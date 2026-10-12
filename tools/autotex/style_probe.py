"""Iris (recon probe): body, sensor head and tail."""
import numpy as np
from hullkit import *
from style_shipgen import make
def _extra(c):
    P = c.P; hd = c.pre('head'); P.paint_slate(hd & c.top & (c.dcv > 0.25)); P.lamp(hd & c.fwd & (c.dcv > 0.12), WINC, e=0.9, glow=0.7)
    P.paint_team(c.pre('tail') & (c.dcv > 0.25) & ~c.rear)
AUTO = dict(canopy=None, tips=0); CFG = dict(extra=_extra)
PLAN = dict(mirror={'body': 'x', 'head': 'x', 'tail': 'x'}, planar=['body', 'head', 'tail'], occlusion=True, maxlen=30.0, twin_tol=0.25)
UVPLAN, paint = make(dict(plan=PLAN, k=0.38, auto=AUTO, win_dens=0.3, **CFG))
RES = 1024
