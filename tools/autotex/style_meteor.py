"""Meteor (anti-fighter frigate): UV plan + paint layout. World axes: +z bow, +y up.
A small ship: 1024 main texture. The rounded fuselage is charted in patches and mirrored across x; the two
missile pods and the two wings are mirror twins; the little gun mounts share texels."""
import numpy as np
from hullkit import *

def _scale(name, c, n):
    if name.startswith(('turret', 'sleeve', 'gbarrel')): return 1.3
    if name.startswith('wing') and n[1] < -0.8: return 0.7
    if n[1] < -0.97: return 0.6
    return 1.0
UVPLAN = dict(mirror={'body': 'x'}, facet_angle={'body': 22, 'shoulderl': 12, 'turret_2': 30, 'turret_5': 30, 'gbarrel_2_1': 40, 'gbarrel_5_1': 40},
              tol={'shoulderl': 0.2, 'body': 0.05}, twin_tol=0.15, planar=['body', 'shoulder', 'wing', 'turret', 'sleeve', 'gbarrel'], scale=_scale, occlusion=True, maxlen=70.0)
RES = 1024

def paint(F):
    P = Painter(F); n = P.n; pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; lp = F['lpos']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x); sx = np.sign(x + 1e-9)
    up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.5; slant = ~up & ~down & ~side
    rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7; outb = nrm[:, 0] * sx > 0.75
    Bd = is_('body'); Sh = is_('shoulder'); Wg = is_('wing'); pk = F['piece'] * 0

    # ------------------------------------------------------------------ FUSELAGE (rounded: panels wrap around it)
    th = np.degrees(np.arctan2(y - 0.4, xa)); arc = np.radians(th) * 8.8
    P.noedge |= Bd
    P.hull(Bd, arc + 40, z, big=(4.6, 7.0), small=(1.53, 1.75), key=pk)
    P.hull(Bd & (th < -35), arc + 40, z, tone=0.66, big=(4.6, 7.0), small=(2.3, 3.5), key=pk)
    P.hull(Bd & (z > 31.6), arc + 40, z, big=(4.6, 3.6), small=(4.6, 1.8), key=pk)         # nose cone: fewer converging seams
    P.paint_team(Bd & (th > 71) & (z > -13) & (z < 21)); P.paint_team(Bd & (th > -25) & (z > 29.4) & (z < 31.6)); P.paint_team(Bd & (th > -25) & (z > -27.6) & (z < -25.8))
    P.paint_slate(Bd & (th > 40) & (th < 66) & (z > -12) & (z < -3) & (((z + 0.2) % 1.75) < 1.0))
    canopy = Bd & (th > 48) & (z > 22.5) & (z < 29); P.dark(canopy, SLATE * 0.55); P.refl[canopy] = 0.45
    P.lamp(canopy & (np.abs(th - 62) < 5) & (np.abs(((z + 0.6) % 1.2) - 0.6) < 0.38), WINC, e=0.9, glow=0.5)
    P.windows(Bd & (th > -18) & (th < 42) & (z > -24) & (z < 28), z, arc + 40, 1.53, 0.55, 11, key=pk, edge=False)
    tip = Bd & (z > 37.2); P.dark(tip, SLATE * 0.6); P.lamp(tip & (z > 40.0), WINC)
    P.lamp(Bd & (np.abs(th + 28) < 1.6) & (np.abs(((z + 3.0) % 6.0) - 3.0) < 0.22) & (z > -24) & (z < 30))
    tail = Bd & (z < -29.5); P.mech(tail & ~rear, arc, z, rib=1.1, pipes=False)
    cap = Bd & rear & (z < -32); d = np.hypot(xa, y + 0.7); P.dark(cap, MECH * 0.8)
    hot = cap & (d < 2.7); P.alb[hot] = ENGINE[None] * (0.6 + 0.4 * np.clip(1 - d[hot] / 2.7, 0, 1))[:, None] + np.array([0.0, 0.2, 0.4])[None] * (np.clip(1 - d[hot] / 2.7, 0, 1) ** 3)[:, None]; P.emit[hot] = 1.0; P.glow[hot] = 1.0
    P.ring(Bd & (th > 55), x, z + 19.1, 3.3, w=0.55, ticks=False)

    # ------------------------------------------------------------------ MISSILE PODS
    P.hull(Sh & up, xa, z, big=(4.0, 5.0), small=(1.33, 1.67), key=pk); P.hull(Sh & down, xa, z, tone=0.62, big=(4.0, 5.0), small=(2.0, 2.5), key=pk)
    P.hull(Sh & ~up & ~down, a, b, tone=0.95, big=(5.0, 3.0), small=(1.67, 1.5))
    st = Sh & up & (y > 4.5); P.paint_team(st & (z > -7.4) & (z < 1.4) & (xa > 8.4) & (xa < 14.4)); P.ring(st, xa - 11.2, z + 12.8, 2.7, w=0.5, ticks=False)
    rack = Sh & fwd & (z > 5.2) & (np.abs(nrm[:, 1]) < 0.3); P.dark(rack, MECH * 0.75)
    fx = ((xa - 9.6) % 1.9) - 0.95; fy = ((y + 1.25) % 1.9) - 0.95; dd = np.hypot(fx, fy)
    P.alb[rack & (dd < 0.78)] = LIGHT * 0.6; P.alb[rack & (dd < 0.6)] = np.array([0.03, 0.03, 0.04]); P.lamp(rack & (dd < 0.25), RED, glow=0.6)
    P.hazard(Sh & slant & (nrm[:, 2] > 0.3) & (z > 1.5), xa, z + y, 0.45)
    ex = Sh & rear & (z < -20.3); P.dark(ex, MECH * 0.8); P.lamp(ex & (dcv > 0.45), ENGINE, glow=0.9)
    sw = Sh & side & outb & (xa > 16.5); P.paint_team(sw & (np.abs(y - 1.0) < 0.55)); P.lamp(sw & (np.abs(y - 2.3) < 0.16) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.2))
    P.paint_team(Sh & slant & (nrm[:, 1] > 0.5) & (np.abs(nrm[:, 2]) < 0.3) & outb.__or__(nrm[:, 0] * sx > 0.4) & (dcv > 0.45) & (z > -19.5) & (z < -12))

    # ------------------------------------------------------------------ WINGS
    wt = Wg & (nrm[:, 1] > 0.8) & (y < 3.4) & (xa > 18.2); wb = Wg & (nrm[:, 1] < -0.8) & (xa > 18.2)
    P.hull(wt, xa, z, big=(4.0, 6.0), small=(1.33, 2.0), key=pk); P.hull(wb, xa, z, tone=0.62, big=(4.0, 6.0), small=(2.0, 3.0), key=pk)
    P.paint_team(wt & (dcv > 1.3) & (xa > 25.0) & (z < -12) & (z > -31)); P.paint_slate(wt & (xa > 19.2) & (xa < 21.8) & (z > -30) & (z < -6) & (((z + 0.2) % 2.0) < 1.15))
    P.lamp(wt & (xa > 32.9) & (dcv > 0.15) & (dcv < 0.6) & (np.abs(((z + 2.0) % 4.0) - 2.0) < 0.2))
    P.paint_team(wb & (dcv > 1.3) & (xa > 26) & (xa < 30) & (z < -8) & (z > -33))
    le = Wg & (nrm[:, 2] > 0.5) & (np.abs(nrm[:, 1]) < 0.4) & (y < 3.2); P.hazard(le, xa, y * 3, 0.5)
    te = Wg & (nrm[:, 2] < -0.5) & (np.abs(nrm[:, 1]) < 0.4) & (y < 3.2); P.dark(te, MECH); P.lamp(te & (dcv > 0.3) & (np.abs(((xa + 1.0) % 2.0) - 1.0) < 0.5), ENGINE, glow=0.6)
    P.dark(Wg & side & (xa > 33.5), MECH * 1.2)
    fin = Wg & (y > 3.3); fsd = fin & side & (np.abs(nrm[:, 0]) > 0.8)
    P.hull(fsd, z, y, tone=1.0, big=(4.0, 3.0), small=(1.33, 1.5), key=pk, slate=0.0); P.paint_team(fsd & (dcv > 0.6) & (y > 5.6) & (y < 10.4)); P.paint_slate(fsd & (dcv > 0.6) & (y > 4.2) & (y < 5.1))
    P.lamp(fin & (y > 11.6) & (nrm[:, 1] > 0.5), RED); P.hazard(fin & (nrm[:, 2] > 0.5), y, z, 0.45)

    # ------------------------------------------------------------------ GUNS
    P.guns(is_('turret') | is_('sleeve') | is_('gbarrel'), cut=-1)
    return P.finish()
