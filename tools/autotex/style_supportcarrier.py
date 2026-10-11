"""Battle Carrier (supportcarrier.s3o, also the Advanced Battle Carrier): UV plan + paint layout.
World axes: +z bow, +y up. The body is mirrored across x; side pods, engine nacelles and gun platforms are
mirrored / flipped copies of each other, so each pair shares one set of texels."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith('turret'): return 1.5
    if name.startswith('barrel'): return 1.25
    if n[1] < -0.97: return 0.6                     # flat undersides
    return 1.0
def _unique(name, c, n):                            # aft deck carries the hull number
    return name == 'body' and n[1] > 0.95 and c[1] > 9.5 and c[2] < -19
UVPLAN = dict(mirror={'body': 'x'}, planar=['body', 'right', 'left', 'platform0', 'extra', 'enginer', 'enginel'],
              scale=_scale, unique=_unique, occlusion=True, maxlen=125.0)
HULL_NO = 'BC-12'

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9)
    up = nrm[:, 1] > 0.85; down = nrm[:, 1] < -0.85; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.75; fwd = nrm[:, 2] > 0.75; outb = nrm[:, 0] * sx > 0.8; inb = nrm[:, 0] * sx < -0.8
    Bd = is_('body'); Pd = is_('right') | is_('left'); Pl = is_('platform') | is_('extra'); En = is_('engine'); hullp = Bd | Pd | Pl | En
    pk = F['piece'] * 0

    # ------------------------------------------------------------------ base plating
    P.hull(hullp & up, xa, z, big=(6.0, 8.0), small=(2.0, 2.0), key=pk)
    P.hull(hullp & down, xa, z, tone=0.62, big=(6.0, 8.0), small=(3.0, 4.0), key=pk)
    P.hull(hullp & side, a, y, big=(7.0, 4.6), small=(1.75, 1.53))
    P.hull(hullp & slant, a, b, tone=0.92, big=(7.0, 4.6), small=(1.75, 1.53))

    # ------------------------------------------------------------------ BODY: decks
    top = Bd & up
    bow = top & (y > 10.5) & (z > 34.5)
    P.paint_team(bow & (xa > 5.6) & (xa < 8.2) & (z > 36) & (z < 58))
    P.paint_slate(bow & (xa < 4.4) & (z > 49.5) & (z < 56.5) & (((z + 0.3) % 1.75) < 1.0))
    dt = np.hypot(x, z - 40.2); tm = bow & (dt < 5.3); P.dark(tm & (dt < 4.6), MECH); P.team[tm & (dt >= 4.6)] = 1.0; P.lock[tm & (dt >= 4.6)] = True
    slope = Bd & (nrm[:, 1] > 0.6) & (z > 59.2) & (y > 4); P.hazard(slope & (dcv > 0.35) & (dcv < 1.05), xa, z, 0.6); P.paint_team(slope & (xa < 5.5) & (dcv > 2.0))
    ramp = top & (z > 18.2) & (z < 34.8) & (y > 6.5); P.paint_slate(ramp & (xa > 1.2) & (xa < 7.2) & (((z + 0.4) % 2.0) < 1.15) & (z > 20) & (z < 33))
    mid = top & (y > 6.5) & (y < 7.5) & (z < 18.2)
    P.paint_team(mid & (xa > 5.9) & (xa < 8.2) & (z > -14.5) & (z < 16.5))
    lift = mid & (xa < 4.6) & (z > -9.5) & (z < 5.5); P.dark(lift, DECK * 0.75)
    P.hazard(lift & ((xa > 3.85) | (z < -8.75) | (z > 4.75)), xa, z, 0.55)
    P.lamp(lift & (xa < 3.4) & (np.abs(((z + 2.0) % 3.0) - 1.5) < 0.2) & (np.abs(xa - 2.6) < 0.2), WINC)
    aft = top & (y > 9.5) & (z < -19.5)
    P.paint_team(aft & (xa > 6.3) & (xa < 8.3) & (z > -49.5) & (z < -21.5))
    h = 4.2; w = text_w(HULL_NO, h); x0 = -35.2 - w / 2
    plate = aft & (z > x0 - 1.2) & (z < x0 + w + 1.2) & (xa < h / 2 + 1.0) & ~P.lock
    P.alb[plate] = LIGHT * (1 - 0.5 * (1 - smooth(0.04, 0.1, np.minimum(np.minimum(z - (x0 - 1.2), x0 + w + 1.2 - z), h / 2 + 1.0 - xa)[plate])))[:, None]; P.seam[plate] = 1e9; P.team[plate] = 0
    P.paint_slate(aft & stencil(HULL_NO, z, x, x0, -h / 2, h))
    # hull sides
    bs = Bd & side & outb & (xa > 8.5) & (xa < 9.6) & (y > -12.5)
    P.paint_team(bs & (y > 2.6) & (y < 4.3)); P.windows(bs, a, y, 1.53, 0.75, 11)
    P.lamp(bs & (np.abs(y - 5.5) < 0.2) & (np.abs(((z + 2.5) % 5.0) - 2.5) < 0.22))
    P.mech(Bd & (xa > 9.6) & ~up & ~down, a, b, rib=1.3, pipes=False)             # struts out to the pods
    nose = Bd & fwd & (z > 66); P.dark(nose & (xa < 7.6) & (y > -5.6) & (y < 3.8), SLATE * 0.7)
    P.lamp(nose & (xa < 6.8) & (np.abs(((y + 0.6) % 2.4) - 1.2) < 0.2) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.42), WINC)
    # main engine
    eng = Bd & rear & (z < -50); P.nozzles(eng, xa - 1.4, y + 7.6, cell=6.2, rad=2.45)
    P.dark(eng & (dcv < 0.6), MECH * 0.9); P.emit[eng & (dcv < 0.6)] = 0; P.glow[eng & (dcv < 0.6)] = 0
    # keel hangar: door, hanging flight deck, lit ceiling
    keel = Bd & (y < -11.5)
    ks = keel & side & ~fwd & ~rear & (z < 19); P.hull(ks, a, y, tone=0.82, big=(7.0, 4.6), small=(1.75, 1.53)); P.windows(ks, a, y, 1.53, 0.6, 12)
    P.paint_team(ks & (y > -17.6) & (y < -16.2))
    door = keel & fwd & (z > 17) & (z < 19) & (xa < 9.3)
    P.dark(door, MECH * 0.55); deep = door & (xa < 7.4) & (y > -24.0) & (y < -13.2)
    g = np.minimum(np.abs((xa % 2.5) - 1.25), np.abs(((y + 24) % 2.2) - 1.1))
    P.alb[deep] = AMBER * (0.30 + 0.25 * smooth(0.05, 0.2, g[deep]))[:, None]; P.emit[deep] = 0.55; P.glow[deep] = 0.35
    P.lamp(deep & (np.abs(y + 14.0) < 0.22) & (np.abs((xa % 1.8) - 0.9) < 0.5), AMBER); P.hazard(door & ~deep & (xa < 8.4) & (y > -25) & (y < -12.2), xa, y, 0.6)
    deck = keel & up & (z > 20); P.dark(deck, DECK * 0.8)
    P.alb[deck & (xa < 0.3) & (((z + 0.5) % 3.0) < 1.8)] = LIGHT; P.hazard(deck & (xa > 4.1), xa, z, 0.55)
    P.lamp(deck & (np.abs(xa - 3.3) < 0.2) & (np.abs(((z + 1.25) % 2.5) - 1.25) < 0.2), AMBER); P.lamp(deck & (z > 51.6) & (xa < 3.8) & (np.abs((xa % 1.2) - 0.6) < 0.25), RED)
    P.mech(keel & side & (z > 19) & (np.abs(nrm[:, 0]) > 0.9) & (y > -22.5), z, y, rib=1.4, pipes=False)   # pylons
    ceil_ = Bd & down & (y > -9) & (y < -7) & (z > 24); P.lamp(ceil_ & (np.abs(xa - 2.6) < 0.25) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.6), AMBER, glow=0.8)
    P.mech(keel & rear, xa, y, rib=1.4)

    # ------------------------------------------------------------------ SIDE PODS
    pt = Pd & (nrm[:, 1] > 0.8) & (y > 5)
    P.paint_team(pt & (xa > 18.5) & (xa < 29.5) & (z > 8.5) & (z < 19.0))
    P.paint_slate(pt & (xa > 17.5) & (xa < 30) & (z > -16.5) & (z < -11) & (((xa + 0.2) % 2.0) < 1.15))
    P.lamp(pt & (xa > 30.6) & (dcv > 0.2) & (dcv < 0.8) & (np.abs(((z + 3.0) % 6.0) - 3.0) < 0.24))
    ow = Pd & side & outb & (xa > 31)
    P.paint_team(ow & (y > 3.6) & (y < 5.3)); P.windows(ow, a, y, 1.53, 0.7, 21)
    for zc in (16.5, 5.5, -6.0):                                                 # torpedo tubes
        d = np.hypot(y, z - zc); t = ow & (d < 2.75); s = (np.degrees(np.arctan2(y, z - zc)) % 45) < 22.5
        P.alb[t] = np.where(s[t, None], HAZ_Y, HAZ_K); P.team[t] = 0; P.lock[t] = True
        P.alb[t & (d < 1.95)] = LIGHT * 0.7; P.alb[t & (d < 1.55)] = np.array([0.02, 0.02, 0.03]); P.lamp(t & (d < 0.3), RED)
    iw = Pd & side & inb & (xa < 15.5); P.hull(iw, a, y, tone=0.72, big=(7.0, 4.6), small=(3.5, 1.53)); P.windows(iw, a, y, 1.53, 0.3, 22)
    # recessed launch bay in each pod nose
    back = Pd & fwd & (z > 19.5) & (z < 20.5); P.dark(back, MECH * 0.55)
    g = np.minimum(np.abs(((xa - 17) % 2.4) - 1.2), np.abs(((y + 12) % 2.25) - 1.125)); dd = back & (dcv > 0.7)
    P.alb[dd] = WINC * (0.22 + 0.2 * smooth(0.05, 0.2, g[dd]))[:, None]; P.emit[dd] = 0.5; P.glow[dd] = 0.3
    P.lamp(dd & (np.abs(y - 4.4) < 0.22) & (np.abs(((xa - 17) % 1.6) - 0.8) < 0.45), WINC)
    rec = Pd & (z > 20.2) & (xa > 16.6) & (xa < 29.6) & (y > -12.6) & (y < 6.6) & ~fwd; P.dark(rec, MECH * 1.1)
    P.lamp(rec & (np.abs(((z - 20) % 2.2) - 1.1) < 0.16) & (z < 30.3), WINC, e=0.8, glow=0.5)
    rim = Pd & fwd & (z > 24.5); P.hazard(rim & (dcv < 0.95) & (dcv > 0.25), a, b, 0.55)
    pr = Pd & rear; P.mech(pr, xa, y, rib=1.5); P.lamp(pr & (np.abs(y + 3) < 0.25) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.35), ENGINE, glow=0.7)

    # ------------------------------------------------------------------ GUN PLATFORMS
    P.hull(Pl & ~up, a, b, tone=1.05, big=(4.0, 3.0), small=(1.33, 1.5), slate=0.0)
    ptop = Pl & up; P.hull(ptop, xa, z, tone=0.8, big=(4.0, 4.0), small=(2.0, 2.0), key=pk, slate=0.0)
    P.hazard(ptop & (dcv > 0.3) & (dcv < 0.95), xa, z, 0.5)
    dt = np.hypot(xa - 24.6, z + 2.7); P.dark(ptop & (dt < 2.5), MECH); P.team[ptop & (dt >= 2.5) & (dt < 3.1)] = 1.0; P.lock[ptop & (dt >= 2.5) & (dt < 3.1)] = True
    P.paint_team(Pl & side & outb & (dcv > 0.9)); P.paint_team(Pl & slant & (nrm[:, 1] > 0.3) & (dcv > 0.7) & (np.abs(nrm[:, 2]) < 0.3))

    # ------------------------------------------------------------------ ENGINE NACELLES
    fin = En & (np.abs(y) > 11.5)
    ft = fin & up & (y > 18); P.paint_team(ft & (xa > 18.0) & (xa < 23.0) & (((z > -50.3) & (z < -48.2)) | ((z > -39.6) & (z < -33.2))))
    dt = np.hypot(xa - 20.0, z + 44.0); tm = ft & (dt < 4.0); P.dark(tm & (dt < 3.4), MECH); P.team[tm & (dt >= 3.4)] = 1.0; P.lock[tm & (dt >= 3.4)] = True
    fs = fin & side & (np.abs(nrm[:, 0]) > 0.8); P.paint_team(fs & (np.abs(np.abs(y) - 15.6) < 1.1) & (z > -53) & (z < -34)); P.windows(fs, a, y, 1.53, 0.5, 31)
    fsl = fin & (nrm[:, 2] > 0.4) & (np.abs(nrm[:, 1]) > 0.5); P.paint_team(fsl & (dcv > 1.2))
    frr = fin & rear; P.dark(frr, MECH); P.lamp(frr & (dcv > 0.6) & (np.abs(((xa + 0.9) % 1.8) - 0.9) < 0.5), ENGINE, glow=0.8)
    P.mech(En & (np.abs(y) > 7.5) & (np.abs(y) < 12.6) & ~up & ~down & (xa > 17.5) & (xa < 23.5), a, b, rib=1.0, pipes=False)   # fin struts
    blk = En & ~fin
    bo = blk & side & outb & (xa > 30); P.paint_team(bo & (y > 1.6) & (y < 3.4)); P.windows(bo, a, y, 1.53, 0.7, 32)
    bi = blk & side & inb & (xa < 15); P.hull(bi, a, y, tone=0.72, big=(7.0, 4.6), small=(3.5, 1.53))
    sh = blk & slant & (nrm[:, 1] > 0.5) & (xa > 26.5); P.paint_team(sh & (dcv > 0.8) & (z > -44) & (z < -30))
    btop = blk & up & (y > 8); P.paint_team(btop & (xa > 14.6) & (xa < 16.6) & (z > -58) & (z < -28))
    big = blk & rear & (z < -67); P.nozzles(big, xa - 23.0 + 5.3, y + 5.3, cell=10.6, rad=3.9)
    P.dark(big & (dcv < 0.5), MECH * 0.9); P.emit[big & (dcv < 0.5)] = 0; P.glow[big & (dcv < 0.5)] = 0
    r60 = blk & rear & (z > -61) & (z < -59); P.mech(r60, xa, y, rib=1.3, pipes=False)
    P.nozzles(r60 & (np.abs(y) > 5.9) & (dcv > 0.5), xa - 14.2, y + 9.0 + 1.1, cell=4.25, rad=1.25)
    ext = blk & (z < -60.2) & ~rear; P.mech(ext, a, b, rib=1.2, pipes=False); P.hazard(ext & (z < -66.9), z, y, 0.5)
    intake = blk & fwd & (z > -27); P.mech(intake, xa, y, rib=1.1, pipes=False)
    P.lamp(intake & (np.abs(np.abs(y) - 6.6) < 0.22) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.55) & (dcv > 0.5), WINC, glow=0.6)
    P.hazard(intake & (dcv > 0.25) & (dcv < 0.85), xa, y, 0.55)

    # ------------------------------------------------------------------ belly stripe
    bl = hullp & down & ~P.lock; P.team[bl & (P.seam > 0.1) & Bd & (xa > 2.5) & (xa < 4.5) & (y < -11)] = 1.0
    P.team[bl & (P.seam > 0.1) & (Pd | En) & (np.abs(xa - 23) < 1.2)] = 1.0

    # ------------------------------------------------------------------ TURRETS
    lp = F['lpos']
    T4 = is_('turret_4'); P.hull(T4, a, b, tone=1.12, big=(2.6, 1.7), small=(0.87, 0.85), slate=0.0); P.team[T4 & (nrm[:, 1] > 0.35) & (dcv > 0.22)] = 1.0
    P.alb[T4 & (nrm[:, 1] < -0.2)] = MECH * 1.4
    T1 = is_('turret_1') | is_('turret_5'); P.alb[T1] = LIGHT * 0.88; P.seam[T1] = 1e9; P.noedge |= T1
    P.alb[T1 & (lp[:, 1] < -1.2)] = MECH * 1.3; P.team[T1 & (nrm[:, 1] > 0.5)] = 1.0
    P.turret(is_('turret_2') | is_('turret_3'), is_('barrel'))
    B1 = is_('barrel_1') | is_('barrel_5'); P.noedge |= B1
    P.alb[B1 & (lp[:, 2] < 4) & (lp[:, 2] > -9)] = BASE * 0.85                   # breech housing of the long guns
    P.team[B1 & (nrm[:, 1] > 0.6) & (lp[:, 2] < 2.5) & (lp[:, 2] > -8)] = 1.0
    P.alb[B1 & (lp[:, 2] < -9)] = MECH * 0.8
    return P.finish()
