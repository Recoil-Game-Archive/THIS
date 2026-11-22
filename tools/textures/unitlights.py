#!/usr/bin/env python3
"""Unit lights for the deferred lights widget, from where the artists painted glow.

  unitlights.py [--max-lights 4] [--only name1,name2] [--report]

For every unit, reads its S3O model (pieces, triangles, texture coordinates) and its textures: texture2's red
channel is self-illumination (windows, lamps, vents, cockpits), texture1 gives the colour there. Glowing surface is
sampled over every triangle, clustered per piece, and each strong cluster becomes a point light just off the
surface, in the painted colour, attached to that piece (so it moves with turrets, legs, rotors).
Writes LuaUI/Configs/DeferredLightsGL4unitLights.lua (loaded by DeferredLightsGL4config.lua), keyed by unit name.

Texture rows are read flipped (row = (1 - v) x height), as tools_autotex bakes them (render.py) and as the engine
shows a DDS. The number of lights grows with the size of the ship: --max-lights is for the smallest ones.
Needs numpy and Pillow.
"""
import argparse, glob, os, re, struct
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'LuaUI', 'Configs', 'DeferredLightsGL4unitLights.lua')

GLOW_MIN = 0.35        # texture2 red above this counts as glowing
CLUSTER = 10.0         # elmos: glowing samples closer than this merge into one light
MIN_AREA = 2.0         # square elmos of glowing surface for a light at all
TEXRES = 512


def read_s3o(path):
    d = open(path, 'rb').read()
    assert d.startswith(b'Spring unit')
    root, = struct.unpack_from('<i', d, 36)
    t1, t2 = struct.unpack_from('<ii', d, 44)
    rd = lambda o: d[o:d.index(b'\0', o)].decode('latin-1') if o else ''
    pieces = []

    def piece(off):
        name_o, nch, ch_o, nv, v_o, vtype, prim, nidx, idx_o, coll, ox, oy, oz = struct.unpack_from('<iiiiiiiiiifff', d, off)
        verts = np.frombuffer(d, np.float32, nv * 8, v_o).reshape(nv, 8) if nv else np.zeros((0, 8), np.float32)
        idx = np.frombuffer(d, np.int32, nidx, idx_o) if nidx else np.zeros(0, np.int32)
        if prim == 0:
            tris = idx[: len(idx) // 3 * 3].reshape(-1, 3)
        elif prim == 2:  # quads
            q = idx[: len(idx) // 4 * 4].reshape(-1, 4)
            tris = np.concatenate([q[:, [0, 1, 2]], q[:, [0, 2, 3]]])
        else:            # triangle strips
            tris = np.array([(idx[i], idx[i + 1], idx[i + 2]) for i in range(len(idx) - 2)
                             if len({idx[i], idx[i + 1], idx[i + 2]}) == 3], np.int32).reshape(-1, 3)
        pieces.append(dict(name=rd(name_o), verts=verts, tris=tris))
        for c in struct.unpack_from('<%di' % nch, d, ch_o) if nch else ():
            piece(c)
    piece(root)
    return pieces, rd(t1), rd(t2)


def texture(name, mode):
    p = os.path.join(ROOT, 'unittextures', name)
    if not name or name.lower().startswith('dummy') or not os.path.isfile(p):   # blank.s3o, planets
        return None
    return np.asarray(Image.open(p).convert(mode).resize((TEXRES, TEXRES)), np.float32) / 255


# barycentric sample points inside a triangle (centre, 3 inner points, 3 edge midpoints)
BARY = np.array([[1/3, 1/3, 1/3], [2/3, 1/6, 1/6], [1/6, 2/3, 1/6], [1/6, 1/6, 2/3],
                 [.5, .5, 0], [0, .5, .5], [.5, 0, .5]], np.float32)


def samples(pieces, tex2r, tex1, flipv):
    """-> per piece: arrays of glowing sample points (pos, normal, weight=area*glow, colour)."""
    out = []
    total = 0.0
    for p in pieces:
        v, t = p['verts'], p['tris']
        if len(t) == 0:
            out.append(None); continue
        P = v[:, 0:3][t]; N = v[:, 3:6][t]; UV = v[:, 6:8][t]           # (T,3,3) (T,3,3) (T,3,2)
        area = 0.5 * np.linalg.norm(np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]), axis=1)   # (T,)
        sp = np.einsum('sk,tkc->tsc', BARY, P)                          # (T,S,3)
        sn = np.einsum('sk,tkc->tsc', BARY, N)
        suv = np.einsum('sk,tkc->tsc', BARY, UV)
        u = np.mod(suv[..., 0], 1.0); vv = np.mod(suv[..., 1], 1.0)
        if flipv:
            vv = 1.0 - vv
        x = np.clip((u * TEXRES).astype(int), 0, TEXRES - 1); y = np.clip((vv * TEXRES).astype(int), 0, TEXRES - 1)
        g = tex2r[y, x]                                                  # (T,S)
        col = tex1[y, x]                                                 # (T,S,3)
        w = np.where(g > GLOW_MIN, g, 0.0) * (area[:, None] / len(BARY))
        total += w.sum()
        m = w > 0
        out.append(dict(pos=sp[m], nrm=sn[m], w=w[m], col=col[m]) if m.any() else None)
    return out, total


def cluster(s, dist):
    """greedy clustering of glowing samples within dist elmos; -> list of (pos, normal, area, colour)."""
    order = np.argsort(-s['w'])
    pos, nrm, w, col = s['pos'][order], s['nrm'][order], s['w'][order], s['col'][order]
    used = np.zeros(len(pos), bool)
    res = []
    for i in range(len(pos)):
        if used[i]:
            continue
        d = np.linalg.norm(pos - pos[i], axis=1)
        m = (d < dist) & ~used
        used |= m
        W = w[m].sum()
        res.append((
            (pos[m] * w[m, None]).sum(0) / W,
            (nrm[m] * w[m, None]).sum(0),
            W,
            (col[m] * w[m, None]).sum(0) / W,
        ))
    return res


