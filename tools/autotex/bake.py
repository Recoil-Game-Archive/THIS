"""Procedural texture baker for unwrapped S3O models.
usage: bake.py model.s3o style_module out_dir [--res 1024] [--ss 2]
The style module provides paint(F) -> dict(albedo (n,3), team (n,), emit (n,), refl (n,)) from per-texel fields F."""
import sys, os, json, argparse, importlib, struct, io, numpy as np
from PIL import Image
from scipy import ndimage
import s3o

# ---------------------------------------------------------------- helpers usable from styles
def ihash(*ks, seed=0):
    h = np.uint64(seed * 0x9E3779B1 + 0x85EBCA6B) * np.ones(np.shape(ks[0]), np.uint64)
    with np.errstate(over='ignore'):
        for k in ks:
            h ^= (np.asarray(k).astype(np.int64).astype(np.uint64) + np.uint64(0x9E3779B97F4A7C15) + (h << np.uint64(6)) + (h >> np.uint64(2)))
            h *= np.uint64(0xFF51AFD7ED558CCD); h ^= h >> np.uint64(33)
    return (h >> np.uint64(11)).astype(np.float64) / float(1 << 53)

def noise3(p, scale, seed=0):
    q = p * scale; i = np.floor(q).astype(np.int64); f = q - i; f = f * f * (3 - 2 * f)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + w * ihash(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz, seed=seed)
    return out

def panels(a, b, cw, ch, seed=0, merge=0.5, key=None):
    """Irregular brick-ish panel layout. Returns (distance to nearest panel border, per-panel random 0..1)."""
    key = 0 if key is None else key
    j = np.floor(b / ch).astype(np.int64)
    a2 = a + ihash(j, key, seed=seed) * cw * 2
    i = np.floor(a2 / cw).astype(np.int64); g = i // 2
    merged = ihash(g, j, key, seed=seed + 1) < merge
    fa = a2 - i * cw; fb = b - j * ch
    da = np.where(merged, np.minimum(a2 - g * 2 * cw, (g + 1) * 2 * cw - a2), np.minimum(fa, cw - fa))
    pid = ihash(np.where(merged, g * 2, i), j, key, seed=seed + 2)
    return np.minimum(da, np.minimum(fb, ch - fb)), pid

def smooth(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0 + 1e-9), 0, 1); return t * t * (3 - 2 * t)

def band(x, lo, hi, soft=0.06):
    return smooth(lo - soft, lo + soft, x) * (1 - smooth(hi - soft, hi + soft, x))

# ---------------------------------------------------------------- baking
def seg_dist(p, a, b):
    """min distance from points p (n,3) to segments a,b (e,3) -> (n,)"""
    out = np.full(len(p), 1e9, np.float32)
    for s in range(0, len(p), 200000):
        q = p[s:s + 200000, None, :]; ab = (b - a)[None]; t = np.clip(((q - a[None]) * ab).sum(-1) / ((ab * ab).sum(-1) + 1e-12), 0, 1)
        d = np.linalg.norm(q - (a[None] + t[..., None] * ab), axis=-1); out[s:s + 200000] = d.min(1)
    return out

