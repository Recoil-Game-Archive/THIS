"""Laser mine: a 10-unit sphere with a nose lens (+z) and four bracket struts. Grey plated sphere with a
team-colour equator band, dark struts with hazard tips and red lights, the lens glowing pale blue."""
import numpy as np
from hullkit import *
UVPLAN = dict(mirror={'body': 'x'}, facet_angle={'body': 25}, occlusion=True, maxlen=8.0)
RES = 512
def paint(F):
    pos = F['pos']; nrm = F['nrm']; x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); r = np.hypot(x, y)
    P = Painter(F, k=0.22); A = xa > -1; a, b, dcv = F['a'], F['b'], F['dcv']
    sph = (r < 3.25) & (np.abs(z) < 3.15) & (xa < 3.25); nose = (z >= 3.0) & (r < 1.6); strut = ~sph & ~nose
    lat = np.degrees(np.arctan2(y, np.hypot(x, z)))                                    # latitude on the sphere, equator in the xz plane
    lon = np.degrees(np.arctan2(x, z))
    P.hull(sph, lon / 18.0, lat / 18.0, big=(1.6, 1.0), small=(0.4, 0.33)); P.noedge |= sph
    P.paint_team(sph & (np.abs(lat) < 9) & (np.abs(((lon + 180) % 45) - 22.5) > 3.0))
    P.lamp(sph & (np.abs(lat) < 2.2) & (np.abs(((lon + 180) % 45) - 22.5) < 1.2), RED, glow=0.6)
    P.paint_slate(sph & (lat > 52) & (lat < 64)); P.paint_slate(sph & (lat < -52) & (lat > -64))
    P.windows(sph & (np.abs(np.abs(lat) - 30) < 7) & (nrm[:, 2] < 0.3), lon / 18.0 * 1.0, lat / 18.0, 0.33, 0.6, 3)
    P.dark(nose, MECH * 1.1); P.alb[nose & (np.abs(((z - 3.0) % 0.8) - 0.4) < 0.07)] = MECH * 0.55; P.alb[nose & (z > 4.9) & (z < 5.4)] = HAZ_Y * 0.9
    P.lamp(nose & (nrm[:, 2] > 0.6) & (z > 5.9), np.array([0.7, 0.9, 1.0]), glow=1.0)
    P.dark(strut, MECH * 1.25); P.hull(strut, a, b, tone=0.0, big=(1.6, 1.0), small=(0.5, 0.4)) if False else None
    tip = strut & (np.abs(z) > 3.3) & (xa < 4.1); P.hazard(tip, z, y, 0.3)
    P.paint_team(strut & (xa > 4.1) & (np.abs(z) < 1.0) & (np.abs(nrm[:, 0]) > 0.8))
    P.lamp(strut & (np.abs(nrm[:, 1]) > 0.8) & (np.abs(z) > 3.6) & (np.abs(y) > 1.5) & (np.hypot(z - np.sign(z) * 3.9, xa - 4.5) < 0.22), RED, glow=0.6)
    return P.finish()
