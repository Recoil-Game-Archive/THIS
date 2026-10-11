#!/usr/bin/env python3
"""Render the unit pictures in unitpics/ from the game's own models.

Every picture uses the same camera angle, the same lighting and the same
starfield, so the set looks like one family. Run it again whenever a model or
texture changes:

    python3 tools/unitpics/render_unitpics.py            # every unit listed below
    python3 tools/unitpics/render_unitpics.py dagger sword

Needs Python 3 with numpy and Pillow. It reads objects3d/*.s3o and
unittextures/*, and writes unitpics/<unit>.png (256x192).
"""
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s3o  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

WIDTH, HEIGHT = 256, 192    # picture size (the old pictures were 128x96)
SUPERSAMPLE = 4             # rendered this many times larger, then scaled down
FILL = 0.80                 # how much of the frame the ship may take up

YAW = math.radians(-38)     # ship turned so its nose points towards the lower left
PITCH = math.radians(24)    # camera looks down on it by this much
ROLL = math.radians(-4)

# Hull colour for the parts the game paints in the team colour. A cool steel
# blue reads well next to any team's HUD accent.
HULL = np.array([0.46, 0.60, 0.88])

LIGHT = np.array([-0.45, 0.70, 0.55])   # key light: upper left, towards the viewer
FILL_LIGHT = np.array([0.60, 0.15, 0.40])
AMBIENT = 0.20

# Units with a picture. unit name -> model file is read from units/*.
UNITS = [
    "carrier", "supportcarrier", "stealthcarrier", "starbase", "minelayer", "meteor",
    "comet", "starslayer", "quasar", "imperator",
    "dagger", "sword", "mace", "claymore", "wraith", "longbow", "warhammer",
    "dronelauncherm", "gunstar_cannon", "gunstar_torpedo", "probe",
    "imperator_hangar", "imperator_hive", "imperator_turret_am",
    "imperator_turret_cannon", "imperator_turret_pd", "imperator_turret_plasma",
]


def model_of(unit):
    """The model file a unit definition names (objectName in units/<unit>.*)."""
    for ext in ("lua", "fbi"):
        path = os.path.join(ROOT, "units", unit + "." + ext)
        if os.path.exists(path):
            text = open(path, encoding="latin-1").read()
            match = re.search(r'objectname\s*=\s*"?([A-Za-z0-9_]+\.s3o)', text, re.I)
            if match:
                return match.group(1)
    raise SystemExit("no model found for unit %r" % unit)


def texture(name):
    """A model texture as float RGBA, or None if the model has none."""
    if not name:
        return None
    folder = os.path.join(ROOT, "unittextures")
    wanted = name.lower()
    stem = os.path.splitext(wanted)[0]
    for entry in os.listdir(folder):
        low = entry.lower()
        if low == wanted or os.path.splitext(low)[0] == stem:
            image = Image.open(os.path.join(folder, entry)).convert("RGBA")
            return np.asarray(image, dtype=np.float32) / 255.0
    return None


def sample(tex, u, v):
    height, width = tex.shape[:2]
    x = np.clip((u % 1.0) * width, 0, width - 1).astype(np.int32)
    y = np.clip(((1.0 - v) % 1.0) * height, 0, height - 1).astype(np.int32)
    return tex[y, x]


def rotation():
    cy, sy = math.cos(YAW), math.sin(YAW)
    cp, sp = math.cos(PITCH), math.sin(PITCH)
    cr, sr = math.cos(ROLL), math.sin(ROLL)
    yaw = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    pitch = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    roll = np.array([[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]])
    return roll @ pitch @ yaw


def backdrop(width, height):
    """The starfield every picture shares. Fixed seed: always the same stars."""
    rng = np.random.default_rng(7)
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    u, v = xs / width, ys / height
    base = np.zeros((height, width, 3), np.float32)
    base[...] = np.array([0.020, 0.030, 0.060])
    base += (1.0 - v)[..., None] * np.array([0.018, 0.022, 0.050])
    # two soft clouds of colour
    for cx, cy, radius, colour in ((0.78, 0.22, 0.42, (0.10, 0.07, 0.22)), (0.15, 0.85, 0.50, (0.03, 0.10, 0.16))):
        d = ((u - cx) ** 2 + ((v - cy) * height / width) ** 2) / (radius * radius)
        base += np.exp(-d * 2.2)[..., None] * np.array(colour)
    stars = np.zeros((height, width), np.float32)
    count = int(width * height / 260)
    sx = rng.integers(0, width, count)
    sy = rng.integers(0, height, count)
    brightness = rng.random(count) ** 3.2
    np.maximum.at(stars, (sy, sx), brightness)
    image = Image.fromarray((np.clip(stars, 0, 1) * 255).astype(np.uint8))
    glow = np.asarray(image.filter(ImageFilter.GaussianBlur(width / 420.0)), dtype=np.float32) / 255.0
    stars = np.clip(stars * 0.9 + glow * 2.2, 0, 1)
    base += stars[..., None] * np.array([0.92, 0.95, 1.0])
    # darker towards the corners, so the ship in the middle stands out
    vignette = 1.0 - 0.35 * (((u - 0.5) * 2) ** 2 + ((v - 0.5) * 2) ** 2)
    return np.clip(base * vignette[..., None], 0, 1)


