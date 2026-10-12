"""usage: analyze.py model.s3o piece[:mirror] ...  -- symmetry report + main faces by direction (world coords)"""
import sys, numpy as np, itertools
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s3o, unwrap2
from scipy.spatial import cKDTree
m = s3o.load(sys.argv[1]); ps = {p.name: (p, off) for p, off in m.root.walk() if len(p.verts)}
MX = np.diag([-1., 1, 1]); tot = 0
for n, (p, off) in ps.items():
    v = p.verts[:, :3].astype(float); t = s3o.triangles(p); ar = np.linalg.norm(np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]]), axis=1) / 2; tot += ar.sum()
    uq = np.unique(np.round(v, 3), axis=0); tree = cKDTree(uq); res = []
    for c in np.arange(-0.6, 0.61, 0.01):
        d, j = tree.query(uq @ MX.T + [c, 0, 0]); res.append((d.max(), c))
    r = min(res); fs, _ = unwrap2.facets_of(v[t], list(range(len(t))), np.zeros(len(t), int))
    print(f'{n:12s} off={np.round(off, 1)} tris {len(t):3d} facets {len(fs):3d} area {ar.sum():6.0f} degenerate {int((ar < 1e-4).sum())} | x-mirror: plane x={-r[1] / 2:+.3f} max vert error {r[0]:.3f}')
print('total area', round(tot))
names = list(ps)
for a, b in itertools.combinations(names, 2):
    r = unwrap2.twin_match(ps[a][0], ps[b][0])
    if r: print(f'twin: {a} ~ {b}  op diag{np.diag(r[0]).astype(int).tolist()} shift {np.round(r[1], 2).tolist()}')
for spec in sys.argv[2:]:
    nm, _, mir = spec.partition(':'); p, off = ps[nm]
    P = p.verts[:, :3].astype(float) + np.array(off); T = s3o.triangles(p); Q = P[T]
    tris = [i for i in range(len(T)) if (not mir or Q[i].mean(0)[0] >= -0.01)]
    fs, n = unwrap2.facets_of(Q, tris, np.zeros(len(T), int)); rows = []
    for f in fs:
        pts = Q[f].reshape(-1, 3); ar = sum(np.linalg.norm(np.cross(Q[i, 1] - Q[i, 0], Q[i, 2] - Q[i, 0])) / 2 for i in f)
        rows.append((ar, n[f[0]], pts.min(0), pts.max(0)))
    rows.sort(key=lambda r: -r[0])
    print(f'== {nm} world bbox', P.min(0).round(0), P.max(0).round(0))
    for cls, sel in [('REAR', lambda nn: nn[2] < -0.7), ('FRONT', lambda nn: nn[2] > 0.7), ('UP', lambda nn: nn[1] > 0.8), ('DOWN', lambda nn: nn[1] < -0.8), ('+x', lambda nn: nn[0] > 0.8), ('-x', lambda nn: nn[0] < -0.8), ('other', lambda nn: max(abs(nn[0]), abs(nn[1])) <= 0.8 and abs(nn[2]) <= 0.7)]:
        rr = [r for r in rows if sel(r[1]) and r[0] > 1][:7]
        print(' ', cls, ' | '.join(f'A{r[0]:.0f} n({r[1][0]:.1f},{r[1][1]:.1f},{r[1][2]:.1f}) x{r[2][0]:.0f}..{r[3][0]:.0f} y{r[2][1]:.0f}..{r[3][1]:.0f} z{r[2][2]:.0f}..{r[3][2]:.0f}' for r in rr))
