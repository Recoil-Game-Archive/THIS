"""Shared paint kit for the THIS fleet look: mid-grey hull broken into toned panels, slate stencils, painted
team-colour blocks, rows of tiny lit windows, running lights, hazard striping, dark machinery.
A unit's style file builds a Painter, lays these out over its own geometry, and returns painter.finish()."""
import numpy as np
from bake import ihash, noise3, panels, smooth, band

BASE = np.array([0.55, 0.57, 0.62]); LIGHT = np.array([0.74, 0.75, 0.79]); SLATE = np.array([0.25, 0.31, 0.42])
MECH = np.array([0.18, 0.19, 0.22]); DECK = np.array([0.38, 0.40, 0.45]); HAZ_Y = np.array([0.93, 0.71, 0.10]); HAZ_K = np.array([0.06, 0.06, 0.07])
WIN = np.array([1.0, 0.97, 0.86]); WINC = np.array([0.74, 0.91, 1.0]); RED = np.array([1.0, 0.15, 0.10]); AMBER = np.array([1.0, 0.80, 0.45])
ENGINE = np.array([1.0, 0.62, 0.22])
GLOW_SIGMA = 0.16; GLOW_GAIN = 1.0

FONT = {'S': '01111 10000 10000 01110 00001 00001 11110', 'B': '11110 10001 10001 11110 10001 10001 11110',
        'C': '01111 10000 10000 10000 10000 10000 01111', 'V': '10001 10001 10001 10001 01010 01010 00100',
        'F': '11111 10000 10000 11110 10000 10000 10000', 'T': '11111 00100 00100 00100 00100 00100 00100',
        'H': '10001 10001 10001 11111 10001 10001 10001', 'I': '01110 00100 00100 00100 00100 00100 01110',
        '0': '01110 10001 10011 10101 11001 10001 01110', '1': '00100 01100 00100 00100 00100 00100 01110',
        '2': '01110 10001 00001 00110 01000 10000 11111', '3': '11110 00001 00001 01110 00001 00001 11110',
        '4': '10001 10001 10001 11111 00001 00001 00001', '5': '11111 10000 11110 00001 00001 10001 01110',
        '6': '01110 10000 11110 10001 10001 10001 01110', '7': '11111 00001 00010 00100 01000 01000 01000',
        '8': '01110 10001 10001 01110 10001 10001 01110', '9': '01110 10001 10001 01111 00001 00001 01110',
        '-': '00000 00000 00000 01110 00000 00000 00000'}
def stencil(text, along, up, x0, y0, h):
    u = h / 7.0; col = np.floor((along - x0) / u).astype(int); row = np.floor((up - y0) / u).astype(int)
    out = np.zeros(len(along), bool); ok = (row >= 0) & (row < 7) & (col >= 0)
    for k, ch in enumerate(text):
        g = np.array([[c == '1' for c in r] for r in FONT[ch].split()])[::-1]
        m = ok & (col >= k * 6) & (col < k * 6 + 5)
        out[m] = g[row[m], col[m] - k * 6]
    return out
def text_w(text, h): return (len(text) * 6 - 1) * h / 7.0

