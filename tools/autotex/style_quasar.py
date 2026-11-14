"""Quasar (heavy assault battlecruiser): centre hull with twin fore hulls and noses, ribbed engine block aft
flanked by two armour plates, bridge tower amidships."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _team(c):
    plate = c.pre('plate') & (c.nrm[:, 0] * c.x > 0.5) & (c.dcv > 2.5) & (c.dcv < 8.0)
    spine = c.pre('hullmain') & c.top & (c.xa < 5.5)
    nose = c.pre('nose') & c.top & (c.xa < 3.0)
    fore = c.pre('hull') & ~c.pre('hullmain') & ~c.pre('hullaft') & c.top & (c.xa > 30) & (c.xa < 36)
    aft = c.pre('hullaft') & c.top & (c.xa < 4.0)
    head = c.pre('head') & c.up & (c.dcv > 0.6)
    return plate | spine | nose | fore | aft | head
def _slate(c):
    return c.pre('plate') & (c.nrm[:, 0] * c.x > 0.5) & (c.dcv > 10.0) & (c.dcv < 11.5) & (((c.z + 0.4) % 3.2) < 1.8)
def _extra(c):
    P = c.P; hd = c.pre('head'); P.windows(hd & c.side & (c.dcv > 0.5), c.t, c.y, 1.3, 0.85, 11)
    gv = c.pre('grav'); P.dark(gv, SLATE * 0.7); P.lamp(gv & c.up, WINC, e=0.9, glow=0.7); P.noedge |= gv
    am = c.pre('amturret') & ~c.pre('amturretbase'); P.lamp(am & c.fwd & (c.dcv > 0.3), WINC, glow=0.9)
    mp = c.pre('mpod'); P.dark(mp & c.fwd, MECH * 0.7); P.lamp(mp & c.fwd & (c.dcv > 0.5), RED, e=0.8, glow=0.5)
    # engines: the two big hexagonal nozzles and the two small outboard ones on the stern; the wall around them is machinery
    aft = c.pre('hullaft'); wall = aft & c.rear & (np.abs(c.z + 124.5) < 0.4); P.mech(wall, c.x, c.y, rib=2.2, pipes=True)
    d1 = np.hypot(c.xa - 12.8, c.y); big = aft & (c.z < -127.6) & (d1 < 14.5); P.dark(big, MECH * 1.05); P.noedge |= big
    P.alb[big & (c.z > -131.0) & (c.z < -130.6)] = LIGHT * 0.6; P.exhaust(big & (c.z < -131.5), d1, 6.6)
    d2 = np.hypot(c.xa - 32.2, c.y); sm = aft & (c.z < -124.9) & (d2 < 7.5); P.dark(sm, MECH * 1.05); P.exhaust(sm & (c.z < -127.0), d2, 3.3)
    P.lamp(c.pre('plate') & (np.abs(c.nrm[:, 0]) > 0.5) & (c.dcv > 1.1) & (c.dcv < 1.5) & (np.abs((c.z % 8.0) - 4.0) < 0.35))
def _scale(name, c, n):
    if 'barrel' in name or 'turret' in name or 'sleeve' in name or 'pod' in name: return 1.25
    if name.startswith('plate') and n[0] * c[0] < -0.3: return 0.5           # inner faces of the armour plates
    return 0.55 if n[1] < -0.8 else 1.0
PLAN = dict(mirror={'hullmain': 'x', 'hullaft': 'x'},
            mirror_center={'hullmain': (0.045, 0, 0), 'hullaft': (0.14, 0, 0)}, tol={'hullmain': 0.3, 'hullaft': 0.45},
            planar=['hull', 'nose', 'plate', 'head', 'mpod'],
            twin_tol=0.3, twin_loose=0.06, scale=_scale, occlusion=True, maxlen=110.0)
UVPLAN, paint = make(dict(plan=PLAN, bow_z=None, team=_team, slate=_slate, extra=_extra, not_guns=('amturret',)))
RES = 4096
