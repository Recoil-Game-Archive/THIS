"""Auto-unwrap an S3O with xatlas. Identical pieces (e.g. repeated turrets) share UV space.
usage: unwrap.py in.s3o out.s3o [--res 1024] [--boost name_prefix:scale ...]"""
import sys, argparse, numpy as np, xatlas
import s3o

def unwrap(m, res=1024, padding=4, boost=()):
    pieces = [p for p, _ in m.root.walk() if len(p.verts)]
    atlas = xatlas.Atlas(); uniq = []; alias = {}
    for p in pieces:
        key = None
        for q in uniq:
            if q.verts.shape == p.verts.shape and np.allclose(q.verts[:, :6], p.verts[:, :6], atol=1e-4) and np.array_equal(q.idx, p.idx):
                key = q; break
        if key is not None: alias[id(p)] = key; continue
        uniq.append(p)
        scale = 1.0
        for pre, s in boost:
            if p.name.startswith(pre): scale = s
        atlas.add_mesh(np.ascontiguousarray(p.verts[:, :3] * scale, np.float32), s3o.triangles(p).astype(np.uint32),
                       np.ascontiguousarray(p.verts[:, 3:6], np.float32))
    co = xatlas.ChartOptions(); co.max_iterations = 4; co.normal_deviation_weight = 4.0; co.max_cost = 1.5
    po = xatlas.PackOptions(); po.resolution = res; po.padding = padding; po.bruteForce = True; po.rotate_charts_to_axis = True; po.blockAlign = False
    atlas.generate(co, po)
    print(f'atlas {atlas.width}x{atlas.height} charts={atlas.chart_count} util={atlas.utilization:.2f} texels/unit={atlas.texels_per_unit:.2f}')
    result = {}
    for i, p in enumerate(uniq):
        vmap, idx, uv = atlas[i]
        result[id(p)] = (vmap, idx, uv)
    for p in pieces:
        vmap, idx, uv = result[id(alias.get(id(p), p))]
        nv = p.verts[vmap].copy(); nv[:, 6] = uv[:, 0]; nv[:, 7] = 1.0 - uv[:, 1]
        p.verts = nv; p.idx = idx.reshape(-1).astype(np.uint32); p.prim = 0
    return atlas.texels_per_unit

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('--res', type=int, default=1024)
    ap.add_argument('--boost', nargs='*', default=[]); ap.add_argument('--tex1'); ap.add_argument('--tex2')
    a = ap.parse_args()
    m = s3o.load(a.src)
    unwrap(m, a.res, boost=[(b.split(':')[0], float(b.split(':')[1])) for b in a.boost])
    if a.tex1: m.tex1 = a.tex1
    if a.tex2: m.tex2 = a.tex2
    s3o.save(m, a.dst)
