"""Minimal reader for Spring S3O models."""
import struct

def _cstr(data, off):
    if off == 0:
        return ""
    end = data.index(b"\0", off)
    return data[off:end].decode("latin-1")

def load(path):
    data = open(path, "rb").read()
    magic, version, radius, height, mx, my, mz, root, coll, tex1, tex2 = struct.unpack_from("<12sIfffffIIII", data, 0)
    assert magic.startswith(b"Spring unit"), path
    model = {"radius": radius, "height": height, "mid": (mx, my, mz), "tex1": _cstr(data, tex1), "tex2": _cstr(data, tex2), "tris": []}

    def piece(off, px, py, pz):
        (name, nchild, children, nvert, verts, vtype, ptype, tsize, table, coll, ox, oy, oz) = struct.unpack_from("<IIIIIIIIIIfff", data, off)
        px, py, pz = px + ox, py + oy, pz + oz
        vs = []
        for i in range(nvert):
            x, y, z, nx, ny, nz, u, v = struct.unpack_from("<8f", data, verts + 32 * i)
            vs.append((x + px, y + py, z + pz, nx, ny, nz, u, v))
        idx = struct.unpack_from("<%dI" % tsize, data, table) if tsize else ()
        tris = []
        if ptype == 0:
            for i in range(0, len(idx) - 2, 3):
                tris.append((idx[i], idx[i + 1], idx[i + 2]))
        elif ptype == 1:  # strip, 0xFFFFFFFF restarts
            run = []
            for k in idx:
                if k == 0xFFFFFFFF:
                    run = []
                    continue
                run.append(k)
                if len(run) >= 3:
                    a, b, c = run[-3], run[-2], run[-1]
                    tris.append((a, b, c) if len(run) % 2 else (b, a, c))
        elif ptype == 2:  # quads
            for i in range(0, len(idx) - 3, 4):
                tris.append((idx[i], idx[i + 1], idx[i + 2]))
                tris.append((idx[i], idx[i + 2], idx[i + 3]))
        for a, b, c in tris:
            if max(a, b, c) < len(vs):
                model["tris"].append((vs[a], vs[b], vs[c]))
        for i in range(nchild):
            (child,) = struct.unpack_from("<I", data, children + 4 * i)
            piece(child, px, py, pz)

    piece(root, 0.0, 0.0, 0.0)
    return model
