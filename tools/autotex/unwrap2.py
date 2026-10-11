"""Symmetry-aware, density-weighted UV unwrap for S3O models.

usage: unwrap2.py in.s3o out.s3o plan_module [--res 2048] [--tex1 a.dds --tex2 b.dds]

The plan module has a UVPLAN dict:
  sym     {piece: k}     piece is k-fold rotationally symmetric about its Y axis: only one sector gets
                         texture space, the other sectors reuse it (k times the texel density)
  unbend  {piece: R0}    unroll a ring-shaped piece (x,y,z)->(r,y,R0*theta) so arcs pack as straight strips
  planar  [prefixes]     flat-faceted pieces: every coplanar facet is projected exactly (no distortion);
                         other pieces are charted by xatlas
  scale   f(name, centroid, normal) -> relative texel density of a face
Identical pieces (repeated turrets) share UV space as well. Writes <out>.uvmeta.json naming the
triangles that own texture space so the baker paints each texel once."""
import sys, json, argparse, importlib, numpy as np, xatlas
import s3o

def roty(a):
    return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])

def unbend(P, R0, ref):
    th = np.arctan2(P[:, 2], P[:, 0]); th = ref + (th - ref + np.pi) % (2 * np.pi) - np.pi
    return np.stack([np.hypot(P[:, 0], P[:, 2]), P[:, 1], R0 * th], 1)

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

def plan_piece(p, plan):
    """Returns per-triangle corner UVs (world units * density), chart ids, canonical mask for a planar piece."""
    name = p.name; k = plan.get('sym', {}).get(name, 1); R0 = plan.get('unbend', {}).get(name)
    scale = plan.get('scale', lambda *a: 1.0); maxlen = plan.get('maxlen', 66.0)
    P = p.verts[:, :3].astype(np.float64); T = s3o.triangles(p).astype(np.int64); nt = len(T)
    C = P[T].mean(1); fn = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]]); fn /= np.linalg.norm(fn, axis=1)[:, None] + 1e-12
    sec = np.floor((np.arctan2(C[:, 2], C[:, 0]) % (2 * np.pi)) / (2 * np.pi / k)).astype(int) % k if k > 1 else np.zeros(nt, int)
    mid = np.pi / k
    def to_param(X, j):
        Xr = X @ roty(j * 2 * np.pi / k).T if j else X      # rotate sector j back onto sector 0
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
            s = float(np.mean([scale(name, C[i], fn[i]) for i in f]))
            fr = dict(o=o, t=t, u=u, n=nn, s=s, tris=list(f), id=len(charts)); charts.append(fr)
            for i in f:
                uv[i] = np.stack([(Q[i] - o) @ t, (Q[i] - o) @ u], 1) * s; chart[i] = fr['id']; canon[i] = True
    add_facets([i for i in range(nt) if sec[i] == 0], np.zeros(nt, int))
    base = list(charts); extras = []
    for i in range(nt):
        if sec[i] == 0: continue
        hit = None
        for fr in base:
            if abs(n_dot := fr['n'] @ np.cross(Q[i, 1] - Q[i, 0], Q[i, 2] - Q[i, 0])) <= 0: continue
            if np.abs((Q[i] - fr['o']) @ fr['n']).max() > 0.02: continue
            nq = np.cross(Q[i, 1] - Q[i, 0], Q[i, 2] - Q[i, 0]); nq /= np.linalg.norm(nq) + 1e-12
            if nq @ fr['n'] < 0.999: continue
            q2 = np.stack([(Q[i] - fr['o']) @ fr['t'], (Q[i] - fr['o']) @ fr['u']], 1); c2 = q2.mean(0)
            T2 = uv[fr['tris']] / fr['s']
            if all(in_tris(c2 + 0.97 * (x - c2), T2) for x in q2) and in_tris(c2, T2): hit = (fr, q2); break
        if hit: uv[i] = hit[1] * hit[0]['s']; chart[i] = hit[0]['id']
        else: extras.append(i)
    if extras: add_facets(extras, sec)
    return T, uv, chart, canon, len(charts), len(extras)

