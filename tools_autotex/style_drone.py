"""Drone (the little fighter the hives and carriers launch): 9 units across, so a 512 texture and a paint
scale of about a fifth of the capital ships'. World axes: +z nose, +y up. The mesh is slightly off true symmetry, so nothing is shared.
Central cockpit pod, two struts, two gun booms with a barrel forward and an engine block aft."""
import numpy as np
from hullkit import *

UVPLAN = dict(planar=['body'], occlusion=True, maxlen=12.0)
RES = 512

def paint(F):
    P = Painter(F, k=0.2); pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; pk = F['piece'] * 0
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x + 0.02); A = xa > -1
    up = nrm[:, 1] > 0.5; down = nrm[:, 1] < -0.5; rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7
    pod = xa < 1.7; strut = (xa >= 1.7) & (xa < 2.45) & (z > -0.3) & (z < 0.8); boom = ~pod & ~strut
    P.hull(A & (up | down), x, z, big=(1.4, 0.9), small=(0.35, 0.3), key=pk); P.hull(A & ~up & ~down, a, b, tone=0.95, big=(1.4, 0.9), small=(0.35, 0.3))
    P.hull(A & down, x, z, tone=0.62, big=(1.4, 0.9), small=(0.7, 0.6), key=pk)
    # cockpit pod: team colour back, dark canopy at the nose, exhaust behind
    P.paint_team(pod & up & (z < 1.0)); can = pod & up & (z > 1.15); P.dark(can, SLATE * 0.5); P.refl[can] = 0.5
    P.lamp(can & (np.abs(z - 1.6) < 0.09) & (xa < 0.45), WINC, e=0.9, glow=0.5)
    P.lamp(pod & rear, ENGINE, glow=0.9)
    P.mech(strut, x, z, rib=0.16, pipes=False)
    # gun booms
    brl = boom & (z > 1.9) & (xa < 3.3); P.dark(brl, MECH * 1.1); P.refl[brl] = 0.3
    P.alb[brl & (np.abs(((z - 1.9) % 0.5) - 0.25) < 0.05)] = MECH * 0.55; P.alb[brl & (z > 3.3)] = HAZ_Y * 0.9; P.alb[brl & (z > 3.45)] = LIGHT * 0.7
    P.alb[brl & fwd & (z > 3.6)] = np.array([0.02, 0.02, 0.03])
    eng = boom & (z < -1.6); P.paint_team(eng & up & (z > -3.7)); P.paint_slate(eng & up & (z <= -3.7))
    P.dark(eng & rear & (z < -4.2), MECH * 0.8); P.lamp(eng & rear & (z < -4.2), ENGINE, glow=1.0)
    P.lamp(boom & rear & (z > -1.3) & (z < -0.4), ENGINE, e=0.8, glow=0.6)
    fin = boom & ~eng & ~brl & (xa > 3.55); P.paint_team(fin & (up | down)); P.lamp(fin & (xa > 4.3) & up, RED, glow=0.6)
    P.paint_slate(boom & ~eng & ~brl & ~fin & up & (z > 0.9) & (z < 1.7))
    return P.finish()
