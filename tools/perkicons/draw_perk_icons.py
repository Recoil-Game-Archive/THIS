#!/usr/bin/env python3
"""Draw the perk icons in bitmaps/perks/.

All twelve icons are drawn by this script in one style: a light, single-colour
symbol on a transparent background (128x128), meant to sit on a dark tile.
To change an icon, edit its function below and run:

    python3 tools/perkicons/draw_perk_icons.py

Needs Python 3 with Pillow. File names match LuaUI/perks/perks.lua.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SIZE = 128                   # size of the finished icon
S = 1024                     # icons are drawn on a 1024x1024 sheet and scaled down
COLOUR = (230, 237, 247)     # the HUD's text colour (#e6edf7)
C = S // 2


def sheet():
    image = Image.new("L", (S, S), 0)
    return image, ImageDraw.Draw(image)


def disc(d, x, y, r, fill=255):
    d.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def seg(d, a, b, w, fill=255):
    """A line with round ends."""
    d.line([a, b], fill=fill, width=w)
    disc(d, a[0], a[1], w / 2, fill)
    disc(d, b[0], b[1], w / 2, fill)


def arc(d, x, y, r, start, end, w):
    """An arc with round ends; angles in degrees, clockwise from 3 o'clock."""
    d.arc((x - r, y - r, x + r, y + r), start, end, fill=255, width=w)
    for angle in (start, end):
        mid = r - w / 2
        disc(d, x + mid * math.cos(math.radians(angle)), y + mid * math.sin(math.radians(angle)), w / 2)


def polar(r, degrees, cx=C, cy=C):
    return (cx + r * math.cos(math.radians(degrees)), cy + r * math.sin(math.radians(degrees)))


def massdriver():
    """Mass Driver Weapons: a slug leaving a pair of rails."""
    image, d = sheet()
    seg(d, (140, 352), (640, 352), 64)
    seg(d, (140, 672), (640, 672), 64)
    d.rounded_rectangle((420, 442, 760, 582), 26, fill=255)
    d.polygon([(740, 442), (880, 512), (740, 582)], fill=255)
    seg(d, (140, 512), (260, 512), 44)
    return image.rotate(24, resample=Image.BICUBIC)


def armory():
    """Open Armory Policy: a turret, plus one more."""
    image, d = sheet()
    seg(d, (440, 560), (590, 230), 76)
    seg(d, (610, 600), (760, 270), 76)
    disc(d, 512, 730, 300, 0)
    d.pieslice((252, 470, 772, 990), 180, 360, fill=255)
    d.rounded_rectangle((192, 760, 832, 850), 30, fill=255)
    seg(d, (170, 250), (370, 250), 56)
    seg(d, (270, 150), (270, 350), 56)
    return image


def public_support():
    """Public Support: people standing behind you."""
    image, d = sheet()
    for x in (215, 809):
        disc(d, x, 450, 88)
        d.pieslice((x - 150, 590, x + 150, 890), 180, 360, fill=255)
    disc(d, 512, 350, 172, 0)
    d.pieslice((257, 475, 767, 985), 180, 360, fill=0)
    disc(d, 512, 350, 126)
    d.pieslice((302, 520, 722, 940), 180, 360, fill=255)
    d.rectangle((0, 741, S, S), fill=0)
    return image


def automation():
    """Advanced Automation: a gear."""
    image, d = sheet()
    for k in range(8):
        angle = k * 45 + 22.5
        tip, root = 400, 250
        half_tip, half_root = 9.5, 13.5
        d.polygon([polar(root, angle - half_root), polar(tip, angle - half_tip),
                   polar(tip, angle + half_tip), polar(root, angle + half_root)], fill=255)
    disc(d, C, C, 300)
    disc(d, C, C, 125, 0)
    return image


def sensors():
    """High-Res Sensors: a dish sending out waves."""
    image, d = sheet()
    disc(d, 262, 762, 82)
    for r in (270, 450, 630):
        arc(d, 262, 762, r, 278, 352, 72)
    return image