def unwrap(m, plan, res=2048, padding=3):
    pieces = [p for p, _ in m.root.walk() if len(p.verts)]
    uniq = []; alias = {}
    for p in pieces:
        for q in uniq:
            if q.verts.shape == p.verts.shape and np.allclose(q.verts[:, :6], p.verts[:, :6], atol=1e-4) and np.array_equal(q.idx, p.idx):
                alias[id(p)] = q; break
        else: uniq.append(p)
    scale = plan.get('scale', lambda *a: 1.0); planar = tuple(plan.get('planar', ()))
    info = {}; V = []; F = []; owner = []     # packing mesh: uv verts, faces, (piece index, tri, corner)
    for pi, p in enumerate(uniq):
        if p.name.startswith(planar) if planar else False:
            T, uv, chart, canon, nch, nex = plan_piece(p, plan)
            print(f'{p.name:10s} planar charts={nch:3d} unique tris={canon.sum()}/{len(T)} (unmatched copies: {nex})')
        else:
            P = p.verts[:, :3].astype(np.float64); T = s3o.triangles(p).astype(np.int64)
            s = float(scale(p.name, P.mean(0), np.array([0, 1.0, 0])))
            a = xatlas.Atlas(); a.add_mesh(np.ascontiguousarray(P * s, np.float32), T.astype(np.uint32))
            co = xatlas.ChartOptions(); co.max_iterations = 4; po = xatlas.PackOptions(); po.padding = 0; po.texels_per_unit = 64.0; po.resolution = 0
            a.generate(co, po); vmap, idx, uvx = a[0]
            assert np.array_equal(vmap[idx], T), 'xatlas reordered faces'
            uv = uvx[idx] * np.array([a.width, a.height]) / 64.0; canon = np.ones(len(T), bool); chart = None
            print(f'{p.name:10s} xatlas charts={a.chart_count}')
        info[id(p)] = dict(T=T, uv=uv, chart=chart, canon=canon)
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
    def pack(tpu, brute):
        a = xatlas.Atlas(); a.add_uv_mesh(V, F)
        po = xatlas.PackOptions(); po.resolution = res; po.padding = padding; po.texels_per_unit = tpu; po.bruteForce = brute
        po.rotate_charts = True; po.rotate_charts_to_axis = True; po.blockAlign = False
        a.generate(xatlas.ChartOptions(), po); return a
    lo, hi = 0.5, 200.0
    for _ in range(11):
        mid = (lo + hi) / 2; a = pack(mid, False)
        if a.atlas_count == 1 and a.width <= res and a.height <= res: lo = mid
        else: hi = mid
    best = None
    for tpu in [lo * (1.14 - 0.01 * i) for i in range(15)]:      # brute force packs tighter: try to squeeze more in
        a = pack(tpu, True)
        if a.atlas_count == 1 and a.width <= res and a.height <= res: best = (tpu, a); break
    tpu, a = best
    vmap, idx, uvn = a[0]
    newuv = np.zeros((len(V), 2)); newuv[vmap] = uvn * np.array([a.width, a.height]) / res
    e1 = newuv[F[:, 1]] - newuv[F[:, 0]]; e2 = newuv[F[:, 2]] - newuv[F[:, 0]]; used = np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() / 2
    print(f'packed {a.width}x{a.height} in {res}: {tpu:.2f} texels/unit at density 1.0, fill {used:.0%}, charts {a.chart_count}')
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
        meta[p.name] = dict(canonical=[int(i) for i in np.nonzero(d['canon'])[0]], sym=int(plan.get('sym', {}).get(p.name, 1)))
    for p in pieces:
        src = alias.get(id(p), p); d = info[id(src)]; T = d['T']; new = d['new']
        vm = {}; verts = []; idx = []
        for i in range(len(T)):
            for c in range(3):
                key = (int(T[i, c]), round(float(new[i, c, 0]), 6), round(float(new[i, c, 1]), 6))
                if key not in vm:
                    vm[key] = len(verts); row = p.verts[T[i, c]].copy(); row[6] = new[i, c, 0]; row[7] = 1.0 - new[i, c, 1]; verts.append(row)
                idx.append(vm[key])
        p.verts = np.array(verts, np.float32); p.idx = np.array(idx, np.uint32); p.prim = 0
        if id(p) in alias: meta[p.name] = dict(canonical=[], sym=1, alias_of=src.name)
    return meta, tpu

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('plan'); ap.add_argument('--res', type=int, default=2048)
    ap.add_argument('--tex1'); ap.add_argument('--tex2')
    a = ap.parse_args(); m = s3o.load(a.src)
    meta, tpu = unwrap(m, importlib.import_module(a.plan).UVPLAN, a.res)
    if a.tex1: m.tex1 = a.tex1
    if a.tex2: m.tex2 = a.tex2
    s3o.save(m, a.dst); json.dump(dict(pieces=meta, texels_per_unit=tpu, res=a.res), open(a.dst.rsplit('.', 1)[0] + '.uvmeta.json', 'w'))