def render(unit):
    model = s3o.load(os.path.join(ROOT, "objects3d", model_of(unit)))
    tris = np.array(model["tris"], dtype=np.float64)  # (n, 3, 8): position, normal, uv
    if len(tris) == 0:
        raise SystemExit("model of %r has no geometry" % unit)
    tex1 = texture(model["tex1"])
    tex2 = texture(model["tex2"])

    rot = rotation()
    pos = tris[:, :, 0:3] @ rot.T
    nrm = tris[:, :, 3:6] @ rot.T
    uv = tris[:, :, 6:8]

    width, height = WIDTH * SUPERSAMPLE, HEIGHT * SUPERSAMPLE
    lo = pos.reshape(-1, 3).min(axis=0)
    hi = pos.reshape(-1, 3).max(axis=0)
    scale = min(width * FILL / max(hi[0] - lo[0], 1e-6), height * FILL / max(hi[1] - lo[1], 1e-6))
    centre = (lo + hi) / 2
    sx = (pos[:, :, 0] - centre[0]) * scale + width / 2
    sy = height / 2 - (pos[:, :, 1] - centre[1]) * scale
    sz = pos[:, :, 2]  # larger is nearer to the camera

    light = LIGHT / np.linalg.norm(LIGHT)
    fill = FILL_LIGHT / np.linalg.norm(FILL_LIGHT)
    half = light + np.array([0.0, 0.0, 1.0])
    half /= np.linalg.norm(half)

    colour = np.zeros((height, width, 3), np.float32)
    cover = np.zeros((height, width), np.float32)
    depth = np.full((height, width), -np.inf)

    for i in range(len(tris)):
        x0, x1, x2 = sx[i]
        y0, y1, y2 = sy[i]
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        minx, maxx = max(int(math.floor(min(x0, x1, x2))), 0), min(int(math.ceil(max(x0, x1, x2))), width - 1)
        miny, maxy = max(int(math.floor(min(y0, y1, y2))), 0), min(int(math.ceil(max(y0, y1, y2))), height - 1)
        if minx > maxx or miny > maxy:
            continue
        py, px = np.mgrid[miny:maxy + 1, minx:maxx + 1]
        px = px + 0.5
        py = py + 0.5
        w0 = ((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)) / area
        w1 = ((x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)) / area
        w2 = 1.0 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue
        z = w0 * sz[i, 0] + w1 * sz[i, 1] + w2 * sz[i, 2]
        region = depth[miny:maxy + 1, minx:maxx + 1]
        hit = inside & (z > region)
        if not hit.any():
            continue

        n = w0[..., None] * nrm[i, 0] + w1[..., None] * nrm[i, 1] + w2[..., None] * nrm[i, 2]
        length = np.linalg.norm(n, axis=-1, keepdims=True)
        n = n / np.maximum(length, 1e-9)
        # models are not consistent about winding: light whichever side faces the camera
        n = np.where(n[..., 2:3] < 0, -n, n)

        if tex1 is not None:
            u = w0 * uv[i, 0, 0] + w1 * uv[i, 1, 0] + w2 * uv[i, 2, 0]
            v = w0 * uv[i, 0, 1] + w1 * uv[i, 1, 1] + w2 * uv[i, 2, 1]
            texel = sample(tex1, u, v)
            team = texel[..., 3:4]  # the alpha channel says where the team colour goes
            base = texel[..., 0:3] * (1.0 - team) + HULL * team
            glow = sample(tex2, u, v)[..., 0:1] if tex2 is not None and tex2.shape[0] > 64 else 0.0
        else:
            base = np.broadcast_to(HULL, n.shape)
            glow = 0.0

        diffuse = np.clip(n @ light, 0, 1)[..., None]
        soft = np.clip(n @ fill, 0, 1)[..., None]
        shine = (np.clip(n @ half, 0, 1) ** 28)[..., None]
        rim = ((1.0 - np.clip(n[..., 2:3], 0, 1)) ** 3) * 0.22
        shaded = base * (AMBIENT + 0.95 * diffuse + 0.22 * soft) + shine * 0.30 + rim * np.array([0.55, 0.70, 1.0])
        shaded = shaded + base * glow * 0.9

        region[hit] = z[hit]
        colour[miny:maxy + 1, minx:maxx + 1][hit] = shaded[hit]
        cover[miny:maxy + 1, minx:maxx + 1][hit] = 1.0

    # nearer parts a touch brighter, so overlapping hull sections separate
    finite = np.isfinite(depth)
    if finite.any():
        near, far = depth[finite].max(), depth[finite].min()
        fade = np.where(finite, (depth - far) / max(near - far, 1e-6), 0.0)
        colour *= (0.82 + 0.18 * fade)[..., None]

    back = backdrop(width, height)
    # a faint dark halo behind the ship keeps bright stars off its edges
    halo = np.asarray(Image.fromarray((cover * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(SUPERSAMPLE * 3)), dtype=np.float32) / 255.0
    back = back * (1.0 - 0.55 * halo[..., None])
    image = back * (1.0 - cover[..., None]) + np.clip(colour, 0, 1) * cover[..., None]
    image = np.clip(image, 0, 1) ** (1 / 1.12)
    out = Image.fromarray((image * 255 + 0.5).astype(np.uint8)).resize((WIDTH, HEIGHT), Image.LANCZOS)
    path = os.path.join(ROOT, "unitpics", unit + ".png")
    out.save(path, optimize=True)
    return path


def main():
    units = sys.argv[1:] or UNITS
    for unit in units:
        print("rendered", os.path.relpath(render(unit), ROOT))


if __name__ == "__main__":
    main()
