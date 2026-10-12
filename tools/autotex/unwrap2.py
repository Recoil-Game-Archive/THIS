"""Symmetry-aware, density-weighted UV unwrap for S3O models.

usage: unwrap2.py in.s3o out.s3o plan_module [--res 2048] [--padding 3] [--tex1 a.dds --tex2 b.dds] [--pack-tries N]

The plan module has a UVPLAN dict:
  sym     {piece: k}     piece is k-fold rotationally symmetric about its Y axis: only one sector gets
                         texture space, the other sectors reuse it (k times the texel density)
  mirror  {piece: 'x'}   piece is mirror-symmetric across the given local axes ('x', 'y', 'xy'...): one side is
                         unwrapped, the other reuses it. Faces that straddle the mirror plane stay unique.
  mirror_center {piece: (cx, cy, cz)}   where that mirror plane sits, if not at the piece origin
  tol     {piece: t}     how far (model units) the two halves may disagree and still share; default 0.02.
                         Old hand-built hulls are often a few tenths off true symmetry.
  facet_angle {piece: deg}  rounded pieces: grow each chart over neighbouring faces within this angle of its
                         seed face instead of strictly coplanar ones (slight foreshortening, far fewer charts)
  twin_tol t             how closely two pieces must agree (model units) to count as copies; default 0.02
  unbend  {piece: R0}    unroll a ring-shaped piece (x,y,z)->(r,y,R0*theta) so arcs pack as straight strips
  planar  [prefixes]     flat-faceted pieces: every coplanar facet is projected exactly (no distortion);
                         other pieces are charted by xatlas
  scale   f(name, centroid, normal) -> relative texel density of a face
  occlusion True         faces buried in crevices get proportionally less texture space
  unique  f(name, centroid, normal) -> True keeps a face out of the sharing (needed under lettering, which
                         would otherwise read mirrored on the other side)
Pieces that are copies of one another -- identical, mirrored, flipped or shifted, even when triangulated
differently -- are found automatically and share UV space. Writes <out>.uvmeta.json naming the triangles
that own texture space so the baker paints each texel once."""
import sys, json, argparse, importlib, itertools, numpy as np, xatlas
from scipy.spatial import cKDTree
import s3o

DIAGS = [np.diag(sg).astype(float) for sg in ((1, 1, 1), (-1, 1, 1), (1, 1, -1), (-1, 1, -1), (1, -1, 1), (-1, -1, 1), (1, -1, -1), (-1, -1, -1))]

def roty(a):
    return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])

def unbend(P, R0, ref):
    th = np.arctan2(P[..., 2], P[..., 0]); th = ref + (th - ref + np.pi) % (2 * np.pi) - np.pi
    return np.stack([np.hypot(P[..., 0], P[..., 2]), P[..., 1], R0 * th], -1)

def piece_ops(name, plan):
    """Symmetry group of a piece: affine maps (M, t), ops[j] takes sector j onto sector 0, plus a sector function."""
    k = plan.get('sym', {}).get(name, 1); mir = plan.get('mirror', {}).get(name, '')
    if k > 1:
        return [(roty(j * 2 * np.pi / k), np.zeros(3)) for j in range(k)], lambda C: np.floor((np.arctan2(C[:, 2], C[:, 0]) % (2 * np.pi)) / (2 * np.pi / k)).astype(int) % k
    if mir:
        ax = ['xyz'.index(c) for c in mir]; cen = np.array(plan.get('mirror_center', {}).get(name, (0, 0, 0)), float); ops = []
        for j in range(2 ** len(ax)):
            d = np.ones(3); t = np.zeros(3)
            for b, a in enumerate(ax):
                if j >> b & 1: d[a] = -1; t[a] = 2 * cen[a]
            ops.append((np.diag(d), t))
        return ops, lambda C: sum((C[:, a] < cen[a] - 1e-3).astype(int) << b for b, a in enumerate(ax))
    return [(np.eye(3), np.zeros(3))], lambda C: np.zeros(len(C), int)

