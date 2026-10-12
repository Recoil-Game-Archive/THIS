"""Gunstar (cannon): a cigar hull with a big side shield, twin cannon on one flank and a fin on the other. Tiny."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _team(c):
    return (c.pre('body') & (c.nrm[:, 1] > 0.3) & (np.abs(c.z) < 1.1)) | (c.pre('fin') & (c.dcv > 0.25) & (c.dcv < 0.7))
def _extra(c):
    P = c.P; sh = c.pre('shield'); P.paint_team(sh & (c.dcv > 0.35) & (np.abs(c.nrm[:, 0]) > 0.3)); P.paint_slate(sh & (c.dcv > 0.7) & (c.dcv < 1.0) & (((c.z + 0.1) % 0.8) < 0.45))
    ex = c.pre('extra'); P.mech(ex, c.y, c.z, rib=0.4, pipes=False)
    zm = c.F['bbox']['body'][1][2]; nose = c.pre('body') & (c.z > zm - 1.3); P.dark(nose, SLATE * 0.6); P.lamp(nose & (c.z > zm - 0.22), WINC, glow=0.6)
PLAN = dict(planar=['body', 'fin', 'extra', 'barrel', 'sleeve', 'shield', 'gun', 'gbarrel'], facet_angle={'body': 25}, occlusion=True, maxlen=14.0, twin_tol=0.05)
UVPLAN, paint = make(dict(plan=PLAN, k=0.3, eng_z=-5.5, nozzle=(1.9, 0.62), nozzle_y=0.95, team=_team, extra=_extra, round=('body',), guns=('barrel', 'sleeve', 'gun'), win_dens=0.3, windows=lambda c: c.pre('body')))
RES = 512
