"""Starslayer (plasma artillery cruiser): UV plan + paint layout. World axes: +z bow, +y up.
The centre body is mirrored across x; the two slab hulls are mirror twins; the four artillery barrels and the
three flak mounts share one set of texels each."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith('turret'): return 1.3
    if name.startswith('barrel'): return 1.15
    if n[1] < -0.97: return 0.6
    return 1.0
def _unique(name, c, n):                            # top deck carries the hull number
    return name == 'body' and n[1] > 0.95 and 20.5 < c[1] < 21.5
UVPLAN = dict(mirror={'body': 'x', 'gbarrel_1_1': 'xy', 'barrel_2': 'x'}, tol={'barrel_2': 0.1},
              planar=['body', 'right', 'left', 'turret', 'barrel', 'gbarrel'], scale=_scale, unique=_unique, occlusion=True, maxlen=125.0)
HULL_NO = 'CA-09'

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; lp = F['lpos']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9)
    up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7; outb = nrm[:, 0] * sx > 0.75; inb = nrm[:, 0] * sx < -0.75
    Bd = is_('body'); Pd = is_('right') | is_('left'); hullp = Bd | Pd
    pk = F['piece'] * 0

    # ------------------------------------------------------------------ base plating
    P.hull(hullp & up, xa, z, big=(6.5, 8.5), small=(2.17, 2.125), key=pk)
    P.hull(hullp & down, xa, z, tone=0.62, big=(6.5, 8.5), small=(3.25, 4.25), key=pk)
    P.hull(hullp & side, a, y, big=(7.0, 4.6), small=(1.75, 1.53))
    P.hull(hullp & slant, a, b, tone=0.92, big=(7.0, 4.6), small=(1.75, 1.53))

    # ------------------------------------------------------------------ CENTRE BODY
    deck = Bd & up & (y > 20.5) & (y < 21.5)
    P.paint_team(deck & (xa > 15.2) & (xa < 19.4) & (z > -23) & (z < 31))
    P.plate_text(deck, HULL_NO, z, x, 2.5, 6.0, pad=1.4)
    P.paint_slate(deck & (xa < 12) & (z > -23.5) & (z < -17) & (((xa + 0.3) % 2.17) < 1.25))
    brd = Bd & (y > 21.6)                                                        # bridge tower
    P.hull(brd & side, a, y, tone=1.05, big=(5.0, 3.0), small=(1.67, 1.5), slate=0.0); P.paint_team(brd & up & (dcv > 0.6))
    win = brd & fwd & (y > 28.2) & (y < 30.8) & (dcv > 0.5); P.dark(win, MECH * 0.6); P.lamp(win & (np.abs(y - 29.5) < 0.75) & (np.abs(((xa + 0.6) % 1.2) - 0.6) < 0.42), WIN, glow=0.6)
    P.windows(brd & side & ~fwd, a, y, 1.5, 0.8, 11); P.lamp(brd & rear & (y > 31.2) & (dcv > 0.4) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.25))
    face = Bd & fwd & (z > 32) & (y < 21.2)                                      # bow face
    P.paint_team(face & (y > 16.2) & (y < 18.8) & (dcv > 0.6)); P.windows(face & (y < 15.5), a, y, 1.53, 0.9, 12)
    arr = face & (xa < 9.5) & (y > 1.2) & (y < 7.8); P.dark(arr, SLATE * 0.7); P.lamp(arr & (np.abs(((y + 0.3) % 2.2) - 1.1) < 0.2) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.42) & (y > 1.8) & (y < 7.3), WINC)
    chin = Bd & (nrm[:, 2] > 0.3) & (y < -1.5); P.hazard(chin & down.__or__(slant) & (dcv > 0.3) & (dcv < 1.0), xa, z + y, 0.6)
    bs = Bd & side & outb & (xa > 15.5) & (y < 21.3); P.paint_team(bs & (np.abs(y - 16.4) < 1.0)); P.windows(bs, a, y, 1.53, 0.5, 13)
    rs = Bd & (nrm[:, 2] < -0.5) & (nrm[:, 1] > 0.5) & (y > 7.5)                 # aft slope
    P.paint_slate(rs & (xa < 17.5) & (dcv > 1.6) & (((xa + 0.3) % 2.17) < 1.25)); P.hazard(rs & (dcv > 0.35) & (dcv < 1.1) & (xa > 18.5), z, y, 0.6)
    eng = Bd & rear & (z < -36) & (y < 8.5); P.nozzles(eng, xa - 0.5, y + 11.5, cell=10.5, rad=3.6)
    P.dark(eng & (dcv < 0.7), MECH * 0.9); P.emit[eng & (dcv < 0.7)] = 0; P.glow[eng & (dcv < 0.7)] = 0
    lr = Bd & (nrm[:, 2] < -0.4) & (nrm[:, 1] < -0.5); P.mech(lr, xa, b, rib=1.5)
    P.lamp(lr & (dcv > 0.8) & (np.abs(b) < 0.45) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.9), ENGINE, glow=0.7)

    # ------------------------------------------------------------------ SLAB HULLS
    ptop = Pd & up & (y > 38)
    P.paint_team(ptop & (xa > 36) & (xa < 53) & (z > 3) & (z < 17.5)); P.paint_team(ptop & (xa > 36) & (xa < 39.5) & (z > -26) & (z < 0))
    P.ring(ptop, xa - 44.4, z + 10.3, 3.3, w=0.7, ticks=False)
    P.paint_slate(ptop & (xa > 41.5) & (xa < 53.5) & (z > -26.5) & (z < -18.5) & (((z + 0.2) % 2.125) < 1.2))
    P.lamp(ptop & (xa > 53.9) & (dcv > 0.2) & (dcv < 0.8) & (np.abs(((z + 3.0) % 6.0) - 3.0) < 0.25))
    ow = Pd & side & outb & (xa > 65) & (xa < 67) & (z > -28.5) & (z < 21.5)    # outer wall
    P.paint_team(ow & (y > 11.5) & (y < 17.0) & (z > -24) & (z < 17)); P.paint_slate(ow & (y > 12.6) & (y < 15.9) & (z > -22.5) & (z < -9) & (((z + 0.3) % 2.25) < 1.3))
    P.windows(ow, a, y, 1.53, 0.75, 21); P.lamp(ow & (np.abs(y + 17.6) < 0.22) & (np.abs(((z + 3.0) % 6.0) - 3.0) < 0.25))
    och = Pd & slant & (nrm[:, 0] * sx > 0.6) & (np.abs(nrm[:, 2]) < 0.3) & (z > -28.5) & (z < 21.5) & (xa > 54)   # outer chamfers
    P.paint_team(och & (dcv > 2.2) & (z > -12) & (z < 4) & (y > 0)); P.windows(och, a, b, 1.53, 0.45, 22)
    ich = Pd & slant & (nrm[:, 0] * sx < -0.6) & (np.abs(nrm[:, 2]) < 0.3) & (xa < 35); P.windows(ich, a, b, 1.53, 0.35, 23)
    iw = Pd & side & inb & (xa < 35) & (xa > 33); P.hull(iw, a, y, tone=0.75, big=(7.0, 4.6), small=(3.5, 1.53)); P.windows(iw, a, y, 1.53, 0.3, 24)
    ff = Pd & fwd & (z > 26) & (z < 28) & (xa > 31)                               # broad bow face of each slab
    P.hazard(ff & (dcv > 0.5) & (dcv < 1.4), xa, y, 0.7)
    P.paint_team(ff & (dcv > 2.6) & (np.abs(np.abs(y - 0.5) - 28.5) < 3.2) & (xa > 37) & (xa < 61))
    grille = ff & (xa > 40) & (xa < 60) & (np.abs(y - 0.5) < 15); P.dark(grille, MECH * 0.7)
    slot = grille & (np.abs(((xa - 40) % 4.0) - 2.0) < 0.75) & (np.abs(y - 0.5) < 13.2); P.alb[slot] = ENGINE * 0.9; P.emit[slot] = 0.85; P.glow[slot] = 0.6
    P.alb[slot & (np.abs(((y + 0.5) % 2.2) - 1.1) < 0.22)] = MECH * 0.6; P.emit[slot & (np.abs(((y + 0.5) % 2.2) - 1.1) < 0.22)] = 0
    P.windows(ff & ~grille, a, y, 1.53, 0.5, 25)
    fch = Pd & (nrm[:, 2] > 0.25) & ~fwd & (z > 20.5); P.hull(fch, a, b, tone=0.85)
    strut = Pd & (xa < 34.2) & (np.abs(y) < 15) & (z > -19) & (z < 41)          # arm to the body, artillery breech block
    P.hull(strut & up, xa, z, tone=0.8, big=(4.0, 4.0), small=(2.0, 2.0), key=pk, slate=0.0); P.paint_slate(strut & up & (z > -14) & (z < 10) & (dcv > 1.0) & (((z + 0.2) % 2.0) < 1.1))
    P.mech(strut & fwd & (z < 15), xa, y, rib=1.4); P.mech(strut & rear, xa, y, rib=1.4); P.hazard(strut & fwd & (z > 39) & (dcv < 0.9), xa, y, 0.5)
    stub = Pd & (xa > 66.3) & (np.abs(y - 1) < 6) & (z > -6) & (z < 15)          # flak platform on the outer wall
    P.hull(stub & up, xa, z, tone=0.78, big=(4.0, 4.0), small=(2.0, 2.0), key=pk, slate=0.0); P.hazard(stub & up & (dcv > 0.3) & (dcv < 0.95), xa, z, 0.5)
    P.ring(stub & up, xa - 77.2, z - 5.0, 2.6, w=0.6, ticks=False); P.mech(stub & ~up & ~down, a, b, rib=1.2, pipes=False)
    # drives
    pe = Pd & rear & (z < -48); P.nozzles(pe, xa - 39.2, y + 13.2, cell=9.0, rad=3.2)
    P.dark(pe & (dcv < 0.7), MECH * 0.9); P.emit[pe & (dcv < 0.7)] = 0; P.glow[pe & (dcv < 0.7)] = 0
    p43 = Pd & rear & (z > -44) & (z < -42); P.nozzles(p43, xa - 37.4, np.abs(y - 0.5) - 23.2, cell=7.4, rad=2.5)
    P.dark(p43 & (dcv < 0.6), MECH * 0.9); P.emit[p43 & (dcv < 0.6)] = 0; P.glow[p43 & (dcv < 0.6)] = 0
    p28 = Pd & rear & (z > -29) & (z < -27); P.mech(p28, xa, y, rib=1.5, pipes=False)
    P.lamp(p28 & (dcv > 0.7) & (np.abs(np.abs(y - 0.5) - 36.0) < 0.3) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.9), ENGINE, glow=0.7)
    asl = Pd & (nrm[:, 2] < -0.15) & ~rear & (z < -27.5); P.hull(asl & ~up & ~down, a, b, tone=0.82); P.paint_team(asl & (nrm[:, 1] > 0.6) & (dcv > 1.6) & (y > 0) & (y < 30))

    # ------------------------------------------------------------------ belly
    bl = hullp & down & ~P.lock; P.team[bl & (P.seam > 0.1) & Bd & (xa > 8) & (xa < 10.5)] = 1.0; P.team[bl & (P.seam > 0.1) & Pd & (np.abs(xa - 44.5) < 1.4) & (y < -30)] = 1.0

    # ------------------------------------------------------------------ PLASMA ARTILLERY
    Ga = is_('gbarrel'); zl = lp[:, 2]; P.noedge |= Ga; P.seam[Ga] = 1e9; P.team[Ga] = 0
    P.alb[Ga] = MECH * 1.25; P.refl[Ga] = 0.3
    P.alb[Ga & (np.abs(((zl - 41) % 6.2) - 3.1) < 0.35) & (zl < 78)] = MECH * 0.6
    P.alb[Ga & (zl > 41.2) & (zl < 47.5)] = BASE * 0.9; P.team[Ga & (zl > 43.0) & (zl < 46.0)] = 1.0
    P.alb[Ga & (zl > 78)] = BASE * 1.05; P.alb[Ga & (zl > 84.2) & (zl < 86.6)] = HAZ_Y * 0.9
    coil = Ga & (zl > 60) & (zl < 76) & (np.abs(((zl - 60) % 3.1) - 1.55) < 0.5); P.alb[coil] = ENGINE * 0.85; P.emit[coil] = 0.7; P.glow[coil] = 0.5
    muz = Ga & (nrm[:, 2] > 0.9) & (zl > 88); P.alb[muz] = np.array([0.03, 0.03, 0.04]); rr = np.hypot(lp[:, 0], lp[:, 1]); P.lamp(muz & (rr < 2.4), ENGINE, glow=0.8)

    # ------------------------------------------------------------------ FLAK MOUNTS
    G = is_('turret') | is_('barrel'); P.guns(G)
    fb = is_('barrel') & (lp[:, 2] < 8.2); P.alb[fb] = BASE * 0.95; P.team[fb & (nrm[:, 1] > 0.6)] = 1.0; P.alb[fb & (nrm[:, 2] < -0.7)] = MECH
    return P.finish()
