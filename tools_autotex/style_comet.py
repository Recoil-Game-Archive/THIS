"""Comet (fast attack destroyer): UV plan + paint layout. World axes: +z bow, +y up.
Bow, mid-body and engine block are each mirrored across x; the paired guns share texels."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith('turret'): return 1.4
    if name.startswith('barrel'): return 1.2
    if n[1] < -0.97: return 0.6
    return 1.0
def _unique(name, c, n):                            # bow deck carries the hull number
    return name == 'front' and n[1] > 0.95 and c[1] > 10.5 and -17.5 < c[2] < 16.5
UVPLAN = dict(mirror={'body': 'x', 'front': 'x', 'rear': 'x'}, planar=['body', 'front', 'rear', 'turret', 'barrel'],
              scale=_scale, unique=_unique, occlusion=True, maxlen=125.0)
HULL_NO = 'DD-21'

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; lp = F['lpos']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9)
    up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7; outb = nrm[:, 0] * sx > 0.8; inb = nrm[:, 0] * sx < -0.8
    Bd = is_('body'); Fr = is_('front'); Rr = is_('rear'); hullp = Bd | Fr | Rr
    pk = F['piece'] * 0

    # ------------------------------------------------------------------ base plating
    P.hull(hullp & up, xa, z, big=(6.0, 8.0), small=(2.0, 2.0), key=pk)
    P.hull(hullp & down, xa, z, tone=0.62, big=(6.0, 8.0), small=(3.0, 4.0), key=pk)
    P.hull(hullp & side, a, y, big=(7.0, 4.6), small=(1.75, 1.53))
    P.hull(hullp & slant, a, b, tone=0.92, big=(7.0, 4.6), small=(1.75, 1.53))

    # ------------------------------------------------------------------ BOW
    deck = Fr & up & (y > 10.5) & (z > 30.5) & (z < 64.5)
    P.paint_team(deck & (xa > 6.1) & (xa < 8.3) & (z > 32.5) & (z < 63))
    P.plate_text(deck, HULL_NO, z, x, 39.0, 4.2, pad=1.1)
    P.paint_slate(deck & (xa < 4.6) & (z > 58.5) & (z < 62.8) & (((z + 0.2) % 1.45) < 0.85))
    slope = Fr & (nrm[:, 1] > 0.5) & (z > 64.2) & (y > 6); P.hazard(slope & (dcv > 0.3) & (dcv < 1.0), xa, z, 0.55); P.paint_team(slope & (dcv > 1.7))
    nose = Fr & fwd & (z > 68); P.dark(nose & (dcv > 1.0), SLATE * 0.7)
    P.lamp(nose & (dcv > 1.5) & (np.abs(((y + 0.5) % 2.4) - 1.2) < 0.2) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.42), WINC)
    fs = Fr & side & outb & (xa > 10.5) & (xa < 11.6) & (z > 30.5)
    P.paint_team(fs & (y > 4.6) & (y < 6.2) & (z < 63.5)); P.windows(fs, a, y, 1.53, 0.7, 11)
    P.lamp(fs & (np.abs(y + 10.6) < 0.2) & (np.abs(((z + 2.5) % 5.0) - 2.5) < 0.22))
    stub = Fr & (xa > 11.3) & (z > 48) & (z < 56); P.dark(stub & ~up, MECH * 1.2); P.hazard(stub & up & (dcv > 0.25), xa, z, 0.5)
    P.paint_team(Fr & slant & (nrm[:, 1] > 0.4) & outb.__or__(nrm[:, 0] * sx > 0.5) & (z > 34) & (z < 62) & (dcv > 0.8) & (y > 6.5))
    neck = Fr & (z < 33.2) & (xa < 6.5) & (y > -6); P.mech(neck & side, z, y, rib=1.3); P.paint_slate(neck & up & (((z + 0.3) % 1.8) < 1.0) & (dcv > 0.6))
    keel = Fr & (y < -5.5) & side; P.hull(keel, a, y, tone=0.8, big=(7.0, 4.6), small=(1.75, 1.53)); P.windows(keel, a, y, 1.53, 0.5, 12)
    P.paint_team(keel & (np.abs(y + 9.6) < 0.6) & (xa > 4))
    P.mech(Fr & rear & (z < 41), xa, y, rib=1.4)

    # ------------------------------------------------------------------ MID BODY
    top = Bd & up & (y > 11.5) & (y < 12.3)
    P.paint_team(top & (xa > 9.0) & (xa < 11.2) & (z > -9.5) & (z < 20.5))
    P.ring(top, x, z - 5.8, 8.0, w=0.8)
    dome = Bd & (y > 12.35); P.alb[dome] = LIGHT * 0.95; P.noedge |= dome; P.seam[dome] = 1e9; P.team[dome] = 0; P.lock[dome] = False
    P.team[dome & (y > 13.3) & (y < 14.2)] = 1.0; P.lamp(dome & (y > 15.4), WINC)
    shl = Bd & (nrm[:, 1] > 0.5) & (xa > 12) & (xa < 24.5) & (y > 2.5)
    P.paint_team(shl & (z > -8.5) & (z < 5.5) & (dcv > 1.3) & (xa < 20)); P.paint_slate(shl & (z > 8) & (z < 20.5) & (((z + 0.2) % 2.0) < 1.15) & (dcv > 1.0))
    P.paint_team(shl & (z < -8.5) & (dcv > 1.2))
    arm = Bd & up & (y < -1.5) & (y > -3.5) & (xa > 18.5)                        # sponson decks
    P.hull(arm, xa, z, tone=0.78, big=(4.0, 4.0), small=(2.0, 2.0), key=pk, slate=0.0)
    P.hazard(arm & (dcv > 0.3) & (dcv < 0.95) & (xa > 21), xa, z, 0.5); P.ring(arm, xa - 26.6, z + 1.1, 5.4, w=0.7)
    bw = Bd & side & ~rear & ~fwd & (xa > 19.5) & (np.abs(nrm[:, 0]) > 0.8) & (y > -9.5); P.paint_team(bw & (np.abs(y - 1.0) < 0.8)); P.windows(bw, a, y, 1.53, 0.7, 21)
    P.lamp(Bd & side & (xa > 34.5) & (np.abs(y + 4.5) < 0.3) & (np.abs(z - 0.5) < 2.6) & (np.abs(((z + 0.6) % 1.2) - 0.6) < 0.3))
    bf = Bd & fwd & (z > 17) & (xa > 11.5); P.windows(bf, a, y, 1.53, 0.7, 22); P.paint_team(bf & (np.abs(y - 1.0) < 0.8))
    P.mech(Bd & rear & (z < -6.5) & (xa < 20.5), xa, y, rib=1.4)
    P.mech(Bd & fwd & (z > 21.5) & (xa < 12.2), xa, y, rib=1.4)

    # ------------------------------------------------------------------ ENGINE BLOCK
    rt = Rr & (nrm[:, 1] > 0.75) & (z > -56.5) & (xa > 2.9)
    rib = ((z > -45.6) & (z < -38.6)) | ((z > -35.6) & (z < -28.6))
    P.paint_team(rt & rib & (xa > 11.8) & (y > 7.6) & (dcv > 0.6) & (xa < 24.5)); P.paint_team(rt & ~rib & (xa > 4.3) & (xa < 7.2) & (z > -54.5) & (z < -18.5))
    P.paint_slate(rt & ~rib & (xa > 12) & (xa < 22) & (z > -54.5) & (z < -47.5) & (((xa + 0.2) % 2.0) < 1.15))
    P.lamp(rt & (xa > 22.6) & (dcv > 0.2) & (dcv < 0.75) & (np.abs(((z + 2.5) % 5.0) - 2.5) < 0.22))
    ow = Rr & side & outb & (xa > 23.5)
    P.paint_team(ow & (y > 3.4) & (y < 4.9) & (xa < 25)); P.windows(ow & (xa < 25), a, y, 1.53, 0.6, 31)
    for zc in (-32.5, -42.0): P.tube(ow & (xa > 25.5), y, z - zc)
    gap = Rr & side & inb & (xa < 5.6) & (z < -16)                               # trench between the engine lobes
    P.mech(gap, z, y, rib=1.5, pipes=False); P.lamp(gap & (np.abs(np.abs(y + 1.5) - 5.0) < 0.22) & (np.abs(((z + 1.5) % 3.0) - 1.5) < 0.9), ENGINE, e=0.9, glow=0.7)
    spine = Rr & (xa < 3.2) & (z > -31); P.mech(spine & ~inb, z, y, rib=1.2, pipes=False)
    tail = Rr & (z < -56.2) & ~rear
    P.hull(tail & side, a, y, tone=0.8, big=(5.0, 4.6), small=(1.67, 1.53)); P.hazard(tail & (z < -64.9), z, y + xa, 0.5); P.paint_team(tail & (nrm[:, 1] > 0.6) & (dcv > 1.2) & (z > -64.5))
    eng = Rr & rear & (z < -65); P.nozzles(eng, xa - 5.0, y + 8.8, cell=7.5, rad=2.75)
    P.dark(eng & (dcv < 0.55), MECH * 0.9); P.emit[eng & (dcv < 0.55)] = 0; P.glow[eng & (dcv < 0.55)] = 0
    r56 = Rr & rear & (z > -57) & (z < -55); P.mech(r56, xa, y, rib=1.3, pipes=False)
    P.lamp(r56 & (dcv > 0.5) & (np.abs(y - 9.6) < 0.3) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.8), ENGINE, glow=0.7)
    P.lamp(r56 & (dcv > 0.5) & (np.abs(y + 11.6) < 0.3) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.8), ENGINE, glow=0.7)
    rf = Rr & (nrm[:, 2] > 0.6) & (z > -23.5) & (np.abs(nrm[:, 1]) < 0.3); P.windows(rf, a, y, 1.53, 0.5, 32)
    ribf = Rr & (np.abs(nrm[:, 2]) > 0.7) & (xa > 9.5) & (z < -27) & (z > -47) & (np.abs(nrm[:, 1]) < 0.75); P.dark(ribf & (dcv > 0.35), MECH)

    # the two hull halves are sealed shells that meet at x=0; don't draw their shared edge as a highlight line
    P.noedge |= hullp & (xa < 0.3)

    # ------------------------------------------------------------------ belly
    bl = hullp & down & ~P.lock; P.team[bl & (P.seam > 0.1) & (xa > 3.5) & (xa < 5.5)] = 1.0

    # ------------------------------------------------------------------ GUNS
    G = is_('turret') | is_('barrel'); tur, slv, brl = P.guns(G)
    big = is_('turret_1') | is_('turret_2'); P.alb[big & (lp[:, 1] < -1.9)] = DECK * 0.8; P.team[big & (lp[:, 1] < -1.5)] = 0
    hb = is_('barrel_1') | is_('barrel_2'); br = hb & (lp[:, 2] < 2.3); P.alb[br] = BASE * 0.9; P.team[br & (nrm[:, 1] > 0.8)] = 1.0; P.alb[br & (nrm[:, 2] < -0.7)] = MECH
    mb = is_('barrel_3') | is_('barrel_4'); blk = mb & (lp[:, 2] > 6.6) & (lp[:, 2] < 11.4) & (np.abs(lp[:, 0]) + np.abs(lp[:, 1] + 1.0) > 1.2); P.alb[blk] = BASE * 0.9
    return P.finish()
