"""Torpedo and small missile: pale casing, red warhead, yellow and team bands, dark fins, glowing motor.
One routine for both; lengths are taken from the model."""
import numpy as np
from hullkit import *
UVPLAN = dict(planar=['body', 'base'], occlusion=True, maxlen=8.0)
RES = 256
def paint(F):
    pos = F['pos']; nrm = F['nrm']; z = pos[:, 2]; r = np.hypot(pos[:, 0], pos[:, 1]); z0, z1 = z.min(), z.max(); L = z1 - z0; zl = (z - z0) / L
    P = Painter(F, k=0.1 * L / 6.0); P.noedge[:] = True; A = zl > -1; rb = np.percentile(r[(zl > 0.35) & (zl < 0.65)], 90)
    P.alb[A] = LIGHT * 0.92; P.seam[A] = 1e9
    P.alb[A & (zl > 0.74)] = np.array([0.66, 0.10, 0.08]); P.alb[A & (np.abs(zl - 0.70) < 0.035)] = HAZ_Y * 0.95; P.alb[A & (np.abs(zl - 0.52) < 0.012)] = MECH * 1.2
    P.team[A & (zl > 0.36) & (zl < 0.46)] = 1.0; P.alb[A & (zl > 0.96)] = MECH * 0.9
    fin = A & (r > rb * 1.25) & (zl < 0.5); P.alb[fin] = MECH * 1.5; P.team[fin] = 0; P.alb[A & (zl < 0.12) & ~fin] = MECH * 1.1; P.team[A & (zl < 0.12)] = 0
    P.lamp(A & (nrm[:, 2] < -0.7) & (zl < 0.06) & (r < rb * 1.1), ENGINE, glow=1.0)
    return P.finish()