def light_for(c, unit_radius):
    pos, nrm, area, col = c
    n = nrm / max(np.linalg.norm(nrm), 1e-6)
    p = pos + n * 3.0                                    # just off the surface
    # colour: the painted colour, saturated a little and normalised (lamps read as their hue, not as grey)
    col = np.clip(col, 0, 1)
    mx = max(col.max(), 0.05)
    col = col / mx
    grey = col.mean()
    col = np.clip(grey + (col - grey) * 1.4, 0.05, 1.0)
    size = np.sqrt(area)                                 # elmos across the glowing patch
    radius = float(np.clip(18 + size * 6, 20, min(260, 25 + unit_radius * 1.2)))
    bright = float(np.clip(0.12 + size * 0.03, 0.12, 0.45))
    return dict(px=round(float(p[0]), 1), py=round(float(p[1]), 1), pz=round(float(p[2]), 1),
                radius=round(radius), r=round(float(col[0]), 2), g=round(float(col[1]), 2), b=round(float(col[2]), 2),
                a=round(bright, 2))


def unit_list():
    for f in sorted(glob.glob(os.path.join(ROOT, 'units', '*.lua'))):
        s = open(f).read()
        m = re.search(r'objectname\s*=\s*"([^"]+)"', s, re.I)
        if m:
            yield os.path.splitext(os.path.basename(f))[0].lower(), m.group(1).split('/')[-1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--max-lights', type=int, default=3)
    ap.add_argument('--only', default='')
    ap.add_argument('--report', action='store_true')
    a = ap.parse_args()
    want = [w.lower() for w in a.only.split(',') if w]
    units = {}
    stats = {'flipped': 0, 'straight': 0, 'nolight': 0}
    for uname, obj in unit_list():
        if want and not any(w in uname for w in want):
            continue
        path = os.path.join(ROOT, 'objects3d', obj)
        if not os.path.exists(path) or not obj.lower().endswith('.s3o'):
            continue
        pieces, t1, t2 = read_s3o(path)
        tex2 = texture(t2, 'RGBA'); tex1 = texture(t1, 'RGB')
        if tex2 is None or tex1 is None:
            continue
        tex2r = tex2[..., 0]
        s, _ = samples(pieces, tex2r, tex1, True)
        allv = np.concatenate([p['verts'][:, 0:3] for p in pieces if len(p['verts'])] or [np.zeros((1, 3))])
        unit_radius = float(np.linalg.norm(allv - allv.mean(0), axis=1).max())
        dist = max(CLUSTER, unit_radius * 0.2)          # bigger units: bigger glowing patches make one light
        # small ships 3, frigates and cruisers 6, carriers and stations 10, capital ships 16
        max_lights = a.max_lights * (1 if unit_radius < 40 else 2 if unit_radius < 90 else 10 / 3 if unit_radius < 300 else 16 / 3)
        cands = []
        for p, ps in zip(pieces, s):
            if ps is None:
                continue
            for c in cluster(ps, dist):
                if c[2] >= MIN_AREA:
                    cands.append((c[2], p['name'], c))
        cands.sort(key=lambda x: -x[0])
        lights = []
        for _, name, c in cands:
            l = light_for(c, unit_radius)
            # skip a light within half a radius of a stronger one on the same piece (one patch, one light)
            if any(n == name and np.hypot(np.hypot(l['px'] - o['px'], l['py'] - o['py']), l['pz'] - o['pz']) < 0.5 * o['radius']
                   for n, o in lights):
                continue
            lights.append((name, l))
            if len(lights) >= max_lights:
                break
        if not lights:
            stats['nolight'] += 1
            continue
        units[uname] = lights
        if a.report:
            print('%-36s %d lights: %s' % (uname, len(lights),
                  ', '.join('%s r%d (%.1f,%.1f,%.1f) a%.2f' % (n, l['radius'], l['r'], l['g'], l['b'], l['a']) for n, l in lights)))
    with open(OUT, 'w') as f:
        f.write('-- GENERATED by tools/textures/unitlights.py from the glow painted in each unit\'s texture2 (red channel):\n'
                '-- glowing surface clustered per model piece, one point light per cluster, in the painted colour.\n'
                '-- Do not edit by hand; hand-made lights go in DeferredLightsGL4config.lua (they win over these).\n'
                'return {\n')
        for uname in sorted(units):
            f.write('\t%s = {\n' % uname)
            for i, (piece, l) in enumerate(units[uname]):
                f.write('\t\tglow%d = { lightType = "point", pieceName = "%s", lightConfig = { posx = %s, posy = %s, posz = %s, '
                        'radius = %d, r = %s, g = %s, b = %s, a = %s, color2r = %s, color2g = %s, color2b = %s, colortime = 0, '
                        'modelfactor = 0.5, specular = 0.4, scattering = 0.5, lensflare = 0, lifetime = 0, sustain = 0, '
                        'selfshadowing = 0 } },\n' % (i + 1, piece, l['px'], l['py'], l['pz'], l['radius'], l['r'], l['g'], l['b'],
                                                      l['a'], l['r'], l['g'], l['b']))
            f.write('\t},\n')
        f.write('}\n')
    print('%d units with lights (%d without glow on the model) -> %s' % (len(units), stats['nolight'], os.path.relpath(OUT, ROOT)))


if __name__ == '__main__':
    main()