def build(m, R, meta=None):
    pieces = [(p, off) for p, off in m.root.walk() if len(p.verts)]
    seen = {}; P = []; T = []; TP = []; UVs = []; first = []; base = 0; names = []; offs = []; canon = []; bbox = {}; shared = []
    for k, (p, off) in enumerate(pieces):
        key = (p.verts[:, 6:8].tobytes(), p.idx.tobytes())
        first.append(key not in seen); seen.setdefault(key, k)
        names.append(p.name); offs.append(off); bbox[p.name] = (p.verts[:, :3].min(0), p.verts[:, :3].max(0))
        P.append(p.verts[:, :3] + np.array(off, np.float32)); UVs.append(p.verts[:, 6:8])
        t = s3o.triangles(p).astype(np.int64) + base; T.append(t); TP.append(np.full(len(t), k)); base += len(p.verts)
        c = np.full(len(t), first[-1]); sh = np.zeros(len(t), bool)
        if meta is not None: sh[meta[p.name].get('shared', [])] = True; sh |= any(q.get('alias_of') == p.name for q in meta.values())
        shared.append(sh)
        if meta is not None:                       # symmetric copies / aliases share texels: only owners get painted
            c = np.zeros(len(t), bool); c[meta[p.name]['canonical']] = True
        canon.append(c)
    canon = np.concatenate(canon); shared = np.concatenate(shared)
    P = np.concatenate(P).astype(np.float64); UV = np.concatenate(UVs).astype(np.float64); T = np.concatenate(T); TP = np.concatenate(TP)
    fn = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]]); area = np.linalg.norm(fn, axis=1); fn /= area[:, None] + 1e-12
    # --- facets: connected coplanar triangles within a piece
    q = np.round(P * 200).astype(np.int64); vid = {}; pv = np.array([vid.setdefault(tuple(x), len(vid)) for x in q])
    edges = {}
    for ti, t in enumerate(T):
        for e in range(3):
            a, b = pv[t[e]], pv[t[(e + 1) % 3]]
            edges.setdefault((TP[ti], min(a, b), max(a, b)), []).append((ti, t[e], t[(e + 1) % 3]))
    parent = np.arange(len(T))
    def find(x):
        while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
        return x
    for lst in edges.values():
        for x in lst[1:]:
            if fn[lst[0][0]] @ fn[x[0]] > 0.9995: parent[find(x[0])] = find(lst[0][0])
    facet = np.array([find(i) for i in range(len(T))]); _, facet = np.unique(facet, return_inverse=True)
    nf = facet.max() + 1; cv = [[] for _ in range(nf)]; cc = [[] for _ in range(nf)]
    cen = P[T].mean(1)
    for lst in edges.values():
        fs = set(facet[x[0]] for x in lst)
        if len(lst) == 2 and len(fs) == 1: continue
        for x in lst:
            convex = True
            for y in lst:
                if y[0] != x[0] and (cen[y[0]] - P[x[1]]) @ fn[x[0]] > 1e-3: convex = False
            (cv if convex else cc)[facet[x[0]]].append((P[x[1]], P[x[2]]))
    # --- rasterise in UV space
    tri = np.full((R, R), -1, np.int32); bary = np.zeros((R, R, 2), np.float32)
    for ti, t in enumerate(T):
        if not canon[ti]: continue
        x = UV[t, 0] * R; y = (1 - UV[t, 1]) * R
        x0, x1 = max(int(np.floor(x.min())) - 1, 0), min(int(np.ceil(x.max())) + 1, R - 1)
        y0, y1 = max(int(np.floor(y.min())) - 1, 0), min(int(np.ceil(y.max())) + 1, R - 1)
        den = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
        if abs(den) < 1e-12: continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        l0 = ((y[1] - y[2]) * (gx - x[2]) + (x[2] - x[1]) * (gy - y[2])) / den
        l1 = ((y[2] - y[0]) * (gx - x[2]) + (x[0] - x[2]) * (gy - y[2])) / den
        l2 = 1 - l0 - l1
        # conservative: accept texels within ~0.75px of the triangle so seams are covered
        h = 2 * area[ti] / 1  # unused
        eps = 0.75 * np.array([np.hypot(x[1] - x[2], y[1] - y[2]), np.hypot(x[2] - x[0], y[2] - y[0]), np.hypot(x[0] - x[1], y[0] - y[1])]) / abs(den)
        inside = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
        near = (l0 >= -eps[0]) & (l1 >= -eps[1]) & (l2 >= -eps[2])
        sub = tri[y0:y1 + 1, x0:x1 + 1]; m = inside | (near & (sub < 0))
        sub[m] = ti; bary[y0:y1 + 1, x0:x1 + 1][m] = np.stack([l0, l1], -1)[m]
    ys, xs = np.nonzero(tri >= 0); ti = tri[ys, xs]; b = bary[ys, xs].astype(np.float64)
    pos = P[T[ti, 0]] * b[:, :1] + P[T[ti, 1]] * b[:, 1:2] + P[T[ti, 2]] * (1 - b.sum(1, keepdims=True))
    F = dict(pos=pos, nrm=fn[ti], piece=TP[ti], facet=facet[ti], names=names, xs=xs, ys=ys, R=R, offs=np.array(offs, np.float64), bbox=bbox)
    F['lpos'] = pos - np.array(offs)[TP[ti]]; F['shared'] = shared[ti]
    F['y'] = pos[:, 1]; F['r'] = np.hypot(pos[:, 0], pos[:, 2]); F['theta'] = np.arctan2(pos[:, 2], pos[:, 0])
    # --- facet frames + edge distances
    a = np.zeros(len(pos)); bb = np.zeros(len(pos)); dcv = np.full(len(pos), 1e9); dcc = np.full(len(pos), 1e9)
    farea = np.bincount(facet, area / 2, nf); fcen = np.stack([np.bincount(facet, cen[:, k] * area, nf) for k in range(3)], 1) / (2 * farea[:, None] + 1e-12) / 1
    fcen = fcen * 1.0
    fnorm = np.zeros((nf, 3)); fnorm[facet] = fn
    for f in np.unique(F['facet']):
        s = np.nonzero(F['facet'] == f)[0]; n = fnorm[f]; o = fcen[f]
        if abs(n[1]) < 0.95:
            t = np.cross([0, 1, 0], n); t /= np.linalg.norm(t); u = np.cross(n, t)
        else:
            t = np.array([1.0, 0, 0]); u = np.array([0, 0, 1.0])
        a[s] = (pos[s] - o) @ t; bb[s] = (pos[s] - o) @ u
        if cv[f]: e = np.array(cv[f]); dcv[s] = seg_dist(pos[s], e[:, 0], e[:, 1])
        if cc[f]: e = np.array(cc[f]); dcc[s] = seg_dist(pos[s], e[:, 0], e[:, 1])
    F.update(a=a, b=bb, dcv=dcv, dcc=dcc, farea=farea[F['facet']], fcen=fcen[F['facet']])
    F['mesh'] = (P, T)
    return F

