"""Symmetry-aware, density-weighted UV unwrap for S3O models.

usage: unwrap2.py in.s3o out.s3o plan_module [--res 2048] [--tex1 a.dds --tex2 b.dds]

The plan module has a UVPLAN dict:
  sym     {piece: k}     piece is k-fold rotationally symmetric about its Y axis: only one sector gets
                         texture space, the other sectors reuse it (k times the texel density)
  mirror  {piece: 'x'}   piece is mirror-symmetric across the given local axes ('x', 'y', 'xy'...): one side is
                         unwrapped, the other reuses it. Faces that straddle the mirror plane stay unique.
  occlusion True         faces buried in crevices get proportionally less texture space
  unique  f(name, centroid, normal) -> True keeps a face out of the sharing (needed under lettering, which
                         would otherwise read mirrored on the other side)
  unbend  {piece: R0}    unroll a ring-shaped piece (x,y,z)->(r,y,R0*theta) so arcs pack as straight strips
  planar  [prefixes]     flat-faceted pieces: every coplanar facet is projected exactly (no distortion);
                         other pieces are charted by xatlas
  scale   f(name, centroid, normal) -> relative texel density of a face
Identical pieces (repeated turrets) and mirror-image pieces (left/right pods) share UV space as well. Writes <out>.uvmeta.json naming the
triangles that own texture space so the baker paints each texel once."""
import sys, json, argparse, importlib, numpy as np, xatlas
import s3o

def roty(a):
    return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])

def unbend(P, R0, ref):
    th = np.arctan2(P[:, 2], P[:, 0]); th = ref + (th - ref + np.pi) % (2 * np.pi) - np.pi
    return np.stack([np.hypot(P[:, 0], P[:, 2]), P[:, 1], R0 * th], 1)

def piece_ops(name, plan):
    """Symmetry group of a piece: list of matrices, ops[j] maps sector j onto sector 0, plus a sector function."""
    k = plan.get('sym', {}).get(name, 1); mir = plan.get('mirror', {}).get(name, '')
    if k > 1:
        return [roty(j * 2 * np.pi / k) for j in range(k)], lambda C: np.floor((np.arctan2(C[:, 2], C[:, 0]) % (2 * np.pi)) / (2 * np.pi / k)).astype(int) % k
    if mir:
        ax = ['xyz'.index(c) for c in mir]; ops = []
        for j in range(2 ** len(ax)):
            d = np.ones(3)
            for b, a in enumerate(ax):
                if j >> b & 1: d[a] = -1
            ops.append(np.diag(d))
        return ops, lambda C: sum((C[:, a] < -1e-3).astype(int) << b for b, a in enumerate(ax))
    return [np.eye(3)], lambda C: np.zeros(len(C), int)

def facets_of(Q, tris, group):
    """Connected coplanar triangle groups. Q: (ntri,3,3) corner positions, group: only same-group tris connect."""
    n = np.cross(Q[:, 1] - Q[:, 0], Q[:, 2] - Q[:, 0]); n /= np.linalg.norm(n, axis=1)[:, None] + 1e-12
    key = np.round(Q * 50).astype(np.int64); edges = {}
    parent = list(range(len(Q)))
    def find(x):
        while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
        return x
    for i in tris:
        for e in range(3):
            a, b = tuple(key[i, e]), tuple(key[i, (e + 1) % 3])
            for j in edges.setdefault((group[i], min(a, b), max(a, b)), []):
                if n[i] @ n[j] > 0.9995: parent[find(i)] = find(j)
            edges[(group[i], min(a, b), max(a, b))].append(i)
    out = {}
    for i in tris: out.setdefault(find(i), []).append(i)
    return list(out.values()), n

