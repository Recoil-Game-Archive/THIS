"""Warhammer (cloaked missile assault ship): generic small-craft layout."""
import numpy as np
from hullkit import *
from style_shipgen import make
AUTO = dict(); CFG = dict()
PLAN = dict(mirror={'body': 'x'}, planar=['body'], occlusion=True, maxlen=30.0, twin_tol=0.25)
UVPLAN, paint = make(dict(plan=PLAN, k=0.38, auto=AUTO, win_dens=0.3, **CFG))
RES = 1024
