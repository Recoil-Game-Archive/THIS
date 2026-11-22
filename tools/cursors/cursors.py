#!/usr/bin/env python3
"""THIS HD cursors: the game's cursor set redrawn as anti-aliased vector art with smooth animation.

    python3 tools/cursors/cursors.py [cursorname ...]      write the cursors (all, or only the named ones)
    python3 tools/cursors/cursors.py --preview DIR         an animated GIF and a still sheet of the whole set

Writes, for every size in SIZES (px of a centred cursor's canvas):
    Anims/hd/<size>/<cursor>_<i>.png       frames (RGBA)
    Anims/hd/<size>/<cursor>.txt           engine spec file: per-frame image + length, hotspot
and the default set (DEFAULT_SIZE) as Anims/<cursor>.txt, which the engine reads before any <cursor>_<i>.bmp/png.
LuaUI/widgets/gui_cursor_size.lua swaps in the size that suits the screen (Spring.ReplaceMouseCursor) and assigns
the cursors of the game's own commands (Turn, Rally Point).

Every cursor is drawn on a 64 x 64 design grid, centre (32, 32) = the hotspot (the pointer on its own smaller grid,
hotspot top left), at SS x the output size, then downsampled. Shapes get a vertical gradient fill, a dark outline
and, where wanted, a soft glow. The designs follow the old THIS cursors: the angular white pointer, green chevrons
closing in for move, the broken orange ring for attack, a ring of green diamonds for guard, blue for patrol.
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ANIMS = "Anims"          # folder on disk
SPEC_ROOT = "anims"      # how the engine addresses it
SIZES = [32, 48, 64, 96]
DEFAULT_SIZE = 48
SS = 4

OUT = (4, 7, 14)
SILVER = ((255, 255, 255), (150, 165, 190))
GREEN = ((175, 255, 150), (20, 150, 55))
RED = ((255, 150, 60), (200, 25, 5))
YELLOW = ((255, 250, 170), (240, 165, 0))
ORANGE = ((255, 215, 120), (235, 100, 10))
CYAN = ((205, 250, 255), (25, 140, 215))
BLUE = ((165, 195, 255), (50, 75, 225))
STEEL = ((215, 232, 245), (55, 90, 130))
GREY = ((205, 210, 218), (95, 102, 114))


def lerp(a, b, t):
    return a + (b - a) * t


def lerpc(c1, c2, t):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(len(c1)))


def mix(g1, g2, t):
    """blend two gradients"""
    return (lerpc(g1[0], g2[0], t), lerpc(g1[1], g2[1], t))


def ease(t):
    return 0.5 - 0.5 * math.cos(math.pi * max(0.0, min(1.0, t)))


def wave(t):
    """0..1..0 over one loop"""
    return 0.5 - 0.5 * math.cos(2 * math.pi * t)


class Canvas:
    def __init__(self, size, w=64, h=64):
        self.w, self.h = w, h
        self.k = size * SS / 64.0      # supersampled px per design unit
        self.W, self.H = int(round(w * self.k)), int(round(h * self.k))
        self.img = Image.new("RGBA", (self.W, self.H), (0, 0, 0, 0))

    def P(self, p):
        return (p[0] * self.k, p[1] * self.k)

    def mask(self, fn):
        m = Image.new("L", (self.W, self.H), 0)
        fn(ImageDraw.Draw(m), self)
        return m

    def _fill(self, m, fill, alpha=1.0):
        if isinstance(fill[0], int):
            top, bot = fill, fill
        else:
            top, bot = fill
        bb = m.getbbox()
        if not bb:
            return
        y0, y1 = bb[1], max(bb[3], bb[1] + 1)
        grad = Image.new("RGBA", (1, self.H))
        for y in range(self.H):
            t = min(1.0, max(0.0, (y - y0) / (y1 - y0)))
            grad.putpixel((0, y), lerpc(top, bot, t) + (255,))
        grad = grad.resize((self.W, self.H))
        if alpha < 1.0:
            m = m.point(lambda v: int(v * alpha))
        grad.putalpha(m)   # straight alpha (paste with a mask would darken the colour by the mask too)
        self.img.alpha_composite(grad)

    def dilate(self, m, r):
        if r <= 0:
            return m
        b = m.filter(ImageFilter.GaussianBlur(r * self.k * 0.5))
        return b.point(lambda v: 0 if v < 6 else (255 if v > 40 else int((v - 6) * 255 / 34)))

    def glow(self, m, color, radius=4.0, strength=0.8):
        g = m.filter(ImageFilter.GaussianBlur(radius * self.k))
        g = g.point(lambda v: min(255, int(v * strength * 1.6)))
        self._fill(g, color)

    def shape(self, fn, fill, outline=2.0, glow=None, alpha=1.0):
        """fn(draw, canvas) draws the shape in white on a mask."""
        m = self.mask(fn)
        if glow:
            col, rad, st = glow
            self.glow(self.dilate(m, outline), col, rad, st * alpha)
        if outline:
            self._fill(self.dilate(m, outline), OUT, alpha * 0.95)
        self._fill(m, fill, alpha)
        return m

    def out(self, size):
        im = self.img.convert("RGBa").resize((int(round(self.w * size / 64)), int(round(self.h * size / 64))),
                                             Image.LANCZOS)
        return im.convert("RGBA")


# --- shape helpers (design coords) ----------------------------------------------------------------------------
def poly(pts):
    return lambda d, c: d.polygon([c.P(p) for p in pts], fill=255)


def polys(*plist):
    def f(d, c):
        for pts in plist:
            d.polygon([c.P(p) for p in pts], fill=255)
    return f


def circle(cx, cy, r):
    return lambda d, c: d.ellipse([c.P((cx - r, cy - r)), c.P((cx + r, cy + r))], fill=255)


def ring(cx, cy, r, w):
    def f(d, c):
        d.ellipse([c.P((cx - r - w / 2, cy - r - w / 2)), c.P((cx + r + w / 2, cy + r + w / 2))], fill=255)
        d.ellipse([c.P((cx - r + w / 2, cy - r + w / 2)), c.P((cx + r - w / 2, cy + r - w / 2))], fill=0)
    return f


def arc(cx, cy, r, a0, a1, w, caps=True):
    """degrees, 0 = east, clockwise (screen)"""
    def f(d, c):
        if a1 - a0 <= 0.5:
            return
        d.arc([c.P((cx - r - w / 2, cy - r - w / 2)), c.P((cx + r + w / 2, cy + r + w / 2))], a0, a1, fill=255,
              width=max(1, int(round(w * c.k))))
        if caps:
            for a in (a0, a1):
                x, y = cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))
                d.ellipse([c.P((x - w / 2, y - w / 2)), c.P((x + w / 2, y + w / 2))], fill=255)
    return f


def line(p1, p2, w):
    def f(d, c):
        d.line([c.P(p1), c.P(p2)], fill=255, width=max(1, int(round(w * c.k))))
        for p in (p1, p2):
            d.ellipse([c.P((p[0] - w / 2, p[1] - w / 2)), c.P((p[0] + w / 2, p[1] + w / 2))], fill=255)
    return f


def lines(segs, w):
    def f(d, c):
        for p1, p2 in segs:
            line(p1, p2, w)(d, c)
    return f


def rect(x0, y0, x1, y1, r=0):
    return lambda d, c: d.rounded_rectangle([c.P((x0, y0)), c.P((x1, y1))], radius=r * c.k, fill=255)


def union(*fns):
    def f(d, c):
        for fn in fns:
            fn(d, c)
    return f


def rot(p, a, cx=32, cy=32):
    s, co = math.sin(a), math.cos(a)
    x, y = p[0] - cx, p[1] - cy
    return (cx + x * co - y * s, cy + x * s + y * co)


def polar(r, a, cx=32, cy=32):
    return (cx + r * math.cos(a), cy + r * math.sin(a))


def diamond(cx, cy, r, stretch=1.0):
    return [(cx, cy - r * stretch), (cx + r, cy), (cx, cy + r * stretch), (cx - r, cy)]


def arrowhead(tip, direction, length, width):
    """triangle pointing along direction (radians)"""
    dx, dy = math.cos(direction), math.sin(direction)
    bx, by = tip[0] - dx * length, tip[1] - dy * length
    return [tip, (bx - dy * width / 2, by + dx * width / 2), (bx + dy * width / 2, by - dx * width / 2)]


def chevron(tip, direction, length, width, thick):
    """a '>' pointing along direction (radians), its point at tip"""
    def P(along, across):
        dx, dy = math.cos(direction), math.sin(direction)
        return (tip[0] - dx * along - dy * across, tip[1] - dy * along + dx * across)
    return [P(0, 0), P(length, width / 2), P(length + thick, width / 2), P(thick, 0), P(length + thick, -width / 2),
            P(length, -width / 2)]


def ticks(r0, r1, a0=0.0, n=4):
    """n short radial lines round the centre"""
    return [(polar(r0, a0 + i * 2 * math.pi / n), polar(r1, a0 + i * 2 * math.pi / n)) for i in range(n)]


def centre(c, col=SILVER, r0=3.0, r1=7.0, w=1.8):
    """the small open cross every targeting cursor has in the middle: the exact spot is left clear"""
    c.shape(lines(ticks(r0, r1), w), col, outline=1.4)


# --- cursors ----------------------------------------------------------------------------------------------------
def c_normal(c, t):
    # THIS's angular pointer: a corner for the head and a separate shaft; a glint sweeps along it now and then
    head = [(2, 2), (30, 2), (23.5, 8.5), (8.5, 8.5), (8.5, 23.5), (2, 30)]
    shaft = [(13.5, 18), (18, 13.5), (41, 36.5), (36.5, 41)]
    fill = ((255, 255, 255), (130, 165, 215))
    m = c.shape(polys(head, shaft), fill, outline=2.2, glow=((90, 160, 255), 2.5, 0.35))
    edge = c.mask(polys([(2, 2), (30, 2), (27.5, 4.5), (4.5, 4.5), (4.5, 27.5), (2, 30)],
                        [(13.5, 18), (15, 16.5), (38, 39.5), (36.5, 41)]))
    c._fill(ImageChops.multiply(edge, m), (255, 255, 255), 0.7)
    if t < 0.35:
        g = t / 0.35
        d = lerp(-12, 56, g)
        band = c.mask(poly([(d, 0), (d + 9, 0), (0, d + 9), (0, d)]))
        c._fill(ImageChops.multiply(band, m), (255, 255, 255), 0.85 * math.sin(math.pi * g))


def c_move(c, t):
    # green chevrons close in on the spot from both sides
    for side in (-1, 1):
        direction = 0 if side < 0 else math.pi
        for i in range(3):
            ph = (t + i / 3.0) % 1.0
            d = lerp(20.5, 8.0, ph)
            al = min(1.0, ph * 4) * min(1.0, (1 - ph) * 3.5)
            tip = (32 + side * d, 32)
            c.shape(poly(chevron(tip, direction, 6.0, 18, 4.4)), GREEN, outline=1.8,
                    glow=((90, 255, 110), 2.5, 0.4), alpha=al)
    p = wave(t * 3)
    c.shape(poly(diamond(32, 32, 3.4 + 0.8 * p)), ((235, 255, 230), (90, 220, 110)), outline=1.5,
            glow=((120, 255, 130), 2.5, 0.5 + 0.4 * p))


def reticle(c, colors, r, spin=0.0, span=58, width=4.0, glow=0.6, teeth=True):
    """THIS's attack ring: four arcs with gaps at the compass points, a tooth on each pointing at the target"""
    segs = [arc(32, 32, r, 45 + i * 90 - span / 2 + spin, 45 + i * 90 + span / 2 + spin, width, caps=False)
            for i in range(4)]
    c.shape(union(*segs), colors, outline=1.9, glow=(colors[1], 3.5, glow))
    if teeth:
        tri = [arrowhead(polar(r - width / 2 - 4.8, math.radians(45 + i * 90 + spin)),
                         math.radians(45 + i * 90 + spin) + math.pi, 5.0, 7.0) for i in range(4)]
        c.shape(polys(*tri), colors, outline=1.5)