def roty(a):
    return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])

def bake_ao(F, rays=48, seed=1, meta=None, step=2):
    """Ambient occlusion on a coarse texel lattice. Texels shared by symmetric copies or repeated pieces get
    the average occlusion over every place they appear on the model."""
    import trimesh
    P, T = F['mesh']; mesh = trimesh.Trimesh(P, T, process=False); R = F['R']; names = F['names']; offs = F['offs']
    sel = np.nonzero((F['xs'] % step == 0) & (F['ys'] % step == 0))[0]
    n = F['nrm'][sel]; o = F['pos'][sel] + n * 0.03; pc = F['piece'][sel]
    copies = {}                                   # piece -> [(R, t, instance offset)]: every place its texels appear
    for k, nm in enumerate(names):
        mt = meta[nm] if meta else {}
        if 'ops' in mt: ops = [(np.array(o), np.array(t)) for o, t in zip(mt['ops'], mt.get('ops_t', [[0, 0, 0]] * len(mt['ops'])))]
        else: ops = [(roty(2 * np.pi * r / mt.get('sym', 1)), np.zeros(3)) for r in range(mt.get('sym', 1))]
        inst = [(np.eye(3), np.zeros(3), offs[k])]
        if meta:
            for j, q in enumerate(names):
                if meta[q].get('alias_of') == nm:
                    A = np.array(meta[q].get('alias_op', np.eye(3))); s = np.array(meta[q].get('alias_shift', [0, 0, 0]))
                    inst.append((A, -A @ s, offs[j]))                 # src_local = A x + s  =>  x = A (src_local - s) for these flips
        copies[k] = [(A @ g, A @ gt + t, off) for g, gt in ops for A, t, off in inst]
    t = np.cross(n, np.where(np.abs(n[:, :1]) < 0.9, [[1.0, 0, 0]], [[0, 1.0, 0]])); t /= np.linalg.norm(t, axis=1)[:, None]; b = np.cross(n, t)
    rng = np.random.default_rng(seed); hit = np.zeros(len(o))
    for k in range(rays):
        u1 = (k + rng.random(len(o))) / rays; u2 = rng.random(len(o)); rr = np.sqrt(u1); ph = 2 * np.pi * u2
        d = t * (rr * np.cos(ph))[:, None] + b * (rr * np.sin(ph))[:, None] + n * np.sqrt(1 - u1)[:, None]
        oo = o.copy(); dd = d.copy()
        for p, cl in copies.items():
            Rm, tl, off = cl[k % len(cl)]
            if len(cl) == 1: continue
            m = pc == p
            if m.any(): oo[m] = (o[m] - offs[p]) @ Rm.T + tl + off; dd[m] = d[m] @ Rm.T
        hit += mesh.ray.intersects_any(oo, dd)
    img = np.zeros((R // step, R // step), np.float32); mask = np.zeros_like(img, bool)
    img[F['ys'][sel] // step, F['xs'][sel] // step] = 1 - hit / rays; mask[F['ys'][sel] // step, F['xs'][sel] // step] = True
    idx = ndimage.distance_transform_edt(~mask, return_distances=False, return_indices=True); img = img[idx[0], idx[1]]
    img = ndimage.zoom(img, step, order=1) if step > 1 else img
    return img[F['ys'], F['xs']].astype(np.float64)

def to_image(F, vals, R):
    ch = 1 if vals.ndim == 1 else vals.shape[1]
    img = np.zeros((R, R, ch), np.float32); img[F['ys'], F['xs']] = vals.reshape(len(vals), ch)
    mask = np.zeros((R, R), bool); mask[F['ys'], F['xs']] = True
    idx = ndimage.distance_transform_edt(~mask, return_distances=False, return_indices=True)
    return img[idx[0], idx[1]], mask

def dds_dxt5(img, path):
    """Write RGBA image as DXT5 DDS with a full mip chain."""
    levels = []; im = img; w, h = im.size
    while True:
        buf = io.BytesIO(); im.save(buf, 'DDS', pixel_format='DXT5'); levels.append(buf.getvalue())
        if im.size == (1, 1): break
        # resize channel by channel: Pillow premultiplies RGBA on resize, which blacks out every
        # texel whose alpha (team colour mask) is 0
        sz = (max(im.size[0] // 2, 1), max(im.size[1] // 2, 1))
        im = Image.merge('RGBA', [c.resize(sz, Image.BOX) for c in im.split()])
    hdr = bytearray(levels[0][:128])
    flags = struct.unpack_from('<I', hdr, 8)[0] | 0x20000; struct.pack_into('<I', hdr, 8, flags)
    struct.pack_into('<I', hdr, 20, max(w // 4, 1) * max(h // 4, 1) * 16)
    struct.pack_into('<I', hdr, 28, len(levels))
    caps = struct.unpack_from('<I', hdr, 108)[0] | 0x400008; struct.pack_into('<I', hdr, 108, caps)
    open(path, 'wb').write(bytes(hdr) + b''.join(l[128:] for l in levels))

def paint_chunked(style, F, chunk=1500000):
    n = len(F['pos']); outs = []
    for s0 in range(0, n, chunk):
        sub = {k: (v[s0:s0 + chunk] if isinstance(v, np.ndarray) and v.ndim >= 1 and len(v) == n and k not in ('offs',) else v) for k, v in F.items()}
        outs.append(style.paint(sub))
    return {k: np.concatenate([o[k] for o in outs]).astype(np.float32) for k in outs[0]}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('model'); ap.add_argument('style'); ap.add_argument('out')
    ap.add_argument('--res', type=int, default=1024); ap.add_argument('--ss', type=int, default=2); ap.add_argument('--rays', type=int, default=48)
    ap.add_argument('--tex2-div', type=int, default=1, help='tex2 is written at res/N'); ap.add_argument('--ao-step', type=int, default=0)
    a = ap.parse_args()
    m = s3o.load(a.model); R = a.res * a.ss
    mp = a.model.rsplit('.', 1)[0] + '.uvmeta.json'; mj = json.load(open(mp)) if os.path.exists(mp) else None; meta = mj['pieces'] if mj else None
    F = build(m, R, meta); print('texels', len(F['pos']), 'facets', F['facet'].max() + 1, 'fill %.0f%%' % (100 * len(F['pos']) / R / R))
    F['px'] = 1.0 / (mj['texels_per_unit'] * a.res / mj['res']) if mj else 0.0          # model units per final texel
    F['ao'] = bake_ao(F, a.rays, meta=meta, step=a.ao_step or (2 if a.ss > 1 else 1))
    style = importlib.import_module(a.style); out = paint_chunked(style, F)
    alb, mask = to_image(F, np.clip(out['albedo'], 0, 1), R); team, _ = to_image(F, np.clip(out['team'], 0, 1), R)
    emit, _ = to_image(F, np.clip(out['emit'], 0, 1), R); refl, _ = to_image(F, np.clip(out['refl'], 0, 1), R)
    # light spill around emissive texels
    glowsrc = np.zeros((R, R, 3), np.float32)
    gv = np.clip(out.get('glow', out['emit']), 0, 1)
    glowsrc[F['ys'], F['xs']] = out['albedo'] * gv[:, None]
    sg = getattr(style, 'GLOW_SIGMA', 0.18) * a.ss * a.res / 64.0
    glow = np.dstack([ndimage.gaussian_filter(glowsrc[..., c], sg) for c in range(3)]) * getattr(style, 'GLOW_GAIN', 1.2)
    alb = np.clip(alb + glow * 0.5, 0, 1); emit = np.clip(emit[..., 0] + glow.max(-1) * 0.6, 0, 1)
    def down(x, f=a.ss):
        r = x.shape[0] // f; return x.reshape(r, f, r, f, -1).mean((1, 3))
    alb = down(alb); team = down(team)[..., 0]; emit = down(emit[..., None], a.ss * a.tex2_div)[..., 0]; refl = down(refl, a.ss * a.tex2_div)[..., 0]
    u8 = lambda x: (np.clip(x, 0, 1) * 255 + 0.5).astype(np.uint8)
    t1 = Image.fromarray(np.dstack([u8(alb), u8(team)]), 'RGBA')
    t2 = Image.fromarray(np.dstack([u8(emit), u8(refl), np.zeros_like(u8(emit)), np.full_like(u8(emit), 255)]), 'RGBA')
    base = m.tex1.rsplit('.', 1)[0]; base2 = m.tex2.rsplit('.', 1)[0]
    t1.save(f'{a.out}/{base}.png'); t2.save(f'{a.out}/{base2}.png')
    dds_dxt5(t1, f'{a.out}/{m.tex1}'); dds_dxt5(t2, f'{a.out}/{m.tex2}')
    print('wrote', m.tex1, t1.size, m.tex2, t2.size)

if __name__ == '__main__':
    main()