def facets_of(Q, tris, group, angle=None):
    """Connected triangle groups. Q: (ntri,3,3) corner positions; only same-group tris connect. By default groups are
    strictly coplanar; with angle (degrees) each group grows from its largest face over neighbours whose normal stays
    within that angle of the seed face."""
    cr = np.cross(Q[:, 1] - Q[:, 0], Q[:, 2] - Q[:, 0]); ar = np.linalg.norm(cr, axis=1); n = cr / (ar[:, None] + 1e-12)
    key = np.round(Q * 50).astype(np.int64); edges = {}; nbr = {i: [] for i in tris}
    for i in tris:
        for e in range(3):
            a, b = tuple(key[i, e]), tuple(key[i, (e + 1) % 3]); k = (group[i], min(a, b), max(a, b))
            for j in edges.setdefault(k, []): nbr[i].append(j); nbr[j].append(i)
            edges[k].append(i)
    if angle is None:
        parent = {i: i for i in tris}
        def find(x):
            while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
            return x
        for i in tris:
            for j in nbr[i]:
                if n[i] @ n[j] > 0.9995: parent[find(i)] = find(j)
        out = {}
        for i in tris: out.setdefault(find(i), []).append(i)
        return list(out.values()), n
    ca = np.cos(np.radians(angle)); done = set(); out = []
    for s0 in sorted(tris, key=lambda i: -ar[i]):
        if s0 in done: continue
        f = [s0]; done.add(s0); q = [s0]
        while q:
            i = q.pop()
            for j in nbr[i]:
                if j not in done and n[j] @ n[s0] > ca and n[j] @ n[i] > 0.5: done.add(j); f.append(j); q.append(j)
        out.append(f)
    return out, n