def c_attack(c, t):
    # the ring breathes in onto the target and flares from red to yellow as it closes
    p = wave(t)
    col = mix(RED, YELLOW, p * 0.85)
    r = lerp(22, 17.5, p)
    reticle(c, col, r, width=4.4, glow=0.45 + 0.5 * p, teeth=False)
    c.shape(lines(ticks(r - 6.5, r + 5.5), 2.4), col, outline=1.5)
    centre(c, ((255, 250, 235), (255, 190, 120)))


def c_fight(c, t):
    # attack-move: the attack ring in amber, turning, with move's chevrons riding on it
    reticle(c, ORANGE, 19.5, spin=t * 90, glow=0.6, teeth=False)
    for side in (-1, 1):
        ph = wave(t * 2)
        tip = (32 + side * lerp(14.5, 11.5, ph), 32)
        c.shape(poly(chevron(tip, 0 if side < 0 else math.pi, 4.6, 12.5, 3.4)), GREEN, outline=1.6,
                glow=((90, 255, 110), 2.5, 0.5))
    centre(c, ((255, 250, 235), (255, 190, 120)), 2.4, 5.0, 1.6)


def c_manfire(c, t):
    # the Quasar's mega laser: a cold blue ring, a second one turning against it, and a charging core
    p = wave(t)
    hot = ((255, 255, 255), (60, 150, 255))
    reticle(c, mix(CYAN, hot, p), 20.5, spin=t * 90, glow=0.55 + 0.4 * p)
    segs = [arc(32, 32, 12.5, i * 90 - 26 - t * 90, i * 90 + 26 - t * 90, 2.0, caps=False) for i in range(4)]
    c.shape(union(*segs), BLUE, outline=1.4)
    c.shape(lines(ticks(25, 29.5), 2.2), CYAN, outline=1.5)
    c.shape(circle(32, 32, 3.0 + 1.8 * p), ((255, 255, 255), (150, 225, 255)), outline=1.2,
            glow=((110, 200, 255), 3.5, 0.6 + 0.6 * p))


