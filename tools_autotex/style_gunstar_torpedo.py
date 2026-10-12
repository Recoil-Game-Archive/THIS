"""Gunstar (torpedo): cigar hull, two wings carrying four torpedoes, twin thruster blocks aft, a small turret on top."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _team(c):
    return (c.pre('body') & (c.nrm[:, 1] > 0.3) & (c.z > -3.0) & (c.z < -0.5) & (c.xa < 1.6)) | (c.pre('wing') & c.top & (c.dcv > 0.3) & (c.xa > 5.0) & (c.xa < 6.6)) | (c.pre('thrusters') & c.top & (c.dcv > 0.3))
def _extra(c):
    P = c.P; zm = c.F['bbox']['body'][1][2]; nose = c.pre('body') & (c.z > zm - 1.3); P.dark(nose, SLATE * 0.6); P.lamp(nose & (c.z > zm - 0.22), WINC, glow=0.6)
    P.hazard(c.pre('wing') & c.fwd, c.x, c.y, 0.3)
PLAN = dict(mirror={'body': 'x', 'thrusters': 'x', 'turret_2': 'x', 'sleeve_2': 'x'}, planar=['body', 'thrusters', 'wing', 'torp', 'turret', 'sleeve', 'gbarrel'], facet_angle={'body': 25}, occlusion=True, maxlen=14.0)
UVPLAN, paint = make(dict(plan=PLAN, k=0.3, eng_z=-6.0, nozzle=(2.2, 0.75), nozzle_y=0.4, team=_team, extra=_extra, round=('body',), win_dens=0.3, windows=lambda c: c.pre('body')))
RES = 512
