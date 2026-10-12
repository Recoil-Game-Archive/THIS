"""Cut an S3O hull along a world-space lattice and map every cell to a tile of a tileset texture (see tiles.py).

usage: dice.py in.s3o out_dir style_module
The style module provides TILES (list of tile specs), TEX1/TEX2 names and
tile_for(piece, centre, normal, axis, iu, iv, ao) -> (tile index, quarter-turn rotation).
The shape is unchanged: faces are only subdivided (every face is cut by the same three families of planes, so
neighbouring faces get identical cut points and no cracks open up)."""
import sys, importlib, numpy as np
import s3o, tiles
from PIL import Image
from bake import dds_dxt5

def _split(poly, ax, c):
    """Split convex polygon (list of (pos, bary)) by plane pos[ax]=c -> (below, above)."""
    lo, hi = [], []; n = len(poly)
    for i in range(n):
        P, bP = poly[i]; Q, bQ = poly[(i + 1) % n]; dp = P[ax] - c; dq = Q[ax] - c
        if dp <= 1e-9: lo.append((P, bP))
        if dp >= -1e-9: hi.append((P, bP))
        if (dp < -1e-9 and dq > 1e-9) or (dp > 1e-9 and dq < -1e-9):
            a, ba, b, bb = (P, bP, Q, bQ) if tuple(P) <= tuple(Q) else (Q, bQ, P, bP)      # canonical order: both sides of a shared edge agree
            t = (c - a[ax]) / (b[ax] - a[ax]); X = a + t * (b - a); X[ax] = c; bx = ba + t * (bb - ba)
            lo.append((X, bx)); hi.append((X, bx))
    return lo, hi

def _dice(poly, s):
    out = [poly]
    for ax in range(3):
        nxt = []
        for pl in out:
            v = np.array([p[0][ax] for p in pl]); k0 = int(np.floor(v.min() / s + 1e-9)) + 1; k1 = int(np.ceil(v.max() / s - 1e-9)) - 1
            rest = pl
            for k in range(k0, k1 + 1):
                lo, rest = _split(rest, ax, k * s)
                if len(lo) >= 3: nxt.append(lo)
                if len(rest) < 3: break
            if len(rest) >= 3: nxt.append(rest)
        out = nxt
    return out

def dice(m, style, s=tiles.TILE):
    import trimesh
    pieces = [(p, np.array(off, float)) for p, off in m.root.walk() if len(p.verts)]
    Vw = []; Fw = []; b0 = 0
    for p, off in pieces: Vw.append(p.verts[:, :3] + off); Fw.append(s3o.triangles(p) + b0); b0 += len(p.verts)
    mesh = trimesh.Trimesh(np.concatenate(Vw), np.concatenate(Fw), process=False); rng = np.random.default_rng(5)
    stats = {}
    for p, off in pieces:
        V = p.verts[:, :3].astype(float) + off; Nv = p.verts[:, 3:6].astype(float); T = s3o.triangles(p)
        frags = []
        for t in T:
            fn = np.cross(V[t[1]] - V[t[0]], V[t[2]] - V[t[0]]); a2 = np.linalg.norm(fn)
            if a2 < 1e-9: continue
            fn /= a2
            for pl in _dice([(V[t[i]].copy(), np.eye(3)[i]) for i in range(3)], s):
                P = np.array([q[0] for q in pl]); B = np.array([q[1] for q in pl])
                if np.linalg.norm(np.cross(P[1:-1] - P[0], P[2:] - P[0]), axis=1).sum() < 1e-7: continue
                frags.append((P, B @ Nv[t], fn))
        cen = np.array([f[0].mean(0) for f in frags]); fnn = np.array([f[2] for f in frags])
        hit = np.zeros(len(frags)); R = 24
        for _ in range(R):                                 # coarse openness per fragment: lets the style pick shaded tiles in crevices
            d = rng.normal(size=(len(frags), 3)); d /= np.linalg.norm(d, axis=1)[:, None]; d += fnn; d /= np.linalg.norm(d, axis=1)[:, None] + 1e-12
            hit += mesh.ray.intersects_any(cen + fnn * 0.5, d)
        ao = 1 - hit / R
        verts = []; idx = []; vm = {}
        for (P, Nn, fn), c, a in zip(frags, cen, ao):
            ax = int(np.argmax(np.abs(fn))); ua, va = {0: (2, 1), 1: (0, 2), 2: (0, 1)}[ax]
            iu = int(np.floor(c[ua] / s)); iv = int(np.floor(c[va] / s))
            k, rot = style.tile_for(p.name, c, fn, ax, iu, iv, a)
            lu = np.clip(P[:, ua] / s - iu, 0, 1); lv = np.clip(P[:, va] / s - iv, 0, 1)
            if (ax == 1 and fn[1] > 0) or (ax == 0 and fn[0] > 0) or (ax == 2 and fn[2] < 0): lu = 1 - lu       # keep tiles un-mirrored seen from outside
            u, v = tiles.tile_uv(k, lu, lv, rot); ids = []
            for i in range(len(P)):
                nn = Nn[i] / (np.linalg.norm(Nn[i]) + 1e-12); row = np.concatenate([P[i] - off, nn, [u[i], v[i]]]).astype(np.float32)
                key = tuple(np.round(row, 4)); j = vm.get(key)
                if j is None: j = vm[key] = len(verts); verts.append(row)
                ids.append(j)
            for i in range(1, len(P) - 1): idx += [ids[0], ids[i], ids[i + 1]]
        stats[p.name] = (len(T), len(idx) // 3, len(p.verts), len(verts))
        p.verts = np.array(verts, np.float32); p.idx = np.array(idx, np.uint32); p.prim = 0
    return stats

if __name__ == '__main__':
    src, out, mod = sys.argv[1:4]; style = importlib.import_module(mod); m = s3o.load(src)
    t1, t2 = tiles.make_tileset(style.TILES)
    stats = dice(m, style); m.tex1 = style.TEX1; m.tex2 = style.TEX2
    name = src.rsplit('/', 1)[-1].replace('orig_', '')
    s3o.save(m, f'{out}/{name}')
    b1 = style.TEX1.rsplit('.', 1)[0]; b2 = style.TEX2.rsplit('.', 1)[0]
    t2s = Image.merge('RGBA', [c.resize((t2.size[0] // 2, t2.size[1] // 2), Image.BOX) for c in t2.split()])
    t1.save(f'{out}/{b1}.png'); t2s.save(f'{out}/{b2}.png'); dds_dxt5(t1, f'{out}/{style.TEX1}'); dds_dxt5(t2s, f'{out}/{style.TEX2}')
    for k, (t0, tn, v0, vn) in stats.items(): print(f'{k}: {t0} -> {tn} triangles, {v0} -> {vn} vertices')
    print('tileset', t1.size, 'tile', tiles.TILE, 'units =', (tiles.CELL - 2 * tiles.GUT) / tiles.TILE, 'texels/unit')