def c_attackbad(c, t):
    # cannot attack that: the ring gone grey behind a no-entry sign
    reticle(c, GREY, 21, glow=0.0)
    p = wave(t)
    col = mix(((255, 120, 90), (190, 10, 0)), ((255, 240, 120), (230, 150, 0)), p)
    sign = union(ring(32, 32, 10.5, 3.8), line(polar(10.5, math.radians(225)), polar(10.5, math.radians(45)), 3.8))
    c.shape(sign, col, outline=1.8, glow=(col[1], 2.0, 0.25 + 0.25 * p))


def c_defend(c, t):
    # guard: THIS's ring of green diamonds; two swells run round it like a shield being raised
    n = 16
    small, big = [], []
    for i in range(n):
        a = i * 2 * math.pi / n
        d = (a - 2 * math.pi * t) % math.pi          # two swells, opposite each other
        d = min(d, math.pi - d)
        swell = max(0.0, 1 - d / 0.62) ** 1.5
        x, y = polar(21, a)
        (big if swell > 0.3 else small).append(diamond(x, y, 2.3 + 3.3 * swell))
    c.shape(polys(*small), GREEN, outline=1.5)
    c.shape(polys(*big), ((235, 255, 220), (60, 210, 90)), outline=1.7, glow=((110, 255, 120), 3.0, 0.8))
    c.shape(ring(32, 32, 12.5, 1.5), ((200, 255, 200), (60, 180, 90)), outline=1.2, alpha=0.75)
    centre(c)


