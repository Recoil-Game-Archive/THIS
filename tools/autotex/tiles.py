"""Tileset texturing for hulls too big for a unique texture.

A giant hull cannot get fleet-level sharpness from one unwrapped texture (the Imperator would get ~1.3 texels per
unit against ~14 for a carrier). Instead the texture is a sheet of square plating tiles, each covering TILE
model units, and dice.py cuts every face along a world-space lattice so each cell shows one tile. Sharpness is
then independent of the ship's size. All tiles share one seam layout, so any tile fits against any other.

make_tileset(specs) -> (tex1 RGBA, tex2 RGBA) images; specs is a list of dicts, one per tile, laid out row-major."""
import numpy as np
from PIL import Image
from scipy import ndimage
from bake import ihash, smooth
from hullkit import BASE, LIGHT, SLATE, MECH, DECK, HAZ_Y, HAZ_K, WIN, WINC, RED, AMBER, ENGINE

TILE = 40.0          # model units covered by one tile
GRID = 8             # tiles per row/column of the sheet
CELL = 512           # sheet pixels per tile, including the gutter
GUT = 24             # gutter (wrapped copy of the tile's own edge) so filtering and mipmaps stay inside the tile

def _rows(n_units, n_rows, seed, merge=0.45):
    """Per row, split n_units unit cells into panels 1 or 2 units wide; panels never cross the tile edge."""
    pid = np.zeros((n_rows, n_units), int); lo = np.zeros((n_rows, n_units)); hi = np.zeros((n_rows, n_units))
    for j in range(n_rows):
        i = 0; k = 0
        while i < n_units:
            w = 2 if (i + 1 < n_units and ihash(np.array([i]), np.array([j]), seed=seed)[0] < merge) else 1
            pid[j, i:i + w] = k; lo[j, i:i + w] = i; hi[j, i:i + w] = i + w; i += w; k += 1
    return pid, lo, hi

def _panels(A, B, nu, nr, seed, merge=0.45):
    cw = TILE / nu; ch = TILE / nr; pid, lo, hi = _rows(nu, nr, seed, merge)
    j = np.minimum((B / ch).astype(int), nr - 1); i = np.minimum((A / cw).astype(int), nu - 1)
    d = np.minimum(np.minimum(A - lo[j, i] * cw, hi[j, i] * cw - A), np.minimum(B - j * ch, (j + 1) * ch - B))
    return d, pid[j, i], j

