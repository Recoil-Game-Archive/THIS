"""Stealth Carrier: UV plan + paint layout. Same fleet kit, run dark: charcoal hull, few lit windows, cold
blue drive glow -- it is a cloaked ship.
World axes: +z bow, +y up. The hull is mirrored across x (it is a few tenths off true symmetry, hence tol);
pods, fins and point-defence guns are copies of one another."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith('pd_'): return 1.5
    if name.startswith('pflak'): return 1.25
    if n[1] < -0.97: return 0.6
    return 1.0
UVPLAN = dict(mirror={'hull': 'x'}, mirror_center={'hull': (-0.065, 0, 0)}, tol={'hull': 0.3},
              planar=['hull', 'pod', 'fin', 'pd_', 'pflak'], scale=_scale, occlusion=True, maxlen=125.0)
HULL_NO = 'SC-03'
DARK = np.array([0.30, 0.32, 0.385]); DRIVE = np.array([0.35, 0.72, 1.0]); GLASS = np.array([0.55, 0.85, 1.0])

def paint(F):
    P = Painter(F); P.light = DARK * 1.55; P.slate = np.array([0.11, 0.14, 0.21]); P.edge_gain = 0.55
    n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; lp = F['lpos']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9)
    up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7; outb = nrm[:, 0] * sx > 0.8; inb = nrm[:, 0] * sx < -0.8
    H = is_('hull'); Pod = is_('pod'); Fin = is_('fin'); hullp = H | Pod | Fin
    pk = F['piece'] * 0
    def hull(m, ca, cb, tone=1.0, **kw): P.hull(m, ca, cb, tone=tone, base=DARK, **kw)

    # ------------------------------------------------------------------ base plating
    hull(hullp & up, xa, z, big=(6.0, 8.0), small=(2.0, 2.0), key=pk)
    hull(hullp & down, xa, z, tone=0.7, big=(6.0, 8.0), small=(3.0, 4.0), key=pk)
    hull(hullp & side, a, y, big=(7.0, 4.6), small=(1.75, 1.53))
    hull(hullp & slant, a, b, tone=0.93, big=(7.0, 4.6), small=(1.75, 1.53))

    # ------------------------------------------------------------------ HULL: spine and shoulders
    spine = H & up & (y > 14.2) & (xa < 5.4) & (z < 20.5)
    P.paint_team(spine & (xa > 3.5) & (xa < 4.8) & (z > -50) & (z < 19))
    for zc, r0 in ((-37.5, 4.2), (11.5, 3.0)):
        dt = np.hypot(x, z - zc); tm = spine & (dt < r0 + 0.7); P.dark(tm & (dt < r0), MECH * 0.8); P.team[tm & (dt >= r0)] = 1.0; P.lock[tm & (dt >= r0)] = True
    h = 3.6; P.plate_text(spine, HULL_NO, z, x, -10.0, h, pad=1.0)
    sh = H & up & (xa > 5.2) & (xa < 15.2) & (z < 20.5) & (z > -63.5) & (y > 10.5)        # inner shoulders
    P.paint_team(sh & (xa > 6.0) & (xa < 9.2) & (((z > -58) & (z < -49.5)) | ((z > 8.5) & (z < 18.5))))
    P.paint_slate(sh & (xa > 5.8) & (xa < 9.4) & (z > -44) & (z < 4) & (((z + 0.2) % 2.0) < 1.15))
    lou = H & rear & (xa > 14.5) & (z > -50) & (z < -20) & (y > 4.5)                           # louvre faces: cold-running heat sinks
    P.dark(lou, MECH * 0.6); P.lamp(lou & (dcv > 0.45) & (np.abs(((y + 0.5) % 1.6) - 0.8) < 0.28), DRIVE, e=0.85, glow=0.5)
    osh = H & up & (xa > 15) & (z < 6.5) & (y < 11.8) & (y > 4.5)                               # outer shoulders
    P.paint_team(osh & (z > -61) & (z < -50.5) & (dcv > 0.8)); P.paint_team(osh & (xa > 16.5) & (xa < 24.5) & (z > -15.5) & (z < -10.5))
    wall = H & side & outb & (xa > 25)
    P.paint_team(wall & (y > 2.6) & (y < 4.2)); P.windows(wall, a, y, 1.53, 0.3, 11)
    P.lamp(wall & (np.abs(y + 9.6) < 0.2) & (np.abs(((z + 4.0) % 8.0) - 4.0) < 0.22))
    q = H & slant & (nrm[:, 0] * sx > 0.5) & (np.abs(nrm[:, 2]) > 0.4) & (np.abs(nrm[:, 1]) < 0.3) & (xa > 14.5) & (z < 21)      # angled corner plates
    P.paint_team(q & (np.abs(y - 3.4) < 0.8)); P.windows(q, a, y, 1.53, 0.3, 12)
    # head and neck
    head = H & (z > 52.5)
    P.paint_team(head & (nrm[:, 1] > 0.5) & (z > 61.5) & (z < 66.0) & (dcv > 0.5)); P.paint_team(head & (nrm[:, 1] > 0.5) & (z > 68.0) & (z < 69.6) & (dcv > 0.5))
    arr = head & side & (nrm[:, 2] > 0.5); P.dark(arr & (dcv > 0.9), P.slate * 0.8)
    P.lamp(arr & (dcv > 1.3) & (np.abs(((y + 0.2) % 2.4) - 1.2) < 0.2) & (np.abs(((a + 1.0) % 2.0) - 1.0) < 0.42), GLASS)
    P.windows(head & side & outb, a, y, 1.53, 0.35, 13)
    neck = H & (z > 25.5) & (z < 53.5) & (y > -2.6)
    P.paint_slate(neck & up & (z > 28.5) & (z < 50.5) & (((z + 0.2) % 2.2) < 1.25) & (dcv > 0.9)); P.windows(neck & side, a, y, 1.53, 0.4, 14)
    P.paint_team(neck & side & (np.abs(y - 7.6) < 0.7))
    # under-slung hangar: door, flight deck, lit ceiling
    door = H & fwd & (z > 19) & (z < 21) & (y < -3.5) & (xa < 15.3); P.dark(door, MECH * 0.5)
    deep = door & (xa < 13.3) & (y > -15.8) & (y < -5.2); g = np.minimum(np.abs((xa % 2.6) - 1.3), np.abs(((y + 16) % 2.3) - 1.15))
    P.alb[deep] = GLASS * (0.16 + 0.16 * smooth(0.05, 0.2, g[deep]))[:, None]; P.emit[deep] = 0.5; P.glow[deep] = 0.3
    P.lamp(deep & (np.abs(y + 6.0) < 0.22) & (np.abs((xa % 1.8) - 0.9) < 0.5), GLASS); P.hazard(door & ~deep & (xa < 14.4) & (y > -16.8) & (y < -4.3), xa, y, 0.6)
    deck = H & up & (y < -13.5) & (z > 20); P.dark(deck, DECK * 0.55)
    P.alb[deck & (xa < 0.3) & (((z + 0.5) % 3.0) < 1.8)] = LIGHT * 0.8; P.hazard(deck & (xa > 10.2) & (xa < 11.2), xa, z, 0.55)
    P.lamp(deck & (np.abs(xa - 7.4) < 0.2) & (np.abs(((z + 1.25) % 2.5) - 1.25) < 0.2), GLASS); P.lamp(deck & (z > 40.9) & (xa < 9) & (np.abs((xa % 1.5) - 0.75) < 0.25), RED)
    ceil_ = H & down & (y > -3) & (y < -1) & (z > 25.5) & (z < 53.5); P.lamp(ceil_ & (np.abs(xa - 5.0) < 0.25) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.6), GLASS, glow=0.7)
    pyl = H & (z > 29) & (z < 43) & (y < -2.2) & (y > -15) & (xa > 8.5) & (xa < 11.5) & ~up & ~down; P.mech(pyl, a, y, rib=1.4, pipes=False)
    # drive
    eng = H & rear & (z < -78); P.nozzles(eng, xa, y + 4.5, cell=7.4, rad=2.85, col=DRIVE)
    P.dark(eng & (dcv < 0.6), MECH * 0.8); P.emit[eng & (dcv < 0.6)] = 0; P.glow[eng & (dcv < 0.6)] = 0
    low = H & rear & (z < -69) & (z >= -78) & (nrm[:, 1] < -0.3); P.mech(low, xa, b, rib=1.3, pipes=False)
    P.lamp(low & (dcv > 0.7) & (np.abs(((xa + 1.5) % 3.0) - 1.5) < 0.9) & (np.abs(b) < 0.5), DRIVE, glow=0.7)
    aftq = H & (nrm[:, 2] < -0.5) & (nrm[:, 0] * sx > 0.5) & (xa > 14.5) & (z < -50); P.paint_team(aftq & (np.abs(nrm[:, 1]) < 0.2) & (dcv > 1.6) & (y > 0.5) & (y < 7))

    # ------------------------------------------------------------------ PODS
    ptop = Pod & up & (xa > 39.5) & (xa < 51.3) & (y > 3.5)
    P.paint_team(ptop & (xa > 41.3) & (xa < 49.7) & (z > -30.5) & (z < -14.5))
    P.paint_slate(ptop & (xa > 41.5) & (xa < 49.5) & (z > -3.5) & (z < 3.5) & (((xa + 0.3) % 2.0) < 1.15))
    dt = np.hypot(xa - 45.5, z + 6.8); tm = ptop & (dt < 3.5); P.dark(tm & (dt < 2.8), MECH * 0.8); P.team[tm & (dt >= 2.8)] = 1.0; P.lock[tm & (dt >= 2.8)] = True
    teeth = Pod & (xa > 51.2)
    P.paint_team(teeth & side & outb & (xa > 61) & (dcv > 0.7)); tin = teeth & side & outb & (xa < 59.5)
    P.dark(tin & (dcv > 0.6), P.slate * 0.8); P.lamp(tin & (np.abs(y + 3.5) < 0.22) & (dcv > 1.2) & (np.abs(((z + 1.0) % 2.0) - 1.0) < 0.5), GLASS, e=0.9, glow=0.5)
    P.paint_team(teeth & (nrm[:, 1] > 0.6) & (dcv > 0.7) & (xa > 58.4))
    P.lamp(teeth & up & (xa > 60.6) & (dcv > 0.2) & (dcv < 0.7) & (np.abs(((z + 3.7) % 7.4) - 3.7) < 0.22))
    hull(Pod & side & inb & (xa < 41), a, y, tone=0.75, big=(7.0, 4.6), small=(3.5, 1.53))
    strut = Pod & (xa < 39.8); P.paint_team(strut & up & (z > -37) & (z < -26) & (xa > 28) & (xa < 38) & (np.abs(z + 31.5) < 1.6))
    P.mech(strut & side, a, y, rib=1.2, pipes=False)
    peng = Pod & rear & (z < -53); P.nozzles(peng, xa - 40.3, y + 11.2, cell=8.8, rad=2.7, col=DRIVE)
    P.dark(peng & ((dcv < 0.6) | (xa > 57.6)), MECH * 0.8); P.emit[peng & ((dcv < 0.6) | (xa > 57.6))] = 0; P.glow[peng & ((dcv < 0.6) | (xa > 57.6))] = 0
    pn = Pod & (nrm[:, 2] > 0.15) & (z > 4.5); P.hazard(pn & up & (dcv > 0.3) & (dcv < 0.95), xa, z, 0.55)
    pf = Pod & fwd & (z > 18); P.dark(pf & (dcv > 0.7), P.slate * 0.8); P.lamp(pf & (dcv > 1.2) & (np.abs(((y + 0.5) % 2.2) - 1.1) < 0.2) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.42), GLASS)

    # ------------------------------------------------------------------ FINS
    fs = Fin & side & (np.abs(nrm[:, 0]) > 0.9); P.paint_team(fs & (dcv > 1.1) & (y > 8.5)); P.paint_slate(fs & (dcv > 1.1) & (y > 6.2) & (y < 7.6))
    P.lamp(Fin & up & (dcv > 0.25), RED)

    # ------------------------------------------------------------------ belly
    bl = hullp & down & ~P.lock; P.team[bl & (P.seam > 0.1) & H & (xa > 4) & (xa < 6) & (y < -16)] = 1.0
    P.team[bl & (P.seam > 0.1) & Pod & (np.abs(xa - 47.5) < 1.2)] = 1.0

    # ------------------------------------------------------------------ GUNS
    G = is_('pd_') | is_('pflak'); P.noedge |= G; P.seam[G] = 1e9
    P.alb[G] = DARK * 1.25
    brl = G & (np.char.find(name, 'barrel') >= 0); slv = G & (np.char.find(name, 'sleeve') >= 0); tur = G & ~brl & ~slv
    P.alb[tur] = DARK * 1.1; P.alb[tur & (nrm[:, 1] < -0.2)] = MECH
    P.team[slv & (nrm[:, 1] > 0.6)] = 1.0; P.alb[slv & (nrm[:, 2] < -0.7)] = MECH
    P.alb[brl] = MECH * 1.1; P.refl[brl] = 0.3
    zm = np.array([F['bbox'][nm][1][2] for nm in F['names']])[F['piece']]; z0 = np.array([F['bbox'][nm][0][2] for nm in F['names']])[F['piece']]
    L = zm - z0
    P.alb[brl & (np.abs(((lp[:, 2] - z0) % (L / 4 + 1e-6)) - L / 8) < L * 0.02 + 0.08)] = MECH * 0.55
    P.alb[brl & (lp[:, 2] > zm - L * 0.12)] = DARK * 1.7; P.alb[brl & (lp[:, 2] > zm - L * 0.19) & (lp[:, 2] < zm - L * 0.12)] = HAZ_Y * 0.9
    P.alb[brl & (nrm[:, 2] > 0.9) & (lp[:, 2] > zm - 0.3)] = np.array([0.02, 0.02, 0.03])
    return P.finish()