def c_patrol(c, t):
    # three blue markers chase each other round the beat
    c.shape(ring(32, 32, 20.5, 1.5), BLUE, outline=1.2, alpha=0.7)
    orbs = []
    for i in range(3):
        a = 2 * math.pi * (t + i / 3.0)
        for j in range(5):   # trail
            aa = a - j * 0.17
            x, y = polar(20.5, aa)
            orbs.append((x, y, 3.7 - j * 0.6, j))
    for x, y, r, j in sorted(orbs, key=lambda o: -o[3]):
        c.shape(circle(x, y, r), CYAN if j == 0 else BLUE, outline=1.4 if j == 0 else 0,
                glow=((90, 170, 255), 2.8, 0.7) if j == 0 else None, alpha=1.0 - j * 0.19)
    centre(c)


def c_turn(c, t):
    # turn in place: two curved arrows wheel round the point to face
    spin = t * 180
    arrows = []
    for i in range(2):
        a0 = spin + i * 180
        arrows.append(arc(32, 32, 18.5, a0, a0 + 112, 3.8))
        end = math.radians(a0 + 112)
        ex, ey = polar(18.5, end)
        along = end + math.pi / 2 + 0.22          # the tangent, bent in a little to follow the curve
        tip = (ex + math.cos(along) * 8.5, ey + math.sin(along) * 8.5)
        arrows.append(poly(arrowhead(tip, along, 10.0, 12.5)))
    c.shape(union(*arrows), CYAN, outline=1.8, glow=((80, 190, 255), 3.0, 0.6))
    c.shape(line((32, 32), (32, 21.5), 2.0), SILVER, outline=1.4)
    c.shape(poly(arrowhead((32, 15.5), -math.pi / 2, 7.0, 7.5)), SILVER, outline=1.4)
    c.shape(circle(32, 32, 2.2), (255, 255, 255), outline=1.3)