def in_tris(pt, T2):
    a, b, c = T2[:, 0], T2[:, 1], T2[:, 2]
    den = (b[:, 1] - c[:, 1]) * (a[:, 0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (a[:, 1] - c[:, 1])
    l0 = ((b[:, 1] - c[:, 1]) * (pt[0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (pt[1] - c[:, 1])) / (den + 1e-30)
    l1 = ((c[:, 1] - a[:, 1]) * (pt[0] - c[:, 0]) + (a[:, 0] - c[:, 0]) * (pt[1] - c[:, 1])) / (den + 1e-30)
    return bool(((l0 > -2e-3) & (l1 > -2e-3) & (1 - l0 - l1 > -2e-3)).any())

def plan_piece(p, plan, occ):
    """Returns per-triangle corner UVs (world units * density), chart ids, canonical mask for a planar piece."""
    name = p.name; R0 = plan.get('unbend', {}).get(name); ops, secf = piece_ops(name, plan); k = len(ops)
    scale = plan.get('scale', lambda *a: 1.0); maxlen = plan.get('maxlen', 66.0)
    P = p.verts[:, :3].astype(np.float64); T = s3o.triangles(p).astype(np.int64); nt = len(T)
    C = P[T].mean(1); fn = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]]); fn /= np.linalg.norm(fn, axis=1)[:, None] + 1e-12
    sec = secf(C); mid = np.pi / k; uniq_f = plan.get('unique', lambda *a: False); keep = np.array([bool(uniq_f(name, C[i], fn[i])) for i in range(nt)])
    flip0 = None; flip = np.array([np.sign(np.linalg.det(o)) for o in ops])
    def to_param(X, j):
        Xr = X @ ops[j].T if j else X                        # bring sector j back onto sector 0
        return unbend(Xr, R0, mid) if R0 else Xr
    Q = np.stack([to_param(P[T[i]], sec[i]) for i in range(nt)])       # every triangle expressed in sector 0
    uv = np.zeros((nt, 3, 2)); chart = np.full(nt, -1); canon = np.zeros(nt, bool); charts = []
    def add_facets(tris, group):
        fs, n = facets_of(Q, tris, group)
        split = []
        for f in fs:                                   # cut very long strips so they fit the atlas axis-aligned
            pts = Q[f].reshape(-1, 3); c = pts - pts.mean(0); w, v = np.linalg.eigh(c.T @ c); ax = v[:, -1]
            ext = np.ptp(pts @ ax); nb = int(np.ceil(ext / maxlen))
            if nb <= 1: split.append(f); continue
            cc = Q[f].mean(1) @ ax; b = np.minimum(((cc - (pts @ ax).min()) / ext * nb).astype(int), nb - 1)
            split += [[i for i, bb in zip(f, b) if bb == k] for k in range(nb) if (b == k).any()]
        for f in split:
            pts = Q[f].reshape(-1, 3); nn = n[f[0]]; o = pts.mean(0)
            c = pts - o; w, v = np.linalg.eigh(c.T @ c); t = v[:, -1]
            t = t - nn * (t @ nn); t /= np.linalg.norm(t); u = np.cross(nn, t)
            s = float(np.mean([scale(name, C[i], fn[i]) * occ[i] for i in f]))
            fr = dict(o=o, t=t, u=u, n=nn, s=s, tris=list(f), id=len(charts)); charts.append(fr)
            for i in f:
                uv[i] = np.stack([(Q[i] - o) @ t, (Q[i] - o) @ u], 1) * s; chart[i] = fr['id']; canon[i] = True
    add_facets([i for i in range(nt) if sec[i] == 0], np.zeros(nt, int))
    base = list(charts); extras = []; covered = np.zeros(nt, bool)
    for i in range(nt):
        if sec[i] == 0: continue
        hit = None; nq = np.cross(Q[i, 1] - Q[i, 0], Q[i, 2] - Q[i, 0]) * flip[sec[i]]; nq /= np.linalg.norm(nq) + 1e-12
        for fr in ([] if keep[i] else base):
            if nq @ fr['n'] < 0.999: continue
            if np.abs((Q[i] - fr['o']) @ fr['n']).max() > 0.02: continue
            q2 = np.stack([(Q[i] - fr['o']) @ fr['t'], (Q[i] - fr['o']) @ fr['u']], 1); c2 = q2.mean(0)
            T2 = uv[fr['tris']] / fr['s']
            if all(in_tris(c2 + 0.97 * (x - c2), T2) for x in q2) and in_tris(c2, T2): hit = (fr, q2, T2); break
        if hit:
            uv[i] = hit[1] * hit[0]['s']; chart[i] = hit[0]['id']
            for x in [hit[1].mean(0)] + list(hit[1].mean(0) + 0.6 * (hit[1] - hit[1].mean(0))):      # which owners does this copy land on
                for tt in hit[0]['tris']:
                    if in_tris(x, uv[tt][None] / hit[0]['s']): covered[tt] = True
        else:
            extras.append(i)
            if flip[sec[i]] < 0 and not R0: Q[i] = P[T[i]]          # unique after all: keep it un-mirrored
    if extras: add_facets(extras, sec)
    return T, uv, chart, canon, len(charts), len(extras), covered

def unwrap(m, plan, res=2048, padding=3):
    pieces = [p for p, _ in m.root.walk() if len(p.verts)]
    uniq = []; alias = {}
    def match(p, q):
        """Is p a copy (or mirror image) of q? Returns (op, tri map, corner map) with q_local = op @ p_local."""
        if len(p.idx) != len(q.idx): return None
        Tp = s3o.triangles(p); Tq = s3o.triangles(q); kq = [tuple(x) for x in np.round(q.verts[:, :3] * 50).astype(int)]
        table = {}
        for j, t in enumerate(Tq): table.setdefault(tuple(sorted(kq[v] for v in t)), []).append(j)
        for op in (np.eye(3), np.diag([-1.0, 1, 1])):
            kp = [tuple(x) for x in np.round((p.verts[:, :3] @ op.T) * 50).astype(int)]; tm = []; cm = []; used = set()
            for t in Tp:
                c = [j for j in table.get(tuple(sorted(kp[v] for v in t)), []) if j not in used]
                if not c: break
                j = c[0]; used.add(j); tm.append(j); cm.append([[kq[v] for v in Tq[j]].index(kp[v]) for v in t])
            else: return op, np.array(tm), np.array(cm)
        return None
    for p in pieces:
        for q in uniq:
            r = match(p, q)
            if r: alias[id(p)] = (q, r); break
        else: uniq.append(p)
    occ = {id(p): np.ones(len(s3o.triangles(p))) for p in uniq}
    if plan.get('occlusion'):
        import trimesh
        allp = [(p, off) for p, off in m.root.walk() if len(p.verts)]; Vw = []; Fw = []; b0 = 0
        for p, off in allp:
            Vw.append(p.verts[:, :3] + np.array(off)); Fw.append(s3o.triangles(p) + b0); b0 += len(p.verts)
        mesh = trimesh.Trimesh(np.concatenate(Vw), np.concatenate(Fw), process=False); rng = np.random.default_rng(3)
        for p, off in allp:
            if id(p) not in occ: continue
            V = p.verts[:, :3].astype(np.float64) + np.array(off); T = s3o.triangles(p); nrm = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]); nrm /= np.linalg.norm(nrm, axis=1)[:, None] + 1e-12
            hits = np.zeros(len(T)); N = 96
            for _ in range(N):
                w = rng.dirichlet([1, 1, 1], len(T)); o = (V[T] * w[:, :, None]).sum(1) + nrm * 0.05
                d = rng.normal(size=(len(T), 3)); d /= np.linalg.norm(d, axis=1)[:, None]; d += nrm; d /= np.linalg.norm(d, axis=1)[:, None] + 1e-12
                hits += mesh.ray.intersects_any(o, d)
            occ[id(p)] = np.clip(0.42 + 0.75 * (1 - hits / N), 0.5, 1.0)
    scale = plan.get('scale', lambda *a: 1.0); planar = tuple(plan.get('planar', ()))
    info = {}; V = []; F = []; owner = []     # packing mesh: uv verts, faces, (piece index, tri, corner)
    for pi, p in enumerate(uniq):
        if p.name.startswith(planar) if planar else False:
            T, uv, chart, canon, nch, nex, covered = plan_piece(p, plan, occ[id(p)])
            print(f'{p.name:10s} planar charts={nch:3d} unique tris={canon.sum()}/{len(T)} (unmatched copies: {nex})')
        else:
            P = p.verts[:, :3].astype(np.float64); T = s3o.triangles(p).astype(np.int64)
            s = float(scale(p.name, P.mean(0), np.array([0, 1.0, 0])))
            a = xatlas.Atlas(); a.add_mesh(np.ascontiguousarray(P * s, np.float32), np.ascontiguousarray(T, np.uint32))
            co = xatlas.ChartOptions(); co.max_iterations = 4; po = xatlas.PackOptions(); po.padding = 0; po.texels_per_unit = 64.0; po.resolution = 0
            a.generate(co, po); vmap, idx, uvx = a[0]
            assert np.array_equal(vmap[idx], T), 'xatlas reordered faces'
            uv = uvx[idx] * np.array([a.width, a.height]) / 64.0; canon = np.ones(len(T), bool); chart = None; covered = np.zeros(len(T), bool)
            print(f'{p.name:10s} xatlas charts={a.chart_count}')
        info[id(p)] = dict(T=T, uv=uv, chart=chart, canon=canon, covered=covered)
        # dedup uv verts inside each chart only
        vmapd = {}
        for i in np.nonzero(canon)[0]:
            f = []
            for c in range(3):
                key = (pi, -1 if chart is None else int(chart[i]), -1 if chart is not None else int(T[i, c]), round(float(uv[i, c, 0]), 4), round(float(uv[i, c, 1]), 4))
                if key not in vmapd: vmapd[key] = len(V); V.append(uv[i, c])
                f.append(vmapd[key]); owner.append((pi, i, c))
            F.append(f)
    V = np.array(V, np.float32); F = np.array(F, np.uint32)
    def pack(tpu, brute=True):
        a = xatlas.Atlas(); a.add_uv_mesh(V, F)
        po = xatlas.PackOptions(); po.resolution = 0; po.padding = padding; po.texels_per_unit = tpu; po.bruteForce = brute
        po.rotate_charts = True; po.rotate_charts_to_axis = True; po.blockAlign = False
        a.generate(xatlas.ChartOptions(), po); return a
    # Let the packer size the atlas freely, then rescale so its longer side is exactly the texture. Layouts differ
    # with the working resolution, so try several and keep the densest.
    e1 = V[F[:, 1]] - V[F[:, 0]]; e2 = V[F[:, 2]] - V[F[:, 0]]; area = np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() / 2
    t = res * np.sqrt(0.72 / area); best = None; tried = []
    rng = np.random.default_rng(7); base_t = None
    for it in range(plan.get('pack_tries', 28)):
        a = pack(t); side = max(a.width, a.height); lo_side = min(a.width, a.height)
        sides = (a.width, a.height) if lo_side > 0.9 * side else (side, side)       # <=10% stretch is invisible; use the full square
        eff = float(t * res / np.sqrt(sides[0] * sides[1]))
        if side <= res * 1.03 and (best is None or eff > best[0]): best = (eff, a, sides)
        tried.append(round(eff, 2))
        t = (best[0] if best else eff) * rng.uniform(0.9, 1.03)
    tpu, a, sides = best
    vmap, idx, uvn = a[0]
    newuv = np.zeros((len(V), 2)); newuv[vmap] = uvn * np.array([a.width, a.height]) / np.array(sides)
    print(f'packed {a.width}x{a.height} -> {res}: {tpu:.2f} texels/unit at density 1.0, fill {area * tpu * tpu / res / res:.0%}, charts {a.chart_count}, tries {min(tried)}..{max(tried)}')
    # write back canonical corners, then derive copies through each chart's affine map
    for (pi, i, c), v in zip(owner, F.reshape(-1)):
        info[id(uniq[pi])].setdefault('new', np.zeros_like(info[id(uniq[pi])]['uv']))[i, c] = newuv[v]
    meta = {}
    for p in uniq:
        d = info[id(p)]; new = d['new']
        if d['chart'] is not None:
            for ch in np.unique(d['chart']):
                sel = np.nonzero((d['chart'] == ch) & d['canon'])[0]; A = np.c_[d['uv'][sel].reshape(-1, 2), np.ones(len(sel) * 3)]
                M, *_ = np.linalg.lstsq(A, new[sel].reshape(-1, 2), rcond=None)
                for i in np.nonzero((d['chart'] == ch) & ~d['canon'])[0]: new[i] = np.c_[d['uv'][i], np.ones(3)] @ M
        meta[p.name] = dict(canonical=[int(i) for i in np.nonzero(d['canon'])[0]], shared=[int(i) for i in np.nonzero(d['covered'])[0]],
                            ops=[o.tolist() for o in piece_ops(p.name, plan)[0]])
    for p in pieces:
        al = alias.get(id(p)); src = al[0] if al else p; d = info[id(src)]; new = d['new']; T = s3o.triangles(p).astype(np.int64)
        if al: op, tm, cm = al[1]; new = np.stack([new[tm[i]][cm[i]] for i in range(len(T))])
        vm = {}; verts = []; idx = []
        for i in range(len(T)):
            for c in range(3):
                key = (int(T[i, c]), round(float(new[i, c, 0]), 6), round(float(new[i, c, 1]), 6))
                if key not in vm:
                    vm[key] = len(verts); row = p.verts[T[i, c]].copy(); row[6] = new[i, c, 0]; row[7] = 1.0 - new[i, c, 1]; verts.append(row)
                idx.append(vm[key])
        p.verts = np.array(verts, np.float32); p.idx = np.array(idx, np.uint32); p.prim = 0
        if al: meta[p.name] = dict(canonical=[], shared=[], ops=[np.eye(3).tolist()], alias_of=src.name, alias_op=al[1][0].tolist())
    return meta, tpu

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('plan'); ap.add_argument('--res', type=int, default=2048)
    ap.add_argument('--tex1'); ap.add_argument('--tex2')
    a = ap.parse_args(); m = s3o.load(a.src)
    meta, tpu = unwrap(m, importlib.import_module(a.plan).UVPLAN, a.res)
    if a.tex1: m.tex1 = a.tex1
    if a.tex2: m.tex2 = a.tex2
    s3o.save(m, a.dst); json.dump(dict(pieces=meta, texels_per_unit=float(tpu), res=a.res), open(a.dst.rsplit('.', 1)[0] + '.uvmeta.json', 'w'))