def dark_matter():
    """Dark Matter Technology: a dark body with something in orbit."""
    image, d = sheet()
    orbit, od = sheet()
    od.ellipse((92, 342, 932, 682), outline=255, width=60)
    image = ImageChops.lighter(image, orbit.rotate(32, resample=Image.BICUBIC))
    d = ImageDraw.Draw(image)
    disc(d, C, C, 250, 0)
    d.ellipse((C - 190, C - 190, C + 190, C + 190), outline=255, width=60)
    disc(d, C, C, 70)
    return image


def cloak():
    """Cloaking System: a ship that is only an outline."""
    image, d = sheet()
    points = [(512, 120), (830, 870), (512, 700), (194, 870)]
    dash, gap, width = 118, 92, 58
    for i in range(len(points)):
        a, b = points[i], points[(i + 1) % len(points)]
        length = math.dist(a, b)
        count = max(1, round((length + gap) / (dash + gap)))
        step = (length + gap) / count
        for k in range(count):
            t0 = k * step / length
            t1 = min((k * step + step - gap) / length, 1.0)
            seg(d, (a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1), width)
    return image


def shield_outline(scale):
    points = [(512, 100), (840, 215), (840, 480)]
    for k in range(1, 13):               # the curved lower right edge
        t = k / 12
        x = (1 - t) ** 2 * 840 + 2 * (1 - t) * t * 820 + t * t * 512
        y = (1 - t) ** 2 * 480 + 2 * (1 - t) * t * 790 + t * t * 930
        points.append((x, y))
    points += [(S - x, y) for x, y in reversed(points[1:-1])]
    cx, cy = 512, 500
    return [(cx + (x - cx) * scale, cy + (y - cy) * scale) for x, y in points]


def shield():
    """Shield Crazy: a shield."""
    image, d = sheet()
    d.polygon(shield_outline(1.0), fill=255)
    d.polygon(shield_outline(0.76), fill=0)
    d.polygon(shield_outline(0.46), fill=255)
    return image


def inventive():
    """Inventive: a light bulb."""
    image, d = sheet()
    d.ellipse((252, 110, 772, 630), outline=255, width=62)
    d.polygon([(400, 590), (624, 590), (610, 700), (414, 700)], fill=255)
    seg(d, (424, 770), (600, 770), 56)
    seg(d, (464, 860), (560, 860), 56)
    seg(d, (430, 370), (512, 480), 42)
    seg(d, (594, 370), (512, 480), 42)
    seg(d, (512, 480), (512, 600), 42)
    return image


def emp():
    """EMP Missiles: a bolt and its pulse."""
    image, d = sheet()
    d.polygon([(590, 110), (320, 560), (486, 560), (424, 914), (716, 440), (546, 440), (680, 110)], fill=255)
    arc(d, C, C, 440, 148, 212, 58)
    arc(d, C, C, 440, -32, 32, 58)
    return image


def antimatter():
    """Antimatter Warheads: a violent burst."""
    image, d = sheet()
    radii = [440, 170, 300, 170]
    points = [polar(radii[k % 4], k * 22.5 - 90) for k in range(16)]
    d.polygon(points, fill=255)
    disc(d, C, C, 112, 0)
    disc(d, C, C, 56)
    return image


def singularity():
    """Microsingularity Device: everything pulled towards one point."""
    image, d = sheet()
    disc(d, C, C, 112)
    for angle in (0, 90, 180, 270):
        seg(d, polar(440, angle), polar(300, angle), 62)
        left, right = polar(330, angle - 17), polar(330, angle + 17)
        d.polygon([polar(190, angle), left, right], fill=255)
    return image


ICONS = {
    "massdriver": massdriver,
    "armory": armory,
    "public_support": public_support,
    "automation": automation,
    "improved_gravidar": sensors,
    "dark_matter": dark_matter,
    "warhammer_cloak": cloak,
    "shield": shield,
    "inventive": inventive,
    "emp": emp,
    "antimatter": antimatter,
    "grav_flak": singularity,
}


def main():
    for name, draw in ICONS.items():
        mask = draw().resize((SIZE, SIZE), Image.LANCZOS)
        icon = Image.new("RGBA", (SIZE, SIZE), COLOUR + (0,))
        icon.putalpha(mask)
        path = os.path.join(ROOT, "bitmaps", "perks", name + ".png")
        icon.save(path, optimize=True)
        print("drew", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