def c_rally(c, t):
    # rally point: a beacon sending out rings
    for k in range(2):
        ph = (t + k * 0.5) % 1.0
        c.shape(ring(32, 32, 7 + 19 * ph, 2.8 * (1 - ph) + 1.2), GREEN, outline=1.5,
                glow=((90, 255, 120), 2.5, 0.7 * (1 - ph)), alpha=min(1.0, (1 - ph) * 1.6))
    p = wave(t * 2)
    c.shape(poly(diamond(32, 32, 6.0 + 0.8 * p, 1.25)), ((235, 255, 225), (40, 185, 80)), outline=1.8,
            glow=((110, 255, 130), 3.0, 0.6 + 0.4 * p))
    c.shape(poly(diamond(32, 32, 2.2, 1.25)), (255, 255, 255), outline=0)


def c_wait(c, t):
    # an hourglass whose sand runs, then flips
    flip = ease(max(0, (t - 0.85) / 0.15)) * math.pi
    sand = min(1, t / 0.85)

    def R(p):
        return rot(p, flip)
    frame = [R(p) for p in [(21, 14), (43, 14), (34, 32), (43, 50), (21, 50), (30, 32)]]
    c.shape(union(rect(18, 11, 46, 15, 1.5), rect(18, 49, 46, 53, 1.5)) if flip == 0 else
            polys([R(p) for p in [(18, 11), (46, 11), (46, 15), (18, 15)]],
                  [R(p) for p in [(18, 49), (46, 49), (46, 53), (18, 53)]]), STEEL, outline=1.6)
    c.shape(poly(frame), ((235, 248, 255), (150, 190, 225)), outline=1.8)
    top = 1 - sand
    if top > 0.02:
        h = 15 * top
        c.shape(poly([R(p) for p in [(32 - 9 * top, 31 - h), (32 + 9 * top, 31 - h), (32, 31.5)]]), YELLOW, outline=0)
    if sand > 0.02 and flip == 0:
        h = 14 * sand
        c.shape(poly([(32 - 9.5 * min(1, sand * 1.4), 49), (32 + 9.5 * min(1, sand * 1.4), 49), (32, 49 - h)]), YELLOW,
                outline=0)
        if sand < 1:
            c.shape(line((32, 32), (32, 48), 1.0), YELLOW, outline=0)