def make_tile(spec, px, layout_seed=11):
    """Returns float arrays (px,px): rgb(3), team, emit, refl for one tile. spec: kind, seed, plus kind options."""
    kind = spec['kind']; seed = spec.get('seed', 0); tone = spec.get('tone', 1.0)
    t = (np.arange(px) + 0.5) / px * TILE; A, B = np.meshgrid(t, t)            # B increases downward here; flipped at the end
    d1, p1, j1 = _panels(A, B, 6, 8, layout_seed); d2, p2, j2 = _panels(A, B, 24, 24, layout_seed + 1, 0.35)
    h1 = ihash(p1, j1, seed=seed * 7 + 1); h2 = ihash(p2, j2, seed=seed * 7 + 2)
    t1 = (h1 * 7.13) % 1; q2 = (h2 * 13.7) % 1; q3 = (h2 * 29.3) % 1
    c = BASE[None, None] * (tone * (1 + 0.22 * (t1 - 0.5) + 0.09 * (h2 - 0.5)))[..., None]
    team = np.zeros((px, px)); emit = np.zeros((px, px)); refl = np.full((px, px), 0.12); lock = np.zeros((px, px), bool)
    plain = kind not in ('mech', 'engine', 'housing', 'pad', 'pad_edge', 'pad_corner', 'hangar')
    if plain:
        sl = h1 < spec.get('slate', 0.06); c[sl] = SLATE * (1 + 0.14 * (h2[sl] - 0.5))[:, None]
        lt = h1 > 0.91; c[lt] = LIGHT * (tone * (1 + 0.08 * (h2[lt] - 0.5)))[:, None]
        hatch = (q2 < 0.018) & (d2 > 0.16); c[hatch] = MECH * 1.6
        vent = (q3 < 0.014) & (d2 > 0.14) & ~hatch; c[vent] = MECH[None] * (0.7 + 1.4 * (np.abs((B[vent] % 0.26) - 0.13) > 0.065))[:, None]
    def seams():
        nonlocal c
        c = c * (1 - 0.34 * (1 - smooth(0.018, 0.05, d2)))[..., None]
        c = c * ((1 - 0.6 * (1 - smooth(0.035, 0.08, d1))) * (0.93 + 0.07 * smooth(0.06, 0.32, d1)))[..., None]
    def lamp(m, col, e=1.0):
        c[m] = col; emit[m] = e; team[m] = 0; lock[m] = True
    def hazard(m, w=0.62):
        s = ((A + B) / w) % 2 < 1; c[m] = np.where(s[m, None], HAZ_Y, HAZ_K); team[m] = 0; lock[m] = True
    def windows(dens, row_h=TILE / 24, cell=0.5556, run=TILE / 9):
        jr = np.floor(B / row_h); fb = B - jr * row_h; rid = np.floor(A / run); ci = np.floor(A / cell); fa = A - ci * cell
        w = (ihash(jr, seed=seed + 31) < dens) & (ihash(rid, jr, seed=seed + 32) < 0.6) & (np.abs(fa - cell / 2) < 0.165) & (np.abs(fb - row_h / 2) < 0.105) & (d1 > 0.25)
        on = w & (ihash(ci, jr, seed=seed + 33) < 0.86); cool = ihash(rid, jr, seed=seed + 34) < 0.18
        c[w] = MECH * 0.6; refl[w] = 0.4; lock[w] = True; team[w] = 0
        c[on] = np.where(cool[on, None], WINC, WIN); emit[on] = 1.0
    if kind == 'plate':
        seams()
        if spec.get('windows'): windows(spec['windows'])
        if spec.get('lights'):
            gi = np.floor(A / (TILE / 6)); gj = np.floor(B / (TILE / 8)); cx = (gi + 0.5) * TILE / 6; cy = (gj + 0.5) * TILE / 8
            m = (np.hypot(A - cx, B - cy) < 0.28) & (ihash(gi, gj, seed=seed + 5) < spec['lights']); lamp(m, WIN if seed % 2 else WINC)
        if spec.get('lamp'): lamp(np.hypot(A - TILE / 2, B - TILE / 2) < 0.42, RED)
    elif kind == 'team':
        seams(); band = spec.get('band')                   # band=(lo,hi) in tile fractions along B: a lane; None: whole tile
        m = (d1 > 0.075) if band is None else ((d1 > 0.075) & (B > band[0] * TILE) & (B < band[1] * TILE))
        if spec.get('bars'):
            bars = (np.abs(B - TILE / 2) < TILE * 0.2) & (((A + 0.3) % (TILE / 12)) < TILE / 21); c[bars] = SLATE * 0.9; m &= ~bars
        team[m] = 1.0
        if spec.get('windows'): windows(spec['windows'])
    elif kind == 'slate':
        seams(); m = d1 > 0.075; c[m] = SLATE[None] * (0.85 + 0.2 * h2[m])[:, None]; refl[m] = 0.2
        if spec.get('windows'): windows(spec['windows'])
        if spec.get('lights'):
            gi = np.floor(A / 1.6); gj = np.floor(B / 2.2); m2 = (np.hypot(A - (gi + 0.5) * 1.6, B - (gj + 0.5) * 2.2) < 0.2) & (ihash(gi, gj, seed=seed + 5) < spec['lights']); lamp(m2, WINC)
    elif kind == 'mech':
        rib = spec.get('rib', TILE / 28); rr = np.abs((B % rib) - rib / 2); c = MECH[None, None] * (0.72 + 0.6 * smooth(0.12, 0.42, rr))[..., None]
        pp = np.abs(((A + TILE / 44) % (TILE / 22)) - TILE / 44); pm = pp < 0.3
        c[pm] = (MECH * 2.1)[None] * (0.55 + 0.6 * (1 - (pp[pm] / 0.3) ** 2))[:, None]; refl[:] = 0.22
        if spec.get('strip'): lamp((np.abs(B - TILE / 2) < 0.3) & (((A + 0.6) % 2.5) < 1.6), spec['strip'], 0.9)
    elif kind in ('engine', 'housing'):
        c[:] = MECH * 0.9; refl[:] = 0.22
        if kind == 'engine':
            n = spec.get('n', 4); cell = TILE / n; fa = (A % cell) - cell / 2; fb = (B % cell) - cell / 2; d = np.hypot(fa, fb); rad = cell * 0.36
            c[(d < rad * 1.2) & (d >= rad)] = LIGHT * 0.55; hot = d < rad; core = np.clip(1 - d / rad, 0, 1)
            c[hot] = ENGINE[None] * (0.55 + 0.45 * core[hot])[:, None] + np.array([0.0, 0.25, 0.5])[None] * (core[hot] ** 3)[:, None]; emit[hot] = 1.0
        else:
            rr = np.abs((B % 1.6) - 0.8); c = c * (0.8 + 0.4 * smooth(0.15, 0.5, rr))[..., None]
    elif kind in ('pad', 'pad_edge', 'pad_corner'):
        c = DECK[None, None] * (0.72 * (1 + 0.1 * (h2 - 0.5)))[..., None]; c = c * (1 - 0.3 * (1 - smooth(0.02, 0.06, d2)))[..., None]
        if kind == 'pad':
            r = np.hypot(A - TILE / 2, B - TILE / 2); team[(r > TILE * 0.36) & (r < TILE * 0.42)] = 1.0; c[r < TILE * 0.36] = MECH * 0.9
            tk = (r > TILE * 0.3) & (r < TILE * 0.36) & (np.abs(((np.degrees(np.arctan2(B - TILE / 2, A - TILE / 2)) + 7.5) % 15) - 7.5) < 2.5); c[tk] = LIGHT * 0.8
            lamp(r < 0.6, WINC)
        else:
            hazard(B > TILE - 3.2)                        # outer edge is the top of the image-space tile (flipped below -> low b)
            if kind == 'pad_corner': hazard(A < 3.2); lamp(np.hypot(A - 5.2, B - (TILE - 5.2)) < 0.45, RED)
            team[(B < TILE - 4.2) & (B > TILE - 5.6) & ((A > 4.2) | (kind == 'pad_edge'))] = 1.0
            if kind == 'pad_corner': team[(A > 4.2) & (A < 5.6) & (B < TILE - 4.2)] = 1.0
    elif kind == 'hangar':
        c[:] = MECH * 0.55; ins = (A > 4) & (A < TILE - 4) & (B > 9) & (B < TILE - 9)
        g = np.minimum(np.abs((A % 2.7) - 1.35), np.abs((B % 2.2) - 1.1)); c[ins] = AMBER * (0.30 + 0.25 * smooth(0.05, 0.2, g[ins]))[:, None]; emit[ins] = 0.55
        fr = ((A > 2.6) & (A < TILE - 2.6) & (B > 7.6) & (B < TILE - 7.6)) & ~ins; hazard(fr)
        lamp(ins & (np.abs(B - 10.2) < 0.22) & (np.abs((A % 1.8) - 0.9) < 0.5), AMBER)
    c = c * (0.93 + 0.07 * ihash(np.floor(A / 3.3), np.floor(B / 3.3), seed=seed + 77))[..., None]        # faint mottling
    return [np.flipud(x) for x in (np.clip(c, 0, 1), team, np.maximum(emit, 0.10), refl)]

