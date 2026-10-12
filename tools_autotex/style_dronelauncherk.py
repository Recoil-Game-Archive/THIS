"""Crossbow (drone launcher): hull with two drones docked on its flanks and a turret on top."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _extra(c):
    P = c.P; d = c.pre('drone'); lp = c.F['lpos']; P.noedge |= d
    P.alb[d] = LIGHT * 0.95; P.seam[d] = 1e9; P.team[d] = 0; P.team[d & (np.abs(lp[:, 0]) < 1.7) & (np.abs(c.nrm[:, 1]) > 0.5) & (lp[:, 2] < 1.0)] = 1.0
    P.dark(d & (np.abs(lp[:, 0]) > 2.3) & (lp[:, 2] > 1.9), MECH * 1.1); P.lamp(d & c.rear & (lp[:, 2] < -4.2), ENGINE, glow=0.8)
    P.team[d & (np.abs(lp[:, 0]) > 2.5) & (lp[:, 2] < -1.6) & (np.abs(c.nrm[:, 1]) > 0.5)] = 1.0
AUTO = dict(); CFG = dict(extra=_extra)
PLAN = dict(mirror={'body': 'x'}, planar=['body', 'drone'], occlusion=True, maxlen=30.0, twin_tol=0.25)
UVPLAN, paint = make(dict(plan=PLAN, k=0.38, auto=AUTO, win_dens=0.3, **CFG))
RES = 1024