CURSORS = {
    # name:          (frames, length, fn, pointer)
    "cursornormal":    (30, 0.04, c_normal, True),
    "cursormove":      (24, 0.04, c_move, False),
    "cursorattack":    (24, 0.04, c_attack, False),
    "cursorattackbad": (24, 0.04, c_attackbad, False),
    "cursorfight":     (24, 0.04, c_fight, False),
    "cursormanfire":   (24, 0.04, c_manfire, False),
    "cursorpatrol":    (36, 0.04, c_patrol, False),
    "cursordefend":    (32, 0.04, c_defend, False),
    "cursorwait":      (40, 0.05, c_wait, False),
    "cursorturn":      (30, 0.04, c_turn, False),
    "cursorrally":     (30, 0.04, c_rally, False),
}
POINTER = (44, 44)   # design grid of the pointer


def render(name, size, frame):
    frames, length, fn, pointer = CURSORS[name]
    c = Canvas(size, *POINTER) if pointer else Canvas(size)
    t = frame / frames
    if name == "cursornormal":
        # the glint plays in the first 12 frames; the rest is the plain arrow (written once, held via the spec)
        t = frame / 12 * 0.35 if frame < 12 else 0.99
    fn(c, t)
    return c.out(size)


def write_set(size, only=None):
    d = os.path.join(ROOT, ANIMS, "hd", str(size))
    os.makedirs(d, exist_ok=True)
    for name, (frames, length, fn, pointer) in CURSORS.items():
        if only and name not in only:
            continue
        spec = ["hotspot %s" % ("topleft" if pointer else "center")]
        if name == "cursornormal":
            for i in range(13):
                render(name, size, i).save(os.path.join(d, "%s_%d.png" % (name, i)), optimize=True)
            spec.append("frame %s/hd/%d/%s_12.png 2.5" % (SPEC_ROOT, size, name))
            for i in range(12):
                spec.append("frame %s/hd/%d/%s_%d.png %.3f" % (SPEC_ROOT, size, name, i, length))
        else:
            for i in range(frames):
                render(name, size, i).save(os.path.join(d, "%s_%d.png" % (name, i)), optimize=True)
                spec.append("frame %s/hd/%d/%s_%d.png %.3f" % (SPEC_ROOT, size, name, i, length))
        body = "\n".join(spec) + "\n"
        open(os.path.join(d, name + ".txt"), "w").write(body)
        if size == DEFAULT_SIZE:
            open(os.path.join(ROOT, ANIMS, name + ".txt"), "w").write(body)
        print(size, name, flush=True)


def preview(outdir, size=64, scale=2):
    """an animated GIF of every cursor on a space-coloured board, and a still sheet"""
    os.makedirs(outdir, exist_ok=True)
    names = list(CURSORS)
    cols = 6
    cell = int(size * 1.3)
    rows = (len(names) + cols - 1) // cols
    n = 60
    gif = []
    for f in range(n):
        board = Image.new("RGBA", (cols * cell, rows * cell), (10, 14, 28, 255))
        for i, name in enumerate(names):
            frames = CURSORS[name][0]
            im = render(name, size, (f * frames // n) % frames if name != "cursornormal" else min(12, f // 2))
            x, y = (i % cols) * cell + (cell - im.width) // 2, (i // cols) * cell + (cell - im.height) // 2
            board.alpha_composite(im, (x, y))
        board = board.resize((board.width * scale, board.height * scale), Image.LANCZOS)
        gif.append(board.convert("RGB"))
    gif[0].save(os.path.join(outdir, "cursors.gif"), save_all=True, append_images=gif[1:], duration=40, loop=0)
    gif[n // 3].save(os.path.join(outdir, "cursors_still.png"))


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--preview":
        preview(args[1])
    else:
        only = set(a for a in args if a.startswith("cursor")) or None
        for s in SIZES:
            write_set(s, only)
