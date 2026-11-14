"""usage: verify.py orig.s3o new_dir name  -- geometry identity, UV range, mip sanity, team mask stats"""
import sys, numpy as np, struct, io
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s3o
from PIL import Image
orig, D, N = sys.argv[1:4]
a = s3o.load(orig); m = s3o.load(f'{D}/{N}.s3o'); ok = True; uvok = True; nv = 0; nv0 = 0
for (p, o1), (q, o2) in zip(a.root.walk(), m.root.walk()):
    same = p.name == q.name and o1 == o2 and len(p.children) == len(q.children)
    if len(p.verts):
        t1 = p.verts[s3o.triangles(p)][:, :, :6].reshape(-1, 18); t2 = q.verts[s3o.triangles(q)][:, :, :6].reshape(-1, 18)
        same &= t1.shape == t2.shape and np.array_equal(t1, t2) and q.idx.max() < len(q.verts)
        uvok &= bool(q.verts[:, 6:8].min() >= 0 and q.verts[:, 6:8].max() <= 1 and not np.isnan(q.verts).any())
    ok &= bool(same); nv += len(q.verts); nv0 += len(p.verts)
print('pieces', sum(1 for _ in m.root.walk()), '| geometry, normals, triangle order identical to original:', ok, '| UVs inside 0..1:', uvok, '| verts', nv, 'was', nv0, '| header same:', (a.radius, a.height, a.mid) == (m.radius, m.height, m.mid), '|', m.tex1, m.tex2)
for n in (N, N + '2'):
    d = open(f'{D}/{n}.dds', 'rb').read(); im = Image.open(f'{D}/{n}.png'); R = im.size[0]; mean = np.array(im).reshape(-1, 4).mean(0).round(0)
    off = 128 + sum(max(R >> k, 4) ** 2 for k in range(4)); sz = R >> 4
    buf = io.BytesIO(); Image.new('RGBA', (sz, sz)).save(buf, 'DDS', pixel_format='DXT5'); lvl = np.array(Image.open(io.BytesIO(buf.getvalue()[:128] + d[off:off + sz * sz]))).reshape(-1, 4).mean(0).round(0)
    print(f'{n}.dds {R}px {len(d)} bytes, mips {struct.unpack_from("<I", d, 28)[0]}, full mean {mean}, {sz}px mip mean {lvl}')
t = np.array(Image.open(f'{D}/{N}.png'))[..., 3]; print('team mask: %.1f%% of texels, fully opaque %.0f%% of those' % (100 * (t > 0).mean(), 100 * (t > 250).sum() / (t > 0).sum()))
