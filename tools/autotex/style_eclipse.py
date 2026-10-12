"""Eclipse (command-and-control cruiser): manta hull, wing fins, missile boxes, graser on the foredeck."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _team(c):
    spine = c.top & (c.xa < 7.5) & (c.z > -95) & (c.z < 40) & c.pre('hull')
    wing = c.top & c.pre('hull') & (c.xa > 58) & (c.xa < 70) & (c.z < -60) & (c.z > -112)
    tipfin = c.pre('hull') & c.side & (c.xa > 80) & (c.dcv > 1.5)
    band = c.pre('hull') & c.top & (np.abs(c.z - 62) < 2.2) & (c.xa > 9)
    return spine | wing | tipfin | band
def _slate(c):
    return c.pre('hull') & c.top & (c.xa > 9) & (c.xa < 16) & (c.z > -70) & (c.z < 20) & (((c.z + 0.3) % 3.0) < 1.7)
def _extra(c):
    P = c.P; g = c.pre('graser'); P.dark(g, SLATE * 0.7); P.lamp(g & c.fwd & (c.dcv > 0.7), WINC, glow=0.9); P.lamp(g & c.top & (np.abs((c.z % 3.0) - 1.5) < 0.3) & (c.dcv > 0.4), WINC, e=0.8, glow=0.5)
    mb = c.pre('mbox'); P.dark(mb & c.fwd, MECH * 0.7); P.lamp(mb & c.fwd & (c.dcv > 0.45), RED, e=0.8, glow=0.5); P.hazard(mb & c.top & (c.dcv < 0.6), c.x, c.z, 0.5)
    br = c.pre('brace'); P.mech(br, c.y, c.z, rib=1.6, pipes=False)
    jf = c.pre('jawfin'); P.paint_team(jf & c.side & (c.dcv > 1.2))
    P.lamp(c.pre('hull') & c.top & (c.xa < 0.6) & (np.abs((c.z % 10.0) - 5.0) < 0.5) & (c.z > 40) & (c.z < 110), WINC, glow=0.6)
def _scale(name, c, n):
    if 'barrel' in name or 'turret' in name: return 1.25
    return 0.6 if n[1] < -0.8 else 1.0
PLAN = dict(mirror={'hull': 'x', 'jawfin': 'x', 'graser': 'x'}, tol={'hull': 0.3},
            planar=['hull', 'mbox', 'brace', 'jawfin', 'fin', 'graser'],
            twin_tol=0.1, scale=_scale, occlusion=True, maxlen=90.0)
UVPLAN, paint = make(dict(plan=PLAN, eng_z=-100, nozzle=(9.0, 3.2), nozzle_y=2.0, bow_z=105, engine=lambda c: (c.nrm[:, 2] < -0.85) & (c.xa < 50), team=_team, slate=_slate, extra=_extra, team_pieces=('fin',), not_guns=('khbarrel',), round=('hull',)))
RES = 4096
