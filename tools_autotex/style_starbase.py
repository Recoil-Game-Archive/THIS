"""Starbase, second pass: late-80s/90s pre-rendered space-station look -- mid-grey hull broken into a dense
grid of toned panels, slate stencil lettering, big painted blocks (team colour), rows of tiny lit windows,
red running lights, hazard striping around the hangar bays and turret pads.
Also carries the UV plan used by unwrap2.py."""
import numpy as np
from bake import ihash, noise3, panels, smooth, band

# ----------------------------------------------------------------------------- UV plan
def _scale(name, c, n):
    if name.startswith('turret'): return 1.5
    if name.startswith('barrel'): return 1.3
    if n[1] < -0.97: return 0.6                     # flat undersides
    if name == 'link' and abs(n[1]) < 0.5: return 0.7
    if name == 'body' and (-28.2 < c[1] < -11.8 or c[1] < -62.6): return 0.75
    return 1.0
UVPLAN = dict(sym={'body': 2, 'ring': 3, 'link': 3}, unbend={'ring': 60.0}, planar=['body', 'ring', 'link'], scale=_scale)
GLOW_SIGMA = 0.16; GLOW_GAIN = 1.0

# ----------------------------------------------------------------------------- palette
BASE = np.array([0.55, 0.57, 0.62]); LIGHT = np.array([0.74, 0.75, 0.79]); SLATE = np.array([0.25, 0.31, 0.42])
MECH = np.array([0.18, 0.19, 0.22]); DECK = np.array([0.38, 0.40, 0.45]); HAZ_Y = np.array([0.93, 0.71, 0.10]); HAZ_K = np.array([0.06, 0.06, 0.07])
WIN = np.array([1.0, 0.97, 0.86]); WINC = np.array([0.74, 0.91, 1.0]); RED = np.array([1.0, 0.15, 0.10]); AMBER = np.array([1.0, 0.80, 0.45])

FONT = {'S': '01111 10000 10000 01110 00001 00001 11110', 'B': '11110 10001 10001 11110 10001 10001 11110',
        '7': '11111 00001 00010 00100 01000 01000 01000', '0': '01110 10001 10011 10101 11001 10001 01110',
        '1': '00100 01100 00100 00100 00100 00100 01110', '-': '00000 00000 00000 01110 00000 00000 00000',
        'T': '11111 00100 00100 00100 00100 00100 00100', 'H': '10001 10001 10001 11111 10001 10001 10001', 'I': '01110 00100 00100 00100 00100 00100 01110'}
def stencil(text, along, up, x0, y0, h):
    u = h / 7.0; col = np.floor((along - x0) / u).astype(int); row = np.floor((up - y0) / u).astype(int)
    out = np.zeros(len(along), bool); ok = (row >= 0) & (row < 7) & (col >= 0)
    for k, ch in enumerate(text):
        g = np.array([[c == '1' for c in r] for r in FONT[ch].split()])[::-1]
        m = ok & (col >= k * 6) & (col < k * 6 + 5)
        out[m] = g[row[m], col[m] - k * 6]
    return out
def text_w(text, h): return (len(text) * 6 - 1) * h / 7.0