def make_tileset(specs, ss=2):
    inner = CELL - 2 * GUT; S = GRID * CELL
    t1 = np.zeros((S, S, 4), np.float32); t2 = np.zeros((S, S, 4), np.float32); t2[..., 3] = 1
    for k, spec in enumerate(specs):
        c, team, emit, refl = make_tile(spec, inner * ss)
        down = lambda x: x.reshape(inner, ss, inner, ss, -1).mean((1, 3))
        rgba = np.dstack([down(c), down(team)]); er = np.dstack([down(emit), down(refl)])
        # light spill round lamps, wrapped so it stays seamless
        glow = np.dstack([ndimage.gaussian_filter(rgba[..., i] * np.clip((er[..., 0] - 0.3) * 1.6, 0, 1), 2.5, mode='wrap') for i in range(3)])
        rgba[..., :3] = np.clip(rgba[..., :3] + glow * 0.5, 0, 1); er[..., 0] = np.clip(er[..., 0] + glow.max(-1) * 0.6, 0, 1)
        pad = lambda x: np.pad(x, ((GUT, GUT), (GUT, GUT), (0, 0)), mode='wrap')
        r, q = divmod(k, GRID); y0, x0 = r * CELL, q * CELL
        t1[y0:y0 + CELL, x0:x0 + CELL] = pad(rgba); t2[y0:y0 + CELL, x0:x0 + CELL, :2] = pad(er)
    u8 = lambda x: (np.clip(x, 0, 1) * 255 + 0.5).astype(np.uint8)
    return Image.fromarray(u8(t1), 'RGBA'), Image.fromarray(u8(t2), 'RGBA')

def tile_uv(k, lu, lv, rot=0):
    """Sheet UV (s3o convention) for local tile coords lu,lv in 0..1 of tile k, rotated rot quarter turns."""
    for _ in range(rot % 4): lu, lv = lv, 1 - lu
    r, q = divmod(k, GRID); inner = CELL - 2 * GUT; S = GRID * CELL
    u = (q * CELL + GUT + lu * inner) / S; row = (r * CELL + GUT + (1 - lv) * inner) / S
    return u, 1 - row
