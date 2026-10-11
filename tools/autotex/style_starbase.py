"""Starbase paint job: pale hull plating, team-colour bands, lit habitat windows, glowing bays."""
import numpy as np
from bake import ihash, noise3, panels, smooth, band

LIGHT = np.array([0.80, 0.81, 0.84]); MID = np.array([0.60, 0.62, 0.66]); DARK = np.array([0.27, 0.28, 0.31])
GUN = np.array([0.20, 0.21, 0.23]); WARM = np.array([1.0, 0.90, 0.62]); COOL = np.array([0.70, 0.90, 1.0])
BAY = np.array([1.0, 0.72, 0.30]); OFF = np.array([0.10, 0.12, 0.16])

def paint(F):
    n = len(F['pos']); pos = F['pos']; nrm = F['nrm']; y = F['y']; r = F['r']; th = F['theta']
    a, b, dcv, dcc, ao = F['a'], F['b'], F['dcv'], F['dcc'], F['ao']
    name = np.array(F['names'])[F['piece']]
    is_ = lambda pre: np.char.startswith(name, pre)
    up = nrm[:, 1] > 0.9; down = nrm[:, 1] < -0.9; side = np.abs(nrm[:, 1]) < 0.5
    alb = np.tile(LIGHT, (n, 1)); team = np.zeros(n); emit = np.zeros(n); refl = np.full(n, 0.10); glow = np.zeros(n)
    line = np.full(n, 1e9); pj = np.zeros(n)          # panel line distance, per-panel jitter
    fkey = F['facet']

    def setcol(m, c): alb[m] = c
    def windows(m, y0, h, period, width, coord, seed, lit=0.7, yv=None):
        yy = y if yv is None else yv
        i = np.floor(coord / period); f = coord - i * period
        w = m & (np.abs(yy - y0) < h / 2) & (np.abs(f - period / 2) < width / 2) & (dcv > 0.45) & (ihash(i, fkey, seed=seed) < 0.86)
        on = w & (ihash(i, fkey, seed=seed + 7) < lit)
        warm = ihash(i, fkey, seed=seed + 9) < 0.7
        alb[w] = OFF; refl[w] = 0.45; team[w] = 0; line[w] = 1e9
        alb[on] = np.where(warm[on, None], WARM, COOL); emit[on] = 1.0; glow[on] = 1.0
        return w

    # ------------------------------------------------------------------ BODY
    B = is_('body')
    arc = th * 20.6                                    # arc length on the drum, shared by all body side panels
    m = B & side
    d, p = panels(a[m], y[m], 4.2, 3.4, seed=3, key=fkey[m]); line[m] = d; pj[m] = p
    sec = lambda lo, hi: B & (y >= lo) & (y <= hi)
    setcol(sec(6.8, 11.2) & ~up, MID); setcol(sec(-11.9, -6.9), MID)
    setcol(B & up, MID)                                # top cap
    # neck: ribbed dark machinery
    m = sec(-28.2, -11.8) & side
    rib = np.abs(((y[m] + 0.2) % 1.7) - 0.85)
    alb[m] = DARK * (0.75 + 0.5 * smooth(0.15, 0.55, rib))[:, None]; line[m] = 1e9; refl[m] = 0.2
    setcol(sec(-62.7, -51.5), MID)
    m = sec(-81, -62.6); setcol(m, DARK); refl[m] = 0.2
    # team colour bands
    team = np.maximum(team, (B & side) * band(y, -1.5, 1.5))            # drum belt
    team = np.maximum(team, (B & side) * band(y, 20.4, 22.4))           # tower collar
    team = np.maximum(team, (B & side) * band(y, -43.6, -42.4))         # bulb pinstripes
    team = np.maximum(team, (B & side) * band(y, -50.9, -49.7))
    team = np.maximum(team, sec(-81, -62.6) * band(y, -70.0, -66.5))    # spike ring
    team = np.maximum(team, (B & up) * band(r, 7.6, 9.6))               # top cap ring
    team = np.maximum(team, sec(6.8, 11.2) * (~up) * (~side | True) * band(r, 16.6, 18.4) * (nrm[:, 1] > 0.3))  # shoulder ring
    # thin dark keylines either side of the belt
    key = (B & side) & ((np.abs(np.abs(y) - 1.9) < 0.18) | (np.abs(y - 20.0) < 0.15))
    alb[key] = DARK
    # windows: drum, tower, upper bulb cone
    windows(B & side & (r > 19), 4.3, 0.9, 1.7, 0.95, a, 11)
    windows(B & side & (r > 19), -4.3, 0.9, 1.7, 0.95, a, 12)
    windows(B & side & (r > 9.5), 15.4, 0.9, 1.5, 0.8, a, 13)
    windows(B & side & (r > 9.5), 17.6, 0.9, 1.5, 0.8, a, 14, lit=0.5)
    # hangar bays: recessed slot in the lower bulb
    radial = (nrm[:, 0] * pos[:, 0] + nrm[:, 2] * pos[:, 2]) / (r + 1e-6)
    bay = sec(-49.9, -43.6) & ((r < 14) | (np.abs(nrm[:, 1]) > 0.9) | (radial < 0.7))
    back = bay & side & (r < 14)
    setcol(bay, GUN); line[bay] = 1e9; team[bay] = 0
    alb[back] = BAY * (0.75 + 0.25 * smooth(0, 0.5, np.abs(((a[back]) % 1.6) - 0.8)))[:, None]; emit[back] = 0.95; glow[back] = 1.0
    wall = bay & ~back; emit[wall] = 0.35; alb[wall] = BAY * 0.45
    # bottom beacon
    tip = B & down & (y < -80); alb[tip] = COOL; emit[tip] = 1.0; glow[tip] = 1.0

    # ------------------------------------------------------------------ RING
    Rg = is_('ring'); deg = np.degrees(th)
    flat = Rg & (up | down); annulus = flat & (r < 63.3); pad = flat & ~annulus
    # polar plating on the flat faces
    seg = 7.5; ang = (deg % seg); dth = np.minimum(ang, seg - ang) * np.pi / 180 * r
    stag = np.floor(deg / seg).astype(int) % 2
    rl = np.where(stag == 0, np.abs(r - 57.4), np.minimum(np.abs(r - 55.2), np.abs(r - 59.9)))
    line[annulus] = np.minimum(dth, rl)[annulus]; pj[annulus] = ihash(np.floor(deg / seg), np.floor((r - 51.7) / 3), up, seed=5)[annulus]
    setcol(flat & down, MID)
    team = np.maximum(team, (annulus & up) * band(r, 59.6, 62.4))
    team = np.maximum(team, (annulus & down) * band(r, 56.6, 58.2))
    k = annulus & up & (np.abs(r - 59.25) < 0.14); alb[k] = DARK
    # turret pads: framed in team colour, darker deck
    setcol(pad, MID); line[pad] = 1e9
    d, p = panels(a[pad], b[pad], 3.0, 3.0, seed=8, key=fkey[pad]); line[pad] = d; pj[pad] = p
    team = np.maximum(team, (pad & up) * band(dcv, 0.9, 1.9))
    # rim walls: habitat windows outside, plating inside
    wallm = Rg & side
    arcr = th * r
    d, p = panels(arcr[wallm], y[wallm], 4.0, 9.0, seed=6); line[wallm] = d; pj[wallm] = p
    outer = wallm & (r > 62.0) & (nrm[:, 0] * pos[:, 0] + nrm[:, 2] * pos[:, 2] > 0)
    inner = wallm & (r < 53.0)
    windows(outer & (r < 64.5), 1.9, 1.0, 1.9, 1.1, arcr, 21, lit=0.75)
    team = np.maximum(team, (outer & (r < 64.5)) * band(y, -1.6, -0.5))
    windows(inner, 1.2, 0.9, 2.3, 1.0, arcr, 22, lit=0.55)
    setcol(Rg & ~flat & ~side, MID)                    # bevels

    # ------------------------------------------------------------------ SPOKES
    L = is_('link'); phi = np.round((th - np.pi) / (2 * np.pi / 3)) * (2 * np.pi / 3) + np.pi
    along = pos[:, 0] * np.cos(phi) + pos[:, 2] * np.sin(phi); across = -pos[:, 0] * np.sin(phi) + pos[:, 2] * np.cos(phi)
    setcol(L, MID)
    lf = L & (up | down)
    line[lf] = np.minimum(np.abs(((along + 1.0) % 6.0) - 3.0), np.abs(np.abs(across) - 3.9))[lf]; pj[lf] = ihash(np.floor((along + 4.0) / 6.0), phi * 10, seed=4)[lf]
    cond = lf & (np.abs(across) < 1.25)
    alb[cond] = DARK * (0.7 + 0.55 * smooth(0.1, 0.45, np.abs((along[cond] % 1.4) - 0.7)))[:, None]; line[cond] = 1e9; refl[cond] = 0.2
    team = np.maximum(team, (lf & up) * band(np.abs(across), 2.2, 2.9))
    ls = L & side; setcol(ls, DARK); refl[ls] = 0.2
    rib = np.abs((along[ls] % 2.0) - 1.0); alb[ls] = DARK * (0.8 + 0.4 * smooth(0.2, 0.6, rib))[:, None]

    # ------------------------------------------------------------------ TURRETS + BARRELS
    Tt = is_('turret'); Bb = is_('barrel'); lp = F['lpos']
    setcol(Tt, MID)
    top = Tt & (nrm[:, 1] > 0.35)
    team = np.maximum(team, top * smooth(0.25, 0.4, dcv))
    setcol(Tt & (nrm[:, 1] < -0.2), DARK)
    setcol(Bb, GUN); refl[Bb] = 0.3
    zmax = {k: lp[F['piece'] == k][:, 2].max() for k in np.unique(F['piece'][Bb])}
    zm = np.array([zmax.get(k, 0) for k in F['piece']])
    muzzle = Bb & (lp[:, 2] > zm - 1.2); alb[muzzle] = DARK * 1.5
    bandz = Bb & (np.abs((lp[:, 2] % 3.0) - 1.5) < 0.25) & ~muzzle; alb[bandz] = GUN * 0.6
    bore = Bb & (nrm[:, 2] > 0.9) & (lp[:, 2] > zm - 0.3); alb[bore] = np.array([0.03, 0.03, 0.04])

    # ------------------------------------------------------------------ shared finishing
    painted = emit < 0.3
    jit = (pj - 0.5) * 0.09
    alb[painted] *= (1 + jit[painted])[:, None]
    lw = 1 - 0.42 * (1 - smooth(0.06, 0.2, line)); alb[painted] *= lw[painted][:, None]
    hi = (1 - smooth(0.0, 0.42, dcv)) * 0.13; lo = (1 - smooth(0.0, 0.8, dcc)) * 0.30
    alb[painted] = alb[painted] * (1 - lo[painted])[:, None] + hi[painted][:, None]
    grime = 0.5 * noise3(pos, 0.11, 1) + 0.3 * noise3(pos, 0.31, 2) + 0.2 * noise3(pos, 0.9, 3)
    streak = noise3(np.stack([pos[:, 0] * 1.4, pos[:, 1] * 0.12, pos[:, 2] * 1.4], 1), 1.0, 4)
    alb[painted] *= (0.86 + 0.16 * grime + 0.06 * (streak - 0.5) * side)[painted][:, None]
    shade = 0.50 + 0.50 * ao ** 0.9
    alb[painted] *= shade[painted][:, None]
    # team colour areas are fully opaque in the mask: anything less washes the team colour out with hull grey
    team = smooth(0.35, 0.65, team) * (emit < 0.3)
    emit = np.maximum(emit, 0.10)
    return dict(albedo=alb, team=team, emit=emit, refl=refl, glow=glow)
