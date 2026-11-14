"""Fleet Carrier: UV plan + paint layout (hull look comes from hullkit).
World axes: +z bow, +y up. Centre hull (front/link/back) is mirrored across x; the two pods are mirror images."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith('turret'): return 1.5
    if name.startswith('barrel'): return 1.3
    if n[1] < -0.97: return 0.6                     # flat undersides
    return 1.0
def _unique(name, c, n):                            # bow prong deck carries the hull number
    return name == 'front' and n[1] > 0.95 and c[2] > -3.5 and abs(c[0]) < 10.5 and c[1] > 8
UVPLAN = dict(mirror={'front': 'x', 'link': 'x', 'back': 'x'}, planar=['front', 'link', 'back', 'left', 'right'],
              scale=_scale, unique=_unique, occlusion=True, maxlen=100.0)
HULL_NO = 'CV-07'

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x)
    up = nrm[:, 1] > 0.85; down = nrm[:, 1] < -0.85; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.75; fwd = nrm[:, 2] > 0.75; outb = nrm[:, 0] * np.sign(x + 1e-9) > 0.8; inb = nrm[:, 0] * np.sign(x + 1e-9) < -0.8
    Fr = is_('front'); Lk = is_('link'); Bk = is_('back'); Pod = is_('left') | is_('right'); hullp = Fr | Lk | Bk | Pod
    pk = F['piece'] * 0                             # one panel layout for the whole deck, continuous across pieces

    # ------------------------------------------------------------------ base plating
    P.hull(hullp & up, xa, z, big=(6.5, 9.0), small=(2.17, 2.25), key=pk)
    P.hull(hullp & down, xa, z, tone=0.62, big=(6.5, 9.0), small=(3.25, 4.5), key=pk)
    P.hull(hullp & side, a, y, big=(7.0, 4.6), small=(1.75, 1.53))
    P.hull(hullp & slant, a, b, tone=0.92, big=(7.0, 4.6), small=(1.75, 1.53))
    P.hull(Lk & side, a, y, tone=0.78, big=(7.0, 4.6), small=(1.75, 1.53))

    # ------------------------------------------------------------------ BOW section (front)
    deck = Fr & up & (y > 14.5) & (z < 49.2)                                   # main deck, y=15
    P.paint_team(deck & (xa > 9.9) & (xa < 13.2) & (z > 12) & (z < 46.5))
    P.paint_slate(deck & (xa < 6.5) & (z > 28.5) & (z < 37.5) & (((z + 0.2) % 2.25) < 1.3))
    sh = Fr & up & (xa > 15.2) & (z < 49)                                      # sloped shoulders
    P.paint_team(sh & (z > 24.5) & (z < 36.5) & (xa > 18) & (xa < 24))
    prong = Fr & up & (xa < 10.2) & (z > 49.2)                                 # centre prong deck (unique: hull number)
    P.paint_team(prong & (xa > 6.3) & (xa < 9.3) & (z > 50.5) & (z < 80))
    h = 4.6; x0 = 55.5; w = text_w(HULL_NO, h)
    plate = prong & (z > x0 - 1.3) & (z < x0 + w + 1.3) & (xa < h / 2 + 1.1) & ~P.lock
    P.alb[plate] = LIGHT * (1 - 0.5 * (1 - smooth(0.04, 0.1, np.minimum(np.minimum(z - (x0 - 1.3), x0 + w + 1.3 - z), h / 2 + 1.1 - xa)[plate])))[:, None]; P.seam[plate] = 1e9; P.team[plate] = 0
    P.paint_slate(prong & stencil(HULL_NO, z, x, x0, -h / 2, h))
    P.lamp(prong & (xa > 9.45) & (xa < 9.95) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.22))
    # hangar mouths: front wall between the prong and the outer arms
    wall = Fr & fwd & (z > 47) & (z < 50)
    mouth = wall & (xa > 10.4) & (xa < 23.0) & (y > -6.6) & (y < 10.6)
    P.dark(mouth, MECH * 0.55)
    deep = mouth & (xa > 11.3) & (xa < 22.1) & (y > -5.7) & (y < 9.7)
    g = np.minimum(np.abs(((xa - 11.3) % 2.7) - 1.35), np.abs(((y + 5.7) % 2.2) - 1.1))
    P.alb[deep] = AMBER * (0.30 + 0.25 * smooth(0.05, 0.2, g[deep]))[:, None]; P.emit[deep] = 0.55; P.glow[deep] = 0.35
    P.lamp(deep & (np.abs(y - 8.9) < 0.22) & (np.abs(((xa - 11.3) % 1.8) - 0.9) < 0.5), AMBER); P.lamp(deep & (np.abs(y + 4.9) < 0.2) & (np.abs(((xa - 11.3) % 1.8) - 0.9) < 0.3), WINC)
    fr_ = wall & ~mouth & (xa > 9.5) & (xa < 23.9) & (y > -7.5) & (y < 11.5); P.hazard(fr_, xa, y, 0.6)
    P.paint_team(wall & (xa < 9.0) & (y > 10.6) & (y < 13.6))
    P.windows(wall & (xa < 9.5), xa, y, 1.53, 0.7, 21, key=pk)
    # prong walls facing the bays, outer arms, cross struts
    pw = Fr & side & (z > 49.5) & (np.abs(xa - 10) < 0.6)
    P.lamp(pw & (np.abs(y - 1.9) < 0.2) & (np.abs(((z + 1.5) % 3.0) - 1.5) < 0.55), AMBER, glow=0.6)
    P.hazard(pw & (z < 51.4) & (y > -6.6) & (y < 10.6), z, y, 0.6); P.paint_team(pw & (y > 10.3) & (y < 11.6) & (z > 52))
    P.windows(pw & (y > 4), a, y, 1.53, 0.8, 22)
    arm = Fr & (xa > 22.5) & (z > 49.5)
    P.paint_team(arm & side & (np.abs(y - 2) < 1.3) & (z > 52) & (z < 78) & outb); P.hazard(arm & side & (z > 78.6), z, y, 0.55)
    P.lamp(arm & side & inb & (np.abs(y - 1.9) < 0.2) & (np.abs(((z + 1.5) % 3.0) - 1.5) < 0.55), AMBER, glow=0.6)
    tip = Fr & fwd & (z > 85); P.dark(tip & (xa < 8.5) & (y > -5.5) & (y < 7.5), SLATE * 0.7)
    P.lamp(tip & (xa < 7.5) & (np.abs(((y + 0.3) % 2.6) - 1.3) < 0.2) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.42), WINC)
    # bow side walls
    fs = Fr & side & (z < 49.5) & ~rear & ~fwd
    P.paint_team(fs & (np.abs(y - 2.0) < 1.1)); P.windows(fs, a, y, 1.53, 0.7, 23)
    P.mech(Fr & rear & (z < 10), xa, y, rib=1.6)

    # ------------------------------------------------------------------ NECK (link)
    P.mech(Lk & side & (xa < 6), z, y, rib=1.55, pipes=True); P.team[Lk & side & (xa < 6) & ((np.abs(y - 16.2) < 0.6) | (np.abs(y + 11.2) < 0.6))] = 1.0
    st = Lk & up & (xa > 15); P.paint_team(st & (dcv > 1.6))
    P.lamp(Lk & side & (xa < 6) & (np.abs(y - 2.6) < 0.2) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.25), WINC)
    P.windows(Lk & side & (xa > 15), a, y, 1.53, 0.5, 31)

    # ------------------------------------------------------------------ SPINE (back)
    sd = Bk & up & (y > 21.5) & (y < 22.3)                                     # high deck, y=22
    P.paint_team(sd & (xa > 7.4) & (xa < 12.0) & (z > -40) & (z < -15.5))
    dd = np.hypot(x, z + 27.4); P.dark(sd & (dd < 8.2), MECH); P.team[sd & (dd >= 8.2) & (dd < 9.0)] = 1.0
    tk = sd & (dd > 6.9) & (dd < 8.2) & (np.abs(((np.degrees(np.arctan2(z + 27.4, x)) + 7.5) % 15) - 7.5) < 2.5); P.alb[tk] = LIGHT * 0.8
    dome = Bk & (y > 22.35); P.alb[dome] = LIGHT * 0.95; P.noedge |= dome; P.seam[dome] = 1e9; P.team[dome] = 0
    P.lamp(dome & (y > 24.6), WINC); P.team[dome & (y > 23.0) & (y < 23.7)] = 1.0
    ramp = Bk & slant & (nrm[:, 1] > 0.5) & (z < -40) & (z > -58)              # slope down to the aft deck
    P.hazard(ramp & (xa > 10.6) & (xa < 12.2), z, y, 0.6)
    ad = Bk & up & (y < 14) & (z < -56)                                         # aft deck y=13 and tail y=11
    P.paint_team(ad & (xa > 8.2) & (xa < 11.6) & (z > -79.5) & (z < -58.5))
    P.paint_slate(ad & (xa < 5.5) & (z > -66) & (z < -60) & (((z + 0.1) % 1.5) < 0.9))
    P.paint_team(ad & (z < -82.5) & (xa > 2.2) & (xa < 9.0) & (z > -90.5))
    for zc, r0 in ((44.5, 3.5), (-70.0, 3.5)):                                 # turret rings on the centreline
        dt = np.hypot(x, z - zc); tm = (Fr | Bk) & up & (dt < r0 + 0.75); P.dark(tm & (dt < r0), MECH); P.team[tm & (dt >= r0)] = 1.0; P.lock[tm & (dt >= r0)] = True
    dt = np.hypot(xa - 6.0, z - 22.0); tm = Fr & up & (dt < 4.25); P.dark(tm & (dt < 3.5), MECH); P.team[tm & (dt >= 3.5)] = 1.0; P.lock[tm & (dt >= 3.5)] = True
    bs = Bk & side & ~rear & ~fwd & (xa > 10)
    P.paint_team(bs & (y > 17.6) & (y < 19.6)); P.windows(bs, a, y, 1.53, 0.75, 41)
    P.lamp(bs & (np.abs(y - 20.9) < 0.2) & (np.abs(((z + 2.5) % 5.0) - 2.5) < 0.22))
    # engines
    eng = Bk & rear & (z < -91); P.nozzles(eng, xa - 0.2, y + 8.4, cell=5.6, rad=2.15)
    P.dark(eng & ((dcv < 0.7) | (xa > 10.4)), MECH * 0.9); P.emit[eng & (dcv < 0.7)] = 0; P.glow[eng & (dcv < 0.7)] = 0
    ring = Bk & rear & (z > -91); P.mech(ring, xa, y, rib=1.3, pipes=False)
    P.lamp(ring & (np.abs(xa - 12.0) < 0.3) & (np.abs(((y + 1.5) % 3.0) - 1.5) < 0.3), ENGINE, glow=0.7)
    P.mech(Bk & fwd & (z > -15), xa, y, rib=1.6)
    tail = Bk & side & ~rear & (z < -81.2); P.hull(tail, a, y, tone=0.8, big=(5.5, 4.6), small=(1.83, 1.53)); P.paint_team(tail & (np.abs(y - 3) < 1.0))
    P.hazard(tail & (z < -90.4), z, y, 0.5)

    # ------------------------------------------------------------------ PODS
    pt = Pod & (nrm[:, 1] > 0.8)                                               # sloped pod tops
    ribs = [(-20.5, -14.5), (-34.5, -27.8), (-48.5, -41.5)]
    onrib = np.zeros(n, bool)
    for lo, hi in ribs: onrib |= (z > lo) & (z < hi)
    hi_top = pt & onrib & (y > 11.5) & (xa > 21.5); P.paint_team(hi_top & (dcv > 0.55) & (xa > 26) & (xa < 40))
    nose = pt & (z > -14.2) & (xa > 21.5); P.paint_team(nose & (z > -12.6) & (z < -10.4) & (xa > 24) & (xa < 41))
    P.paint_slate(nose & (z > -2.6) & (z < 5.6) & (xa > 25) & (xa < 39) & (((xa + 0.3) % 2.17) < 1.25))
    tailtop = pt & (z < -60.2); P.paint_team(tailtop & (dcv > 1.5) & (z > -80))
    aft = pt & (z > -60) & (z < -48.8) & (xa > 21.5); P.paint_team(aft & (xa > 24) & (xa < 41) & (z > -58.5) & (z < -56.2))
    P.lamp(pt & (xa > 42.2) & (dcv > 0.2) & (dcv < 0.8) & (np.abs(((z + 3.5) % 7.0) - 3.5) < 0.24) & (z > -60))
    ow = Pod & side & outb & (xa > 42)                                         # outboard walls: torpedo tubes
    P.paint_team(ow & (y > 6.9) & (y < 8.6)); P.windows(ow, a, y, 1.53, 0.7, 51)
    for zc in (-18.1, -31.6, -44.6):
        d = np.hypot(y - 1.5, z - zc); t = ow & (d < 3.0)
        s = (np.degrees(np.arctan2(y - 1.5, z - zc)) % 45) < 22.5
        P.alb[t] = np.where(s[t, None], HAZ_Y, HAZ_K); P.team[t] = 0; P.lock[t] = True
        P.alb[t & (d < 2.15)] = LIGHT * 0.7; P.alb[t & (d < 1.7)] = np.array([0.02, 0.02, 0.03]); P.lamp(t & (d < 0.32), RED)
    iw = Pod & side & inb; P.hull(iw, a, y, tone=0.72, big=(7.0, 4.6), small=(3.5, 1.53)); P.windows(iw, a, y, 1.53, 0.35, 52)
    pn = Pod & slant & (nrm[:, 2] > 0.5) & (z > -8)                             # angled pod noses
    P.paint_team(pn & (np.abs(y - 1.5) < 2.6) & (dcv > 1.6) & (np.abs(a) < 9.5)); P.windows(pn, a, y, 1.53, 0.6, 53)
    P.hazard(pn & (dcv > 0.35) & (dcv < 1.1) & (np.abs(y - 1.5) > 5.2), a, y, 0.6)
    boom = Pod & rear & (z < -70); P.nozzles(boom, a, y + 1.4, cell=4.8, rad=1.75)
    P.dark(boom & (dcv < 0.55), MECH * 0.9); P.emit[boom & (dcv < 0.55)] = 0; P.glow[boom & (dcv < 0.55)] = 0
    pr = Pod & rear & (z > -70) & (xa > 21.2); P.mech(pr & (z < -55), xa, y, rib=1.5)
    P.lamp(pr & (z < -55) & (np.abs(y - 14.6) < 0.25) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.3), ENGINE, glow=0.7)
    bs2 = Pod & side & (z < -60.5) & ~rear; P.paint_team(bs2 & (np.abs(y - 6.8) < 0.9)); 
    P.mech(Pod & (xa < 21.2) & ~up & ~down, a, b, rib=1.3, pipes=False)        # struts joining pods to the spine

    # ------------------------------------------------------------------ belly
    bl = hullp & down; P.team[bl & (P.seam > 0.1) & (xa > 26) & (xa < 29.5) & Pod & (z > -58) & (z < 6)] = 1.0
    P.team[bl & (P.seam > 0.1) & (Fr | Bk) & (xa > 3) & (xa < 6) & ~P.lock] = 1.0

    P.turret(is_('turret'), is_('barrel'))
    return P.finish()