def in_tris(pt, T2, slack=2e-3):
    a, b, c = T2[:, 0], T2[:, 1], T2[:, 2]
    den = (b[:, 1] - c[:, 1]) * (a[:, 0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (a[:, 1] - c[:, 1])
    l0 = ((b[:, 1] - c[:, 1]) * (pt[0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (pt[1] - c[:, 1])) / (den + 1e-30)
    l1 = ((c[:, 1] - a[:, 1]) * (pt[0] - c[:, 0]) + (a[:, 0] - c[:, 0]) * (pt[1] - c[:, 1])) / (den + 1e-30)
    return bool(((l0 > -slack) & (l1 > -slack) & (1 - l0 - l1 > -slack)).any())

def plan_group(src, twins, plan, occ):
    """Chart a flat-faceted piece together with its twin pieces (twin_local -> src_local is X @ A.T + s).
    Returns per-triangle corner UVs (world units * density), chart ids, owner flags, for the whole group."""
    name = src.name; R0 = plan.get('unbend', {}).get(name); ops, secf = piece_ops(name, plan); k = len(ops)
    scale = plan.get('scale', lambda *a: 1.0); maxlen = plan.get('maxlen', 66.0); uniq_f = plan.get('unique', lambda *a: False)
    tol = plan.get('tol', {}).get(name, 0.02); exact = tol <= 0.05; fang = plan.get('facet_angle', {}).get(name)
    owners = [(src, np.eye(3), np.zeros(3))] + list(twins)
    X = []; own = []; tri = []; keep = []; dets = []
    for oi, (pc, A, s) in enumerate(owners):
        P = pc.verts[:, :3].astype(np.float64); T = s3o.triangles(pc).astype(np.int64); Xo = P[T]
        no = np.cross(Xo[:, 1] - Xo[:, 0], Xo[:, 2] - Xo[:, 0]); no /= np.linalg.norm(no, axis=1)[:, None] + 1e-12
        keep += [bool(uniq_f(pc.name, Xo[i].mean(0), no[i])) for i in range(len(T))]
        X.append(Xo @ A.T + s); own += [oi] * len(T); tri += list(range(len(T))); dets += [np.sign(np.linalg.det(A))] * len(T)
    X = np.concatenate(X); own = np.array(own); tri = np.array(tri); keep = np.array(keep); dets = np.array(dets); nt = len(X)
    C = X.mean(1); sec = secf(C); gid = own * k + sec; mid = np.pi / k
    fn = np.cross(X[:, 1] - X[:, 0], X[:, 2] - X[:, 0]) * dets[:, None]; fn /= np.linalg.norm(fn, axis=1)[:, None] + 1e-12
    flip = dets * np.array([np.sign(np.linalg.det(ops[j][0])) for j in sec])
    occ_all = np.ones(nt); occ_all[own == 0] = occ
    def to_param(Xi, j):
        Xr = Xi @ ops[j][0].T + ops[j][1]                    # bring sector j back onto sector 0
        return unbend(Xr, R0, mid) if R0 else Xr
    Q = np.stack([to_param(X[i], sec[i]) for i in range(nt)])
    uv = np.zeros((nt, 3, 2)); chart = np.full(nt, -1); canon = np.zeros(nt, bool); charts = []
    def add_facets(tris, group):
        fs, n = facets_of(Q, tris, group, fang); split = []
        for f in fs:                                   # cut very long strips so they fit the atlas axis-aligned
            pts = Q[f].reshape(-1, 3); c = pts - pts.mean(0); w, v = np.linalg.eigh(c.T @ c); ax = v[:, -1]
            ext = np.ptp(pts @ ax); nb = int(np.ceil(ext / maxlen))
            if nb <= 1: split.append(f); continue
            cc = Q[f].mean(1) @ ax; b = np.minimum(((cc - (pts @ ax).min()) / ext * nb).astype(int), nb - 1)
            split += [[i for i, bb in zip(f, b) if bb == kk] for kk in range(nb) if (b == kk).any()]
        for f in split:
            pts = Q[f].reshape(-1, 3); o = pts.mean(0)
            nn = np.cross(Q[f][:, 1] - Q[f][:, 0], Q[f][:, 2] - Q[f][:, 0]).sum(0); nn /= np.linalg.norm(nn) + 1e-12     # area-weighted mean normal
            c = pts - o; w, v = np.linalg.eigh(c.T @ c); t = v[:, -1]
            t = t - nn * (t @ nn); t /= np.linalg.norm(t); u = np.cross(nn, t)
            s = float(np.mean([scale(owners[own[i]][0].name if own[i] else name, C[i], fn[i]) * occ_all[i] for i in f]))
            fr = dict(o=o, t=t, u=u, n=nn, s=s, tris=list(f), id=len(charts), tree=cKDTree(np.unique(np.round(pts, 4), axis=0)) if fang else None); charts.append(fr)
            for i in f:
                uv[i] = np.stack([(Q[i] - o) @ t, (Q[i] - o) @ u], 1) * s; chart[i] = fr['id']; canon[i] = True
    add_facets([i for i in range(nt) if gid[i] == 0], np.zeros(nt, int))
    base = list(charts); extras = []; covered = np.zeros(nt, bool)
    ndot = 0.999 if exact else 0.98; slack = 2e-3 if exact else 0.06; shrink = 0.97 if exact else 0.85
    for i in range(nt):
        if gid[i] == 0: continue
        best = None; nq = np.cross(Q[i, 1] - Q[i, 0], Q[i, 2] - Q[i, 0]) * flip[i]; nq /= np.linalg.norm(nq) + 1e-12
        for fr in ([] if keep[i] else base):
            if fang:                                   # rounded piece: the copy's corners must all be corners of this chart
                if nq @ fr['n'] < np.cos(np.radians(fang + 30)): continue
                dist = fr['tree'].query(Q[i])[0].max()
                if dist > max(tol, 0.03) or (best and dist >= best[0]): continue
                q2 = np.stack([(Q[i] - fr['o']) @ fr['t'], (Q[i] - fr['o']) @ fr['u']], 1)
                if in_tris(q2.mean(0), uv[fr['tris']] / fr['s'], 0.02): best = (dist, fr, q2)
                continue
            if nq @ fr['n'] < ndot: continue
            dist = np.abs((Q[i] - fr['o']) @ fr['n']).max()
            if dist > tol or (best and dist >= best[0]): continue
            q2 = np.stack([(Q[i] - fr['o']) @ fr['t'], (Q[i] - fr['o']) @ fr['u']], 1); c2 = q2.mean(0)
            T2 = uv[fr['tris']] / fr['s']
            if all(in_tris(c2 + shrink * (x - c2), T2, slack) for x in q2) and in_tris(c2, T2, slack): best = (dist, fr, q2)
        if best:
            _, fr, q2 = best; uv[i] = q2 * fr['s']; chart[i] = fr['id']
            for x in [q2.mean(0)] + list(q2.mean(0) + 0.6 * (q2 - q2.mean(0))):      # which owners does this copy land on
                for tt in fr['tris']:
                    if in_tris(x, uv[tt][None] / fr['s']): covered[tt] = True
        else: extras.append(i)
    if extras: add_facets(extras, gid)
    return dict(uv=uv, chart=chart, canon=canon, covered=covered, own=own, tri=tri, owners=owners, ncharts=len(charts), nextra=len(extras), ops=ops)

def exact_match(p, q):
    """Is p a triangle-for-triangle copy (or mirror image) of q? Returns (op, tri map, corner map), q_local = op @ p_local."""
    if len(p.idx) != len(q.idx): return None
    Tp = s3o.triangles(p); Tq = s3o.triangles(q); kq = [tuple(x) for x in np.round(q.verts[:, :3] * 50).astype(int)]
    table = {}
    for j, t in enumerate(Tq): table.setdefault(tuple(sorted(kq[v] for v in t)), []).append(j)
    for op in DIAGS:
        kp = [tuple(x) for x in np.round((p.verts[:, :3] @ op.T) * 50).astype(int)]; tm = []; cm = []; used = set()
        for t in Tp:
            c = [j for j in table.get(tuple(sorted(kp[v] for v in t)), []) if j not in used]
            if not c or len(set(kp[v] for v in t)) < 3: break
            j = c[0]; used.add(j); tm.append(j); cm.append([[kq[v] for v in Tq[j]].index(kp[v]) for v in t])
        else: return op, np.array(tm), np.array(cm)
    return None

def twin_match(p, q, tol=0.02):
    """Same shape as q up to mirroring/flipping and a small shift, whatever the triangulation? Returns (A, s)."""
    vp = np.unique(np.round(p.verts[:, :3].astype(np.float64), 3), axis=0); vq = np.unique(np.round(q.verts[:, :3].astype(np.float64), 3), axis=0)
    if len(vp) != len(vq) or abs(len(p.idx) - len(q.idx)) > 0: return None
    tree = cKDTree(vq)
    for A in DIAGS:
        w = vp @ A.T; s = vq.mean(0) - w.mean(0)
        for sh in (np.zeros(3), s):
            d, j = tree.query(w + sh)
            if d.max() < tol and len(set(j)) == len(vq): return A, sh
    return None

def unwrap(m, plan, res=2048, padding=3, pack_tries=None):
    pieces = [p for p, _ in m.root.walk() if len(p.verts)]
    planar = tuple(plan.get('planar', ())); is_planar = lambda p: bool(planar) and p.name.startswith(planar)
    srcs = []; twin_of = {}; alias = {}
    for p in pieces:
        for q in srcs:
            if is_planar(p) and is_planar(q):
                r = twin_match(p, q, plan.get('twin_tol', 0.02))
                if r: twin_of[id(p)] = (q, r); break
            elif not is_planar(p) and not is_planar(q):
                r = exact_match(p, q)
                if r: alias[id(p)] = (q, r); break
        else: srcs.append(p)
    occ = {id(p): np.ones(len(s3o.triangles(p))) for p in srcs}
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
            o_ = 1 - hits / N; occ[id(p)] = np.where(o_ < 0.015, 0.12, np.clip(0.42 + 0.75 * o_, 0.5, 1.0))    # sealed-in faces get almost nothing
    scale = plan.get('scale', lambda *a: 1.0)
    groups = []; V = []; F = []; owner = []     # packing mesh: uv verts, faces, (group, tri, corner)
    for gi, p in enumerate(srcs):
        if is_planar(p):
            tw = [(q, r[0], r[1]) for q in pieces if id(q) in twin_of and twin_of[id(q)][0] is p for r in [twin_of[id(q)][1]]]
            g = plan_group(p, tw, plan, occ[id(p)])
            print(f'{p.name:14s} planar charts={g["ncharts"]:3d} owned tris={g["canon"].sum()}/{len(g["canon"])} (unmatched copies: {g["nextra"]})' + (f' twins: {", ".join(q.name for q, _, _ in tw)}' if tw else ''))
        else:
            P = p.verts[:, :3].astype(np.float64); T = s3o.triangles(p).astype(np.int64)
            s = float(scale(p.name, P.mean(0), np.array([0, 1.0, 0])))
            a = xatlas.Atlas(); a.add_mesh(np.ascontiguousarray(P * s, np.float32), np.ascontiguousarray(T, np.uint32))
            co = xatlas.ChartOptions(); co.max_iterations = 4; po = xatlas.PackOptions(); po.padding = 0; po.texels_per_unit = 64.0; po.resolution = 0
            a.generate(co, po); vmap, idx, uvx = a[0]
            assert np.array_equal(vmap[idx], T), 'xatlas reordered faces'
            g = dict(uv=uvx[idx] * np.array([a.width, a.height]) / 64.0, chart=None, canon=np.ones(len(T), bool), covered=np.zeros(len(T), bool),
                     own=np.zeros(len(T), int), tri=np.arange(len(T)), owners=[(p, np.eye(3), np.zeros(3))], ops=[(np.eye(3), np.zeros(3))], T=T)
            print(f'{p.name:14s} xatlas charts={a.chart_count}')
        groups.append(g); uv, chart = g['uv'], g['chart']
        vmapd = {}
        for i in np.nonzero(g['canon'])[0]:
            f = []
            for c in range(3):
                key = (gi, -1 if chart is None else int(chart[i]), -1 if chart is not None else int(g['T'][i, c]), round(float(uv[i, c, 0]), 4), round(float(uv[i, c, 1]), 4))
                if key not in vmapd: vmapd[key] = len(V); V.append(uv[i, c])
                f.append(vmapd[key]); owner.append((gi, i, c))
            F.append(f)
    V = np.array(V, np.float32); F = np.array(F, np.uint32)
    def pack(tpu, brute=True):
        a = xatlas.Atlas(); a.add_uv_mesh(V, F)
        po = xatlas.PackOptions(); po.resolution = 0; po.padding = padding; po.texels_per_unit = tpu; po.bruteForce = brute
        po.rotate_charts = True; po.rotate_charts_to_axis = True; po.blockAlign = False
        a.generate(xatlas.ChartOptions(), po); return a
    # Let the packer size the atlas freely, then rescale so it fills the texture. Layouts differ with the working
    # resolution, so try several and keep the densest.
    e1 = V[F[:, 1]] - V[F[:, 0]]; e2 = V[F[:, 2]] - V[F[:, 0]]; area = np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() / 2
    t = res * np.sqrt(0.72 / area); best = None; tried = []; rng = np.random.default_rng(7)
    for it in range(pack_tries or plan.get('pack_tries', 28)):
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
    # write back owned corners, then derive copies through each chart's affine map
    for g in groups: g['new'] = np.zeros_like(g['uv'])
    for (gi, i, c), v in zip(owner, F.reshape(-1)): groups[gi]['new'][i, c] = newuv[v]
    meta = {}; piece_new = {}
    for g in groups:
        new = g['new']
        if g['chart'] is not None:
            for ch in np.unique(g['chart']):
                sel = np.nonzero((g['chart'] == ch) & g['canon'])[0]; A = np.c_[g['uv'][sel].reshape(-1, 2), np.ones(len(sel) * 3)]
                M, *_ = np.linalg.lstsq(A, new[sel].reshape(-1, 2), rcond=None)
                for i in np.nonzero((g['chart'] == ch) & ~g['canon'])[0]: new[i] = np.c_[g['uv'][i], np.ones(3)] @ M
        for oi, (pc, A, s) in enumerate(g['owners']):
            sel = np.nonzero(g['own'] == oi)[0]; order = np.argsort(g['tri'][sel]); sel = sel[order]; piece_new[id(pc)] = new[sel]
            md = dict(canonical=[int(k) for k in np.nonzero(g['canon'][sel])[0]], shared=[int(k) for k in np.nonzero(g['covered'][sel])[0]])
            if oi == 0:
                md.update(ops=[o[0].tolist() for o in g['ops']], ops_t=[o[1].tolist() for o in g['ops']])
                if len(g['owners']) > 1: md['shared'] = md['canonical']
            else: md.update(alias_of=g['owners'][0][0].name, alias_op=A.tolist(), alias_shift=s.tolist())
            meta[pc.name] = md
    for p in pieces:
        al = alias.get(id(p)); T = s3o.triangles(p).astype(np.int64)
        if al:
            src, (op, tm, cm) = al; new = np.stack([piece_new[id(src)][tm[i]][cm[i]] for i in range(len(T))])
            meta[p.name] = dict(canonical=[], shared=[], alias_of=src.name, alias_op=op.tolist(), alias_shift=[0, 0, 0]); meta[src.name]['shared'] = meta[src.name]['canonical']
        else: new = piece_new[id(p)]
        vm = {}; verts = []; idx = []
        for i in range(len(T)):
            for c in range(3):
                key = (int(T[i, c]), round(float(new[i, c, 0]), 6), round(float(new[i, c, 1]), 6))
                if key not in vm:
                    vm[key] = len(verts); row = p.verts[T[i, c]].copy(); row[6] = new[i, c, 0]; row[7] = 1.0 - new[i, c, 1]; verts.append(row)
                idx.append(vm[key])
        p.verts = np.array(verts, np.float32); p.idx = np.array(idx, np.uint32); p.prim = 0
        p.verts[:, 6:8] = np.clip(p.verts[:, 6:8], 0.0, 1.0)      # sliver/degenerate copies can poke a few texels past the edge
    return meta, tpu

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('plan'); ap.add_argument('--res', type=int, default=2048)
    ap.add_argument('--tex1'); ap.add_argument('--tex2'); ap.add_argument('--pack-tries', type=int); ap.add_argument('--padding', type=int, default=3)
    a = ap.parse_args(); m = s3o.load(a.src)
    meta, tpu = unwrap(m, importlib.import_module(a.plan).UVPLAN, a.res, padding=a.padding, pack_tries=a.pack_tries)
    if a.tex1: m.tex1 = a.tex1
    if a.tex2: m.tex2 = a.tex2
    s3o.save(m, a.dst); json.dump(dict(pieces=meta, texels_per_unit=float(tpu), res=a.res), open(a.dst.rsplit('.', 1)[0] + '.uvmeta.json', 'w'))
