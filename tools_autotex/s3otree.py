"""usage: s3otree.py model.s3o  -- print the header and the piece tree with offsets, vertex counts and bounding boxes"""
import struct, sys
def cstr(d, off):
    e = d.index(b'\0', off); return d[off:e].decode('latin1')
def piece(d, off, depth):
    (name, nch, chs, nv, vs, vt, pt, vtn, vto, coll, x, y, z) = struct.unpack_from('<10I3f', d, off)
    vv = [struct.unpack_from('<8f', d, vs + i*32) for i in range(nv)]
    if vv:
        mn = [min(v[k] for v in vv) for k in range(3)]; mx = [max(v[k] for v in vv) for k in range(3)]
        uv = (min(v[6] for v in vv), max(v[6] for v in vv), min(v[7] for v in vv), max(v[7] for v in vv))
        ext = ' bbox=' + ','.join(f'{a:.0f}..{b:.0f}' for a, b in zip(mn, mx)) + ' uv=' + ','.join(f'{u:.2f}' for u in uv)
    else: ext = ''
    print('  '*depth + f"{cstr(d,name)} off=({x:.1f},{y:.1f},{z:.1f}) nv={nv} idx={vtn} prim={pt}{ext}")
    for i in range(nch): piece(d, struct.unpack_from('<I', d, chs + 4*i)[0], depth+1)
d = open(sys.argv[1], 'rb').read()
print(struct.unpack_from('<12sI5f4I', d, 0))
piece(d, struct.unpack_from('<I', d, 36)[0], 0)
