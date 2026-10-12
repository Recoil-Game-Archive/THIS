"""Wraith (point defence): generic small-craft layout; the two long wings are team colour."""
import numpy as np
from hullkit import *
from style_shipgen import make
AUTO = dict(tips=0); CFG = dict(team_pieces=('wing',))
PLAN = dict(mirror={'body': 'x'}, planar=['body', 'wing'], occlusion=True, maxlen=30.0, twin_tol=0.25)
UVPLAN, paint = make(dict(plan=PLAN, k=0.38, auto=AUTO, win_dens=0.3, **CFG))
RES = 1024
