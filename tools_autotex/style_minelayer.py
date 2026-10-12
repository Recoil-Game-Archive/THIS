"""Ring (minelayer frigate, minelayer.s3o): UV plan + paint layout. World axes: +z bow, +y up.
A small ship: 1024 main texture. The saucer body is mirrored across x (it is ~0.1 off true symmetry);
the two side stubs are copies of each other."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if n[1] < -0.9: return 0.6
    return 1.0
def _unique(name, c, n):                            # the flat top of the saucer carries the hull number
    return name == 'body' and n[1] > 0.97 and 5.5 < c[1] < 6.3
UVPLAN = dict(mirror={'body': 'x'}, tol={'body': 0.3}, planar=['body', 'lwing', 'rwing'], scale=_scale, unique=_unique, occlusion=True, maxlen=70.0)
HULL_NO = 'ML-04'

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9); r = np.hypot(x, z)
    up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7
    Bd = is_('body'); Wg = is_('lwing') | is_('rwing'); pk = F['piece'] * 0
    P.noedge |= Bd | Wg                                  # the model is smooth-shaded: no drawn facet edges
    th = np.degrees(np.arctan2(z, xa)); arc = np.radians(th) * 17.0     # polar layout on the saucer
    disc = r < 24.6

    # ------------------------------------------------------------------ base plating
    P.hull(Bd & up, arc + 60, r, big=(6.68, 4.4), small=(2.225, 2.2), key=pk)
    P.hull(Bd & down, xa, z, tone=0.6, big=(6.0, 8.0), small=(3.0, 4.0), key=pk)
    P.hull(Bd & side, a, y, big=(6.0, 4.6), small=(1.5, 1.53)); P.hull(Bd & slant, arc + 60, b, tone=0.93, big=(6.68, 4.6), small=(2.225, 1.53), key=F['facet'] * 0 + (nrm[:, 1] > 0))
    blocks = Bd & ~disc                                  # nose block, engine blocks: straight plating
    P.hull(blocks & up, xa, z, big=(5.0, 6.0), small=(1.67, 2.0), key=pk); P.hull(blocks & slant, a, b, tone=0.93, big=(5.0, 4.6), small=(1.67, 1.53))

    # ------------------------------------------------------------------ SAUCER TOP
    top = Bd & up & disc & (y > 8.5)
    well = Bd & disc & (r < 10.4) & (nrm[:, 1] > 0.5); P.dark(well, SLATE * 0.6); P.refl[well] = 0.3
    P.alb[well & (np.abs((r % 2.4) - 1.2) < 0.12)] = MECH * 0.7; P.alb[well & (np.abs(((np.degrees(np.arctan2(z, x)) + 15) % 30) - 15) < 1.4) & (r > 2.4)] = MECH * 0.7
    P.lamp(well & (r < 1.3), WINC)
    lip = Bd & disc & (r >= 10.4) & (r < 12.9) & (nrm[:, 1] > 0.3); P.team[lip & (r > 11.3)] = 1.0; P.lock[lip & (r > 11.3)] = True
    for ang in (45, 135, 225, 315): P.lamp(Bd & (np.hypot(x - 11.9 * np.cos(np.radians(ang)), z - 11.9 * np.sin(np.radians(ang))) < 0.75) & (nrm[:, 1] > 0.3), AMBER)
    P.paint_team(top & (r > 13.8) & (r < 18.2) & (np.abs(th) < 26)); P.paint_slate(top & (r > 14.2) & (r < 17.8) & (np.abs(th + 52) < 13) & (((arc + 60.3) % 2.225) < 1.25))
    P.plate_text(top, HULL_NO, x, -(z - 16.3), -text_w(HULL_NO, 2.9) / 2, 2.9, pad=0.9)
    rimt = Bd & disc & slant & (nrm[:, 1] > 0.3) & (r > 17.5)                # bevel round the top
    P.paint_team(rimt & (np.abs(th) < 33.5)); P.lamp(rimt & (np.abs(((th + 5.625) % 11.25) - 5.625) * np.pi / 180 * r < 0.22) & (np.abs(r - 22.6) < 0.3) & (np.abs(th) > 36))
    wall = Bd & side & disc & (r > 22.5)
    P.windows(wall, arc + 60, y + 0.1, 1.53, 0.8, 11, key=pk, edge=False); P.paint_team(wall & (y > 1.3) & (y < 2.1))

    # ------------------------------------------------------------------ NOSE (missile launcher)
    nose = Bd & (z > 18.5) & ~disc.__and__(z < 22)
    canopy = nose & (nrm[:, 1] > 0.5) & (xa < 4.2) & (z > 22.5); P.dark(canopy, SLATE * 0.55); P.refl[canopy] = 0.45
    P.lamp(canopy & (xa > 1.6) & (xa < 2.5) & (np.abs(((z + 0.6) % 1.2) - 0.6) < 0.36) & (z < 33.5), WINC, e=0.9, glow=0.5)
    P.hazard(nose & (nrm[:, 1] > 0.5) & (xa >= 4.2) & (xa < 5.0) & (z > 22.5), z, xa, 0.5)
    rack = nose & fwd & (xa > 6.6) & (xa < 12.6) & (z > 26.5); P.dark(rack, MECH * 0.75)
    fx = ((xa - 7.2) % 1.75) - 0.875; fy = ((y - 0.3) % 1.75) - 0.875; dd = np.hypot(fx, fy)
    P.alb[rack & (dd < 0.72)] = LIGHT * 0.6; P.alb[rack & (dd < 0.55)] = np.array([0.03, 0.03, 0.04]); P.lamp(rack & (dd < 0.23), RED, glow=0.6)
    P.paint_team(nose & up & (xa > 7.6) & (xa < 12.2) & (z > 21.5) & (z < 26.2)); P.dark(nose & fwd & (xa < 4.6) & (z > 33.5), SLATE * 0.7); P.lamp(nose & fwd & (xa < 0.5) & (z > 34.5) & (np.abs(y - 2.5) < 0.6), RED)
    P.windows(nose & side & (xa > 6.5), a, y, 1.53, 0.6, 12, edge=False)

    # ------------------------------------------------------------------ ENGINES + SPOILER
    eng = Bd & rear & (z < -24.4) & (xa > 4.6) & (y < 5.6); P.dark(eng, MECH * 0.8)
    ex = (xa - 9.5) / 3.6; ey = (y - 3.0) / 1.5; hot = eng & (np.abs(ex) < 1) & (np.abs(ey) < 1)
    core = np.clip(1 - np.maximum(np.abs(ex), np.abs(ey)), 0, 1)
    P.alb[hot] = ENGINE[None] * (0.6 + 0.4 * core[hot])[:, None] + np.array([0.0, 0.2, 0.4])[None] * (core[hot] ** 2)[:, None]; P.emit[hot] = 1.0; P.glow[hot] = 1.0
    P.mech(Bd & rear & (z < -23) & (xa <= 4.6) & (y < 5.6), xa, y, rib=1.1, pipes=False)
    eb = Bd & (z < -19.5) & ~rear & (y < 5.6) & ~disc; P.hull(eb & side, a, y, tone=0.8, big=(4.0, 4.6), small=(1.33, 1.53)); P.hazard(eb & side & (z < -25.0), z, y, 0.45)
    sp = Bd & (y > 9.4) & (z < -17); spt = sp & (nrm[:, 1] > 0.5) & (y > 11.2)
    P.paint_team(spt & (xa < 11.5) & (xa > 0.9)); P.hazard(spt & (xa >= 11.5), xa, z, 0.45); P.dark(sp & ~spt & (y < 11.3), MECH * 1.1)
    P.lamp(sp & (xa > 12.6) & (y > 11.2) & (nrm[:, 1] > 0.3) & (z < -24), RED)

    # ------------------------------------------------------------------ BELLY: mine bays
    bel = Bd & down & disc
    bay = bel & (np.abs(xa - 10.0) < 3.4) & (np.abs(z) < 5.2); P.dark(bay, MECH * 0.6)
    P.hazard(bay & ((np.abs(xa - 10.0) > 2.7) | (np.abs(z) > 4.5)), xa, z, 0.5); P.alb[bay & (np.abs(xa - 10.0) < 0.12)] = LIGHT * 0.5
    P.lamp(bay & (np.abs(np.abs(z) - 3.6) < 0.25) & (np.abs(((xa - 10.0 + 0.8) % 1.6) - 0.8) < 0.3) & (np.abs(xa - 10.0) < 2.4), AMBER)
    P.team[bel & ~P.lock & (P.seam > 0.1) & (np.abs(r - 19.5) < 0.9)] = 1.0

    # ------------------------------------------------------------------ SIDE STUBS
    P.hull(Wg & (nrm[:, 1] > 0.5), xa, z, big=(4.0, 4.0), small=(1.33, 2.0), key=pk, slate=0.0); P.hull(Wg & down, xa, z, tone=0.6, big=(4.0, 4.0), small=(2.0, 2.0), key=pk)
    P.hull(Wg & side, a, y, tone=0.9, big=(4.0, 4.6), small=(1.33, 1.53))
    wt = Wg & (nrm[:, 1] > 0.5); P.paint_team(wt & (xa > 25.5) & (xa < 31.2) & (np.abs(z) < 4.2)); P.hazard(wt & (xa >= 31.6), z, xa, 0.45)
    P.lamp(Wg & side & (xa > 32.2) & (np.abs(z) < 0.5) & (np.abs(y - 3.2) < 0.5), RED); P.lamp(Wg & side & (nrm[:, 2] < -0.7) & (np.abs(y - 3.0) < 0.6) & (xa > 25) & (xa < 30), ENGINE, glow=0.6)
    return P.finish()
