"""Imperator: tileset texturing (see tiles.py / dice.py). World axes: +z bow, +y up; the hull is 2245 long.
The same fleet plating, at the same scale as every other ship -- there is just a great deal more of it."""
import numpy as np
from bake import ihash

TEX1 = 'imperator.dds'; TEX2 = 'imperator2.dds'
P0 = 0
TILES = ([dict(kind='plate', seed=i) for i in range(16)]                                   # 0-15  plating
         + [dict(kind='plate', seed=20 + i, tone=0.66) for i in range(8)]                  # 16-23 shaded plating (undersides, crevices)
         + [dict(kind='plate', seed=40 + i, windows=0.7) for i in range(8)]                # 24-31 walls with window rows
         + [dict(kind='plate', seed=60 + i, lights=0.18) for i in range(4)]                # 32-35 deck with scattered lights
         + [dict(kind='team', seed=80), dict(kind='team', seed=81), dict(kind='team', seed=82, bars=True), dict(kind='team', seed=83, band=(0.25, 0.75)),
            dict(kind='team', seed=84, windows=0.6), dict(kind='team', seed=85, band=(0.0, 0.5)), dict(kind='team', seed=86, tone=0.66), dict(kind='team', seed=87, tone=0.66)]   # 36-43 team colour
         + [dict(kind='slate', seed=90), dict(kind='slate', seed=91, windows=0.6), dict(kind='slate', seed=92, lights=0.5), dict(kind='plate', seed=93, lamp=True)]              # 44-47
         + [dict(kind='pad_edge', seed=1), dict(kind='pad_corner', seed=2), dict(kind='pad', seed=3), dict(kind='hangar', seed=4)]                                           # 48-51
         + [dict(kind='mech', seed=5), dict(kind='mech', seed=6, strip=(1.0, 0.8, 0.45)), dict(kind='mech', seed=7, strip=(0.74, 0.91, 1.0)), dict(kind='housing', seed=8)]    # 52-55
         + [dict(kind='engine', seed=9, n=4), dict(kind='engine', seed=10, n=2), dict(kind='plate', seed=11, tone=0.66, lights=0.15), dict(kind='plate', seed=12, tone=0.66, windows=0.5)]  # 56-59
         + [dict(kind='plate', seed=100 + i) for i in range(4)])                           # 60-63 more plating
PLATE = list(range(16)) + [60, 61, 62, 63]; SHADE = list(range(16, 24)); WALL = list(range(24, 32)); LIGHTS = [32, 33, 34, 35]
HP = [(241.2, 1240.0), (377.8, 1167.6), (265.3, 731.6), (538.6, 601.1), (0.0, 450.4), (88.4, 152.9), (321.5, -66.2), (321.5, -452.1), (782.1, -251.1)]   # hardpoints (|x|, z)
S = 40.0

def _h(*k):
    return float(ihash(*[np.array([int(x)]) for x in k], seed=3)[0])

def tile_for(piece, c, n, ax, iu, iv, ao):
    x, y, z = c; xa = abs(x); h = _h(iu, iv, ax, round(float(np.sign(n[ax]))) + 2); pick = lambda L: L[int(h * 997) % len(L)]
    flip = 2 * int(_h(iv, iu, 7) < 0.5)                                              # half the plain tiles turned 180: less repetition
    if piece == 'tower':
        if ax == 1: return (36 if n[1] > 0 else pick(SHADE)), 0
        if y > 150 and _h(iu, iv, 5) < 0.5: return 40, 0
        return (pick(WALL) if h < 0.8 else 45), 0
    if ax == 1:                                                                      # decks (and the mirrored belly)
        top = n[1] > 0
        if top:
            for hx, hz in HP:                                                        # landing-pad markings under each hardpoint
                du = int(np.floor(xa / S)) - int(np.floor(hx / S)); dv = int(np.floor(z / S)) - int(np.floor(hz / S))
                if abs(du) <= 1 and abs(dv) <= 1:
                    if du == 0 and dv == 0: return 50, 0
                    sx = du if x >= 0 or hx < S else -du                          # mirror the pad for the port side
                    if du != 0 and dv != 0: return 49, {(1, 1): 0, (1, -1): 1, (-1, -1): 2, (-1, 1): 3}[(sx, dv)]
                    return 48, {(0, 1): 0, (1, 0): 1, (0, -1): 2, (-1, 0): 3}[(sx, dv)]
        col = int(np.floor(xa / S)); row = int(np.floor(z / S))
        lane = col in (5, 10) and -18 <= row <= 31 and xa > 175                       # twin lanes down each hull
        spine = col == 0 and xa < 175 and -18 <= row <= 5 and not (-9 <= row <= -2)   # centre stripe, broken by the tower
        band = xa > 452 and row in (-8, 4)                                           # cross bands on the outer hulls
        stern = 13 <= col <= 19 and row in (-18, -17)
        if lane or spine or band or stern:
            if not top: return (42 if h < 0.5 else 43), 0
            return (38 if (row % 6 == 0 and lane) else (36 if h < 0.5 else 37)), (1 if (band or stern) else 0)
        if not top: return (58 if h < 0.08 else pick(SHADE) if (h < 0.35 or ao < 0.45) else pick(PLATE)), flip
        if ao < 0.45: return pick(SHADE), flip
        if h < 0.10: return pick(LIGHTS), flip
        if h < 0.14: return 44, flip
        if h < 0.17: return 47, flip
        return pick(PLATE), flip
    # walls
    if ax == 2 and n[2] < 0 and z < -755: return (56 if (xa < 175 or abs(y + 196) < 120) else 57), 0        # engine faces
    if z < -740 and ax != 2 and xa > 120: return (55 if h < 0.7 else 52), 0                                   # engine barrels
    if ax == 2 and n[2] < 0: return (52 if h < 0.6 else 54), 0                                                # stern wall
    waist = abs(y + 198) < 70 and xa > 420 and ax == 0 or (abs(y + 198) < 70 and ax == 2 and z > 1290 and xa > 175)
    if waist: return ((53 if iu % 5 else 54) if iv in (-7, -4) else (59 if h < 0.15 else pick(WALL))), 0
    if xa < 190 and z > 833 and ax == 0:                                                                      # inner walls of the bow fork: hangar slots
        if abs(y + 198) < 22 and int(np.floor(z / S)) % 3 == 0: return 51, 0
        return (pick(WALL) if h < 0.6 else pick(SHADE)), 0
    if ax == 2 and n[2] > 0: return (45 if h < 0.5 else 46), 0                                                 # bow faces: dark sensor arrays
    if ao < 0.4: return (59 if h < 0.4 else pick(SHADE)), 0
    if abs(abs(y + 198) - 90) < 22 and iu % 4 == 0: return 40, 0                                                  # team panels along the rim strips
    return (pick(WALL) if h < 0.6 else pick(PLATE)), 0