def paint(F):
    n = len(F['pos']); pos = F['pos']; nrm = F['nrm']; y = F['y']; r = F['r']; th = F['theta']
    a, b, dcv, dcc, ao = F['a'], F['b'], F['dcv'], F['dcc'], F['ao']; fkey = F['facet']
    name = np.array(F['names'])[F['piece']]; is_ = lambda pre: np.char.startswith(name, pre)
    up = nrm[:, 1] > 0.9; down = nrm[:, 1] < -0.9; side = np.abs(nrm[:, 1]) < 0.5
    radial = (nrm[:, 0] * pos[:, 0] + nrm[:, 2] * pos[:, 2]) / (r + 1e-6)
    alb = np.tile(BASE, (n, 1)); team = np.zeros(n); emit = np.zeros(n); refl = np.full(n, 0.12); glow = np.zeros(n)
    seam = np.full(n, 1e9); lock = np.zeros(n, bool)       # lock: texel is a light/decal, skip weathering

    def hull(m, ca, cb, tone=1.0, big=(7.0, 4.6), small=(1.75, 1.53), key=None, base=BASE, slate=0.09):
        if not m.any(): return
        k = (fkey if key is None else key)[m]
        d1, h1 = panels(ca[m], cb[m], big[0], big[1], seed=1, key=k, merge=0.45)
        d2, h2 = panels(ca[m], cb[m], small[0], small[1], seed=2, key=k, merge=0.35)
        t1 = (h1 * 7.13) % 1; q2 = (h2 * 13.7) % 1; q3 = (h2 * 29.3) % 1
        c = base[None] * (tone * (1 + 0.22 * (t1 - 0.5) + 0.09 * (h2 - 0.5)))[:, None]
        sl = h1 < slate; c[sl] = SLATE * (1 + 0.14 * (h2[sl] - 0.5))[:, None]
        lt = h1 > 0.91; c[lt] = LIGHT * (tone * (1 + 0.08 * (h2[lt] - 0.5)))[:, None]
        hatch = (q2 < 0.05) & (d2 > 0.16); c[hatch] = MECH * 1.6
        vent = (q3 < 0.04) & (d2 > 0.14) & ~hatch
        c[vent] = MECH[None] * (0.7 + 1.4 * (np.abs(((cb[m][vent]) % 0.26) - 0.13) > 0.065))[:, None]
        c *= (1 - 0.34 * (1 - smooth(0.018, 0.05, d2)))[:, None]
        c *= ((1 - 0.6 * (1 - smooth(0.035, 0.08, d1))) * (0.93 + 0.07 * smooth(0.06, 0.32, d1)))[:, None]
        alb[m] = c; seam[m] = d1

    def windows(m, ca, cb, row_h=1.5, dens=0.5, seed=0, cell=0.56, run=4.4, key=None):
        k = fkey if key is None else key
        jr = np.floor(cb / row_h); fb = cb - jr * row_h
        rid = np.floor(ca / run + ihash(jr, k, seed=seed) * 3)
        ci = np.floor(ca / cell); fa = ca - ci * cell
        w = m & (ihash(jr, k, seed=seed + 1) < dens) & (ihash(rid, jr, k, seed=seed + 2) < 0.55) & (np.abs(fa - cell / 2) < 0.165) & (np.abs(fb - row_h / 2) < 0.105) & (dcv > 0.3) & ~lock
        on = w & (ihash(ci, jr, k, seed=seed + 3) < 0.86); cool = ihash(rid, jr, k, seed=seed + 4) < 0.18
        alb[w] = MECH * 0.6; team[w] = 0; refl[w] = 0.4; lock[w] = True
        alb[on] = np.where(cool[on, None], WINC, WIN); emit[on] = 1.0; glow[on] = 0.55

    def paint_team(m): team[m & (seam > 0.075) & ~lock] = 1.0
    def paint_slate(m): alb[m & ~lock] = SLATE * 0.9; team[m] = 0
    def hazard(m, c1, c2, w=0.62):
        s = ((c1 + c2) / w) % 2 < 1; alb[m] = np.where(s[m, None], HAZ_Y, HAZ_K); team[m] = 0; lock[m] = True; seam[m] = 1e9
    def lamp(m, col=RED, e=1.0): alb[m] = col; emit[m] = e; glow[m] = 1.0; team[m] = 0; lock[m] = True
    def mech(m, ca, cb, rib=1.4, pipes=True):
        if not m.any(): return
        rr = np.abs((cb[m] % rib) - rib / 2); c = MECH[None] * (0.72 + 0.6 * smooth(0.12, 0.42, rr))[:, None]
        if pipes:
            pp = np.abs(((ca[m] + 0.9) % 1.8) - 0.9); pm = pp < 0.3
            c[pm] = (MECH * 2.1)[None] * (0.55 + 0.6 * (1 - (pp[pm] / 0.3) ** 2))[:, None]
        alb[m] = c; refl[m] = 0.22; seam[m] = 1e9

    # =============================================================================== BODY
    B = is_('body'); fc = F['fcen']; o = np.floor((np.arctan2(fc[:, 2], fc[:, 0]) % (2 * np.pi)) / (np.pi / 4) + 1e-6).astype(int) % 8
    even = o % 2 == 0; sec = lambda lo, hi: B & (y >= lo) & (y <= hi)
    cap = B & up & (y > 23.0); slant = B & ~side & ~cap & ~(down & (y < -80))
    # tower
    m = sec(11.1, 23.5) & side
    hull(m, a, y, big=(4.0, 4.1), small=(1.33, 1.37)); paint_team(m & even & (np.abs(a) < 3.1) & (y > 16.6) & (y < 22.3))
    h = 3.6; paint_slate(m & ~even & stencil('7', a, y, -text_w('7', h) / 2, 17.2, h))
    windows(m, a, y, 1.37, 0.75, 31)
    paint_team(m & ~even & (y > 12.0) & (y < 12.8))
    # top cap
    m = cap; pa = th * 8.0
    hull(m, pa, r, tone=0.78, big=(6.283, 5.2), small=(3.1416, 2.6), key=np.zeros(n, int)); paint_team(m & (r > 7.9) & (r < 9.5))
    mm = m & (r < 6.6); alb[mm] = MECH * (0.8 + 0.5 * (np.abs(((np.degrees(th[mm]) + 7.5) % 15) - 7.5) > 2.2))[:, None]; team[mm] = 0
    # shoulder + lower shoulder cones
    m = sec(6.8, 11.2) & slant; hull(m, a, b, tone=0.95, big=(5.0, 3.7), small=(1.67, 1.85)); paint_team(m & ~even & (dcv > 1.1) & (np.abs(a) < 4.2)); windows(m, a, b, 1.85, 0.3, 35)
    m = sec(-11.9, -6.8) & slant; hull(m, a, b, tone=0.72, big=(5.0, 3.0), small=(1.67, 1.5))
    # drum
    m = sec(-6.95, 6.85) & side & (r > 18)
    hull(m, a, y, big=(5.27, 4.5), small=(1.757, 1.5))
    paint_team(m & even & (np.abs(a) < 5.7) & (y > 1.1) & (y < 5.7))
    h = 3.3; paint_slate(m & ~even & stencil('SB-7', a, y, -text_w('SB-7', h) / 2, 1.6, h))
    paint_team(m & ~even & (y > -5.9) & (y < -5.0) & (np.abs(a) < 6.4))
    paint_slate(m & even & (np.abs(a) < 5.7) & (y > -5.6) & (y < -3.4) & (((a + 6) % 2.85) < 1.9))
    windows(m, a, y, 1.5, 0.62, 32)
    tr = m & (np.abs(y) < 0.42); alb[tr] = MECH * (0.8 + 0.5 * (np.abs((a[tr] % 0.5) - 0.25) > 0.1))[:, None]; team[tr] = 0; lock[tr] = True
    lamp(m & (np.abs(y) < 0.2) & (np.abs(((a + 1.317) % 2.635) - 1.317) < 0.2))
    # neck
    m = sec(-28.2, -11.8) & side; mech(m, a, y); team[m & (y > -13.7) & (y < -12.7)] = 1.0; team[m & (y > -27.4) & (y < -26.6)] = 1.0
    # upper bulb cone
    m = sec(-41.85, -28.2) & slant; hull(m, a, b, big=(5.2, 4.7), small=(1.73, 1.57)); paint_team(m & even & (np.abs(a) < 3.6) & (y > -38.5) & (y < -30.5))
    h = 3.0; paint_slate(m & ~even & stencil('07', a, b, -text_w('07', h) / 2, -1.2, h)); windows(m, a, b, 1.57, 0.4, 33)
    # bulb band and hangar bays
    bandm = sec(-51.6, -41.8) & side
    bay = sec(-49.9, -43.6) & ((r < 14) | (np.abs(nrm[:, 1]) > 0.9) | (radial < 0.7))
    m = bandm & ~bay; hull(m, a, y, big=(5.3, 4.85), small=(1.767, 1.62))
    bayf = m & (o % 4 == 2)
    hazard(bayf & (((y > -44.75) & (y < -43.95)) | ((y > -49.35) & (y < -48.55))), a, y)
    lamp(bayf & (np.abs(y + 42.9) < 0.2) & (np.abs(((a + 1.2) % 2.4) - 1.2) < 0.2), WINC)
    oth = m & ~(o % 4 == 2); paint_team(oth & (y > -47.3) & (y < -45.9) & (np.abs(a) < 6.2)); windows(oth, a, y, 1.62, 0.55, 34)
    back = bay & side & (r < 14); wall = bay & ~back
    gridl = np.minimum(np.abs((a % 1.5) - 0.75), np.abs((y % 1.2) - 0.6))
    alb[back] = AMBER * (0.62 + 0.38 * smooth(0.05, 0.16, gridl[back]))[:, None]; emit[back] = 0.92; glow[back] = 0.8; lock[back] = True; team[back] = 0
    alb[wall] = MECH * 1.3; emit[wall] = 0.22; lock[wall] = True; team[wall] = 0; seam[wall] = 1e9
    strip = wall & (np.abs((r % 2.2) - 1.1) < 0.16); alb[strip] = AMBER; emit[strip] = 0.9; glow[strip] = 0.6
    # lower cone, spike, beacon
    m = sec(-62.7, -51.5) & slant; hull(m, a, b, tone=0.8, big=(5.2, 4.0), small=(1.73, 1.33)); paint_team(m & ~even & (np.abs(a) < 2.6) & (y > -60.5) & (y < -54))
    m = sec(-81, -62.6) & ~down; mech(m, a, y, rib=1.8, pipes=False); team[m & (y > -69.2) & (y < -66.8)] = 1.0
    lamp(B & down & (y < -80), RED)

    # =============================================================================== RING
    Rg = is_('ring'); deg = np.degrees(th) % 360; dm = deg % 120; rho = r - 51.7
    key0 = np.zeros(n, int)
    top = Rg & up; bot = Rg & down
    padc = (dm > 49.5) & (dm < 70.5) & (r > 63.25)
    ann = top & ~padc; s = np.radians(dm) * 57.4
    hull(ann, s, rho, big=(7.514, 5.7), small=(1.8785, 1.9), key=key0)
    paint_team(ann & (rho > 5.95) & (rho < 10.9) & (dm > 6.5) & (dm < 39.5))
    paint_team(ann & (rho > 0.5) & (rho < 5.45) & (dm > 80.5) & (dm < 113.5))
    h = 3.4; paint_slate(ann & stencil('SB-7', s, rho, 13.0, 1.15, h)); paint_slate(ann & stencil('07', s, rho, 92.0, 6.75, h))
    paint_slate(ann & (rho > 6.6) & (rho < 10.2) & (dm > 104) & (dm < 113) & (((s + 0.4) % 1.5) < 0.9))
    windows(ann, s, rho, 1.9, 0.4, 41, key=key0)
    lamp(ann & (rho > 10.5) & (rho < 11.05) & (np.abs(((dm + 3.75) % 7.5) - 3.75) * np.pi / 180 * r < 0.26))
    # turret pads
    pad = top & padc
    hull(pad, pos[:, 0], pos[:, 2], tone=0.74, big=(3.2, 3.2), small=(1.6, 1.6), key=key0, slate=0.0)
    hazard(pad & (dcv > 0.3) & (dcv < 1.15), pos[:, 0], pos[:, 2]); team[pad & (dcv > 1.5) & (dcv < 2.3)] = 1.0
    dxp = r * np.cos(np.radians(dm - 60)) - 60.5; dzp = r * np.sin(np.radians(dm - 60)); dt = np.hypot(dxp, dzp)
    tb = top & (dt < 7.3)
    alb[tb & (dt < 6.3)] = MECH; team[tb & (dt < 6.3)] = 0; team[tb & (dt >= 6.3) & (dt < 7.0)] = 1.0; lock[tb & (dt < 6.3)] = True
    tick = tb & (dt > 5.2) & (dt < 6.3) & (np.abs(((np.degrees(np.arctan2(dzp, dxp)) + 7.5) % 15) - 7.5) < 2.5); alb[tick] = LIGHT * 0.8
    # underside
    hull(bot, s, rho, tone=0.62, big=(7.514, 5.7), small=(3.757, 2.85), key=key0); team[bot & (rho > 4.9) & (rho < 6.5) & (r < 63.2) & (seam > 0.1)] = 1.0
    # outer wall, pad walls
    wallm = Rg & side; outer = wallm & (r > 62.0); so = np.radians(dm) * 63.1
    ow = outer & (radial > 0.96) & (r < 64.0)
    hull(ow, so, y, big=(8.26, 3.45), small=(2.065, 1.15), key=key0); windows(ow, so, y + 0.15, 1.15, 0.85, 42, key=key0)
    paint_team(ow & (y > -2.45) & (y < -1.7)); lamp(ow & (np.abs(y - 3.55) < 0.2) & (np.abs(((dm + 7.5) % 15) - 7.5) * np.pi / 180 * r < 0.2))
    pw = outer & ~ow; hull(pw, a, y, tone=0.9, big=(4.0, 2.4), small=(1.33, 1.2)); hazard(pw & (y > 3.15) & (y < 3.85), a, y, 0.5); windows(pw, a, y, 1.2, 0.5, 43)
    paint_team(pw & (y > 0.3) & (y < 1.0))
    # inner wall and bevels
    iw = wallm & (r < 62.0); si = np.radians(dm) * 51.7
    hull(iw, si, y, tone=0.84, big=(6.77, 3.3), small=(1.69, 1.1), key=key0); windows(iw, si, y, 1.1, 0.5, 44, key=key0)
    bev = Rg & ~up & ~down & ~side; hull(bev, np.radians(dm) * r, b, tone=0.7, big=(7.5, 4.0), small=(1.875, 2.0), key=fkey)

    # =============================================================================== SPOKES
    L = is_('link'); phi = np.round((th - np.pi) / (2 * np.pi / 3)) * (2 * np.pi / 3) + np.pi
    al = pos[:, 0] * np.cos(phi) + pos[:, 2] * np.sin(phi); ac = -pos[:, 0] * np.sin(phi) + pos[:, 2] * np.cos(phi); aac = np.abs(ac)
    lt = L & up; lb = L & down; ls = L & side
    hull(lt, al, ac + 20, tone=0.98, big=(6.8, 3.2), small=(1.7, 1.6), key=key0)
    tren = lt & (aac < 1.05); alb[tren] = MECH[None] * (0.7 + 0.7 * smooth(0.1, 0.3, np.abs((al[tren] % 0.9) - 0.45)))[:, None]; lock[tren] = True; seam[tren] = 1e9
    rail = lt & (aac > 1.05) & (aac < 1.3); alb[rail] = LIGHT * 0.9
    paint_team(lt & (aac > 1.75) & (aac < 4.1) & (((al > 23) & (al < 33.2)) | ((al > 40) & (al < 46.8))))
    hazard(lt & (aac > 1.5) & (al > 49.5) & (al < 50.6), al, ac, 0.5); hazard(lt & (aac > 1.5) & (al > 20.6) & (al < 21.6), al, ac, 0.5)
    lamp(lt & (np.abs(aac - 4.3) < 0.2) & (np.abs(((al + 1.7) % 3.4) - 1.7) < 0.2) & (al > 22) & (al < 49))
    windows(lt & (aac > 1.5), al, ac + 20, 1.6, 0.3, 51, key=key0)
    hull(lb, al, ac + 20, tone=0.6, big=(6.8, 3.2), small=(3.4, 1.6), key=key0)
    mech(ls, al, y + 0.7, rib=1.56, pipes=False); stripe = ls & (np.abs(y) < 0.3); alb[stripe] = LIGHT * 0.75
    lamp(ls & (np.abs(y) < 0.16) & (np.abs(((al + 2.0) % 4.0) - 2.0) < 0.18), WINC)

    # =============================================================================== TURRETS + BARRELS
    Tt = is_('turret'); Bb = is_('barrel'); lp = F['lpos']
    T4 = is_('turret_4'); Td = Tt & ~T4
    hull(T4, a, b, tone=1.12, big=(2.6, 1.7), small=(0.87, 0.85), slate=0.0)
    team[T4 & (nrm[:, 1] > 0.35) & (dcv > 0.22)] = 1.0
    alb[Td] = LIGHT * 0.9; seam[Td] = 1e9
    alb[Td & (np.abs(lp[:, 1] + 0.9) < 0.22)] = MECH * 1.3
    team[Td & (lp[:, 1] > 0.1)] = 1.0; team[Td & (lp[:, 1] > 0.1) & (np.abs(lp[:, 1] - 1.15) < 0.12)] = 0; alb[Td & (lp[:, 1] > 0.1)] = SLATE
    und = Tt & (nrm[:, 1] < -0.2); alb[und] = MECH * 1.4
    hazard(is_('turret_4') & side & (lp[:, 1] < -0.6) & (lp[:, 1] > -1.3), a, b, 0.45)
    alb[Bb] = MECH * 1.15; refl[Bb] = 0.3; seam[Bb] = 1e9
    zm = np.array([F['bbox'][nm][1][2] for nm in F['names']])[F['piece']]; z0 = np.array([F['bbox'][nm][0][2] for nm in F['names']])[F['piece']]
    alb[Bb & (np.abs(((lp[:, 2] - z0) % 2.6) - 1.3) < 0.2)] = MECH * 0.6
    alb[Bb & (lp[:, 2] > zm - 1.3)] = LIGHT * 0.62; alb[Bb & (lp[:, 2] > zm - 1.75) & (lp[:, 2] < zm - 1.3)] = HAZ_Y * 0.9
    alb[Bb & (nrm[:, 2] > 0.9) & (lp[:, 2] > zm - 0.3)] = np.array([0.02, 0.02, 0.03])

    # =============================================================================== finishing
    w = ~lock
    hi = (1 - smooth(0.0, 0.2, dcv)) * 0.16 * ~Td; lo = (1 - smooth(0.0, 0.55, dcc)) * 0.35
    alb[w] = alb[w] * (1 - lo[w])[:, None] + hi[w][:, None]
    grime = 0.6 * noise3(pos, 0.13, 1) + 0.4 * noise3(pos, 0.5, 2)
    alb[w] *= (0.93 + 0.11 * grime[w])[:, None]
    shade = 0.42 + 0.58 * ao ** 0.85
    lit = emit > 0.5
    alb[~lit] *= shade[~lit][:, None]
    team[((dcv < 0.07) & ~Td) | lit] = 0                      # keep a crisp hull-coloured edge line, never tint lights
    emit = np.maximum(emit, 0.10)
    return dict(albedo=alb, team=team, emit=emit, refl=refl, glow=glow)