class Painter:
    def __init__(self, F):
        self.F = F; n = self.n = len(F['pos'])
        self.alb = np.tile(BASE, (n, 1)); self.team = np.zeros(n); self.emit = np.zeros(n); self.refl = np.full(n, 0.12); self.glow = np.zeros(n)
        self.seam = np.full(n, 1e9); self.lock = np.zeros(n, bool)     # lock: texel is a light/decal, skip weathering
        self.noedge = np.zeros(n, bool)                                # small rounded parts: no per-facet edge lines
        self.fkey = F['facet']; self.dcv = F['dcv']

    def hull(self, m, ca, cb, tone=1.0, big=(7.0, 4.6), small=(1.75, 1.53), key=None, base=BASE, slate=0.09):
        if not m.any(): return
        k = (self.fkey if key is None else key)[m]
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
        self.alb[m] = c; self.seam[m] = d1

    def windows(self, m, ca, cb, row_h=1.5, dens=0.5, seed=0, cell=0.56, run=4.4, key=None):
        k = self.fkey if key is None else key
        jr = np.floor(cb / row_h); fb = cb - jr * row_h
        rid = np.floor(ca / run + ihash(jr, k, seed=seed) * 3)
        ci = np.floor(ca / cell); fa = ca - ci * cell
        w = m & (ihash(jr, k, seed=seed + 1) < dens) & (ihash(rid, jr, k, seed=seed + 2) < 0.55) & (np.abs(fa - cell / 2) < 0.165) & (np.abs(fb - row_h / 2) < 0.105) & (self.dcv > 0.3) & ~self.lock
        on = w & (ihash(ci, jr, k, seed=seed + 3) < 0.86); cool = ihash(rid, jr, k, seed=seed + 4) < 0.18
        self.alb[w] = MECH * 0.6; self.team[w] = 0; self.refl[w] = 0.4; self.lock[w] = True
        self.alb[on] = np.where(cool[on, None], WINC, WIN); self.emit[on] = 1.0; self.glow[on] = 0.55

    def paint_team(self, m): self.team[m & (self.seam > 0.075) & ~self.lock] = 1.0
    def paint_slate(self, m): self.alb[m & ~self.lock] = SLATE * 0.9; self.team[m] = 0
    def hazard(self, m, c1, c2, w=0.62):
        s = ((c1 + c2) / w) % 2 < 1; self.alb[m] = np.where(s[m, None], HAZ_Y, HAZ_K); self.team[m] = 0; self.lock[m] = True; self.seam[m] = 1e9
    def lamp(self, m, col=RED, e=1.0, glow=1.0):
        self.alb[m] = col; self.emit[m] = e; self.glow[m] = glow; self.team[m] = 0; self.lock[m] = True
    def dark(self, m, col=MECH):
        self.alb[m] = col; self.team[m] = 0; self.lock[m] = True; self.seam[m] = 1e9; self.refl[m] = 0.22
    def mech(self, m, ca, cb, rib=1.4, pipes=True):
        if not m.any(): return
        rr = np.abs((cb[m] % rib) - rib / 2); c = MECH[None] * (0.72 + 0.6 * smooth(0.12, 0.42, rr))[:, None]
        if pipes:
            pp = np.abs(((ca[m] + 0.9) % 1.8) - 0.9); pm = pp < 0.3
            c[pm] = (MECH * 2.1)[None] * (0.55 + 0.6 * (1 - (pp[pm] / 0.3) ** 2))[:, None]
        self.alb[m] = c; self.refl[m] = 0.22; self.seam[m] = 1e9; self.team[m] = 0
    def nozzles(self, m, ca, cb, cell=5.0, rad=1.7, col=ENGINE):
        """Engine block: dark housing with a grid of glowing exhausts."""
        if not m.any(): return
        fa = (ca % cell) - cell / 2; fb = (cb % cell) - cell / 2; d = np.hypot(fa, fb)
        self.dark(m, MECH * 0.9)
        ring = m & (d < rad * 1.22) & (d >= rad); self.alb[ring] = LIGHT * 0.55
        hot = m & (d < rad); core = np.clip(1 - d / rad, 0, 1)
        self.alb[hot] = col[None] * (0.55 + 0.45 * core[hot])[:, None] + np.array([0.0, 0.25, 0.5])[None] * (core[hot] ** 3)[:, None]
        self.emit[hot] = 1.0; self.glow[hot] = 1.0

    def finish(self):
        F = self.F; dcv, dcc, ao, pos = F['dcv'], F['dcc'], F['ao'], F['pos']; alb = self.alb
        w = ~self.lock
        hi = (1 - smooth(0.0, 0.2, dcv)) * 0.16 * ~self.noedge; lo = (1 - smooth(0.0, 0.55, dcc)) * 0.35
        alb[w] = alb[w] * (1 - lo[w])[:, None] + hi[w][:, None]
        grime = 0.6 * noise3(pos, 0.13, 1) + 0.4 * noise3(pos, 0.5, 2)
        alb[w] *= (0.93 + 0.11 * grime[w])[:, None]
        shade = 0.42 + 0.58 * ao ** 0.85; lit = self.emit > 0.5
        alb[~lit] *= shade[~lit][:, None]
        self.team[((dcv < 0.07) & ~self.noedge) | lit] = 0     # crisp hull-coloured edge line; never tint lights
        return dict(albedo=alb, team=self.team, emit=np.maximum(self.emit, 0.10), refl=self.refl, glow=self.glow)

    def turret(self, Tt, Bb):
        """Standard small dome turret + barrel."""
        F = self.F; lp = F['lpos']; nrm = F['nrm']
        self.alb[Tt] = LIGHT * 0.9; self.seam[Tt] = 1e9; self.noedge |= Tt
        self.alb[Tt & (np.abs(lp[:, 1] + 0.9) < 0.22)] = MECH * 1.3
        top = Tt & (lp[:, 1] > 0.1); self.alb[top] = SLATE; self.team[top] = 1.0; self.team[top & (np.abs(lp[:, 1] - 1.15) < 0.12)] = 0
        self.alb[Tt & (nrm[:, 1] < -0.2)] = MECH * 1.4
        self.alb[Bb] = MECH * 1.15; self.refl[Bb] = 0.3; self.seam[Bb] = 1e9
        zm = np.array([F['bbox'][nm][1][2] for nm in F['names']])[F['piece']]; z0 = np.array([F['bbox'][nm][0][2] for nm in F['names']])[F['piece']]
        self.alb[Bb & (np.abs(((lp[:, 2] - z0) % 2.6) - 1.3) < 0.2)] = MECH * 0.6
        self.alb[Bb & (lp[:, 2] > zm - 1.3)] = LIGHT * 0.62; self.alb[Bb & (lp[:, 2] > zm - 1.75) & (lp[:, 2] < zm - 1.3)] = HAZ_Y * 0.9
        self.alb[Bb & (nrm[:, 2] > 0.9) & (lp[:, 2] > zm - 0.3)] = np.array([0.02, 0.02, 0.03])
