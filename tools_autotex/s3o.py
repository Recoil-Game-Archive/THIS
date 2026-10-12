"""Minimal S3O reader/writer (Spring/Recoil model format)."""
import struct
import numpy as np

class Piece:
    def __init__(self):
        self.name = ''; self.children = []; self.offset = (0.0, 0.0, 0.0)
        self.verts = np.zeros((0, 8), np.float32)   # x y z nx ny nz u v
        self.idx = np.zeros((0,), np.uint32); self.prim = 0; self.coll = 0
    def walk(self, parent_off=(0, 0, 0)):
        off = tuple(a + b for a, b in zip(parent_off, self.offset))
        yield self, off
        for c in self.children:
            yield from c.walk(off)

class S3O:
    pass

def _cstr(d, off):
    if off == 0: return ''
    return d[off:d.index(b'\0', off)].decode('latin1')

def _read_piece(d, off):
    (name, nch, chs, nv, vs, vt, pt, vtn, vto, coll, x, y, z) = struct.unpack_from('<10I3f', d, off)
    p = Piece(); p.name = _cstr(d, name); p.offset = (x, y, z); p.prim = pt; p.coll = coll
    p.verts = np.frombuffer(d, '<f4', nv * 8, vs).reshape(-1, 8).copy() if nv else np.zeros((0, 8), np.float32)
    p.idx = np.frombuffer(d, '<u4', vtn, vto).copy() if vtn else np.zeros((0,), np.uint32)
    p.children = [_read_piece(d, struct.unpack_from('<I', d, chs + 4 * i)[0]) for i in range(nch)]
    return p

def load(path):
    d = open(path, 'rb').read()
    magic, ver, radius, height, mx, my, mz, root, coll, t1, t2 = struct.unpack_from('<12sI5f4I', d, 0)
    assert magic.startswith(b'Spring unit'), magic
    m = S3O(); m.version = ver; m.radius = radius; m.height = height; m.mid = (mx, my, mz)
    m.tex1 = _cstr(d, t1); m.tex2 = _cstr(d, t2); m.root = _read_piece(d, root)
    return m

def save(m, path):
    buf = bytearray(52)
    def put_str(s):
        off = len(buf); buf.extend(s.encode('latin1') + b'\0'); return off
    def put_piece(p):
        off = len(buf); buf.extend(b'\0' * 52)
        name = put_str(p.name)
        child_offs = [put_piece(c) for c in p.children]
        chs = len(buf) if child_offs else 0
        for c in child_offs: buf.extend(struct.pack('<I', c))
        vs = len(buf) if len(p.verts) else 0
        buf.extend(np.asarray(p.verts, '<f4').tobytes())
        vt = len(buf) if len(p.idx) else 0
        buf.extend(np.asarray(p.idx, '<u4').tobytes())
        struct.pack_into('<10I3f', buf, off, name, len(child_offs), chs, len(p.verts), vs, 0, p.prim,
                         len(p.idx), vt, 0, *p.offset)
        return off
    root = put_piece(m.root)
    t1 = put_str(m.tex1) if m.tex1 else 0
    t2 = put_str(m.tex2) if m.tex2 else 0
    struct.pack_into('<12sI5f4I', buf, 0, b'Spring unit\0', m.version, m.radius, m.height, *m.mid, root, 0, t1, t2)
    open(path, 'wb').write(bytes(buf))

def triangles(p):
    """Return (n,3) index array for a piece regardless of primitive type."""
    i = p.idx
    if p.prim == 0: return i.reshape(-1, 3)
    if p.prim == 2:
        q = i.reshape(-1, 4); return np.concatenate([q[:, [0, 1, 2]], q[:, [0, 2, 3]]])
    if p.prim == 1:
        t = [(i[k], i[k + 1], i[k + 2]) if k % 2 == 0 else (i[k + 1], i[k], i[k + 2]) for k in range(len(i) - 2)]
        return np.array([x for x in t if len(set(x)) == 3], np.uint32).reshape(-1, 3)
    raise ValueError(p.prim)

def flatten(m):
    """World-space soup: pos, nrm, uv, tris, piece id per tri, piece list."""
    P, N, UV, T, TP, names = [], [], [], [], [], []
    base = 0
    for k, (p, off) in enumerate(m.root.walk()):
        names.append(p.name)
        if not len(p.verts): continue
        P.append(p.verts[:, :3] + np.array(off, np.float32)); N.append(p.verts[:, 3:6]); UV.append(p.verts[:, 6:8])
        t = triangles(p).astype(np.int64) + base; T.append(t); TP.append(np.full(len(t), k)); base += len(p.verts)
    return np.concatenate(P), np.concatenate(N), np.concatenate(UV), np.concatenate(T), np.concatenate(TP), names
