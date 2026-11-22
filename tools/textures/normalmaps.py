#!/usr/bin/env python3
"""Tangent-space normal maps for the S3O unit textures, derived from their diffuse (tex1) textures.

  normalmaps.py [--strength S] [--limit L] [--max 1024] [--only name1,name2] [--jobs N] [--preview DIR] [--force]

For every S3O model in objects3d/, reads its tex1 (diffuse + team colour in alpha) from unittextures/ and writes
unittextures/<tex1 stem>_normals.dds: DXT5 with a full mipmap chain, in the layout Beyond All Reason's CUS GL4 shader
reads (modelmaterials_gl4/templates/cus_gl4.frag.glsl):
  RGB = tangent-space normal * 0.5 + 0.5, red along +u (image right), green along +v (image DOWN: GL reads the DDS
        rows top-down; measured on BAR's Arm_color/Arm_normal pair), blue up
  A   = height (0..1), which CUS uses for its wreck/damage effects
There are no high-poly sources, so height comes from the diffuse brightness (dark panel lines, gaps and the baked
occlusion read as recesses), high-passed so large colour areas do not tilt, and slopes are taken at three scales:
fine (rivets, panel lines) strongest, then plates, then broad shapes. Faint slopes (dirt blotches, noise) fade
out below THRESHOLD, so panel lines and edges stand out instead of weathering; brightness goes through a curve
(GAMMA) so dark Core textures get about as much relief as bright Arm ones; slopes are soft-limited (tanh) so hard
colour edges do not become cliffs. --strength sets how visible the detail is, --limit the steepest tilt. Defaults
chosen by eye on Bulldog, Goliath, Arm Commander and Fusion previews (user: "very visible, not overbearing").
Resolution: the diffuse's own, capped at --max (2048 textures get 1024 normal maps); computed at full resolution and
averaged down, so the cap loses no detail to aliasing.

Needs numpy and Pillow (no scipy: blurs are done in the frequency domain).
"""
import argparse, os, struct, sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OBJ, TEX = os.path.join(ROOT, 'objects3d'), os.path.join(ROOT, 'unittextures')

# (sigma in pixels at 1024 px, weight): slopes are measured on the brightness blurred to each scale
SCALES = [(0.7, 1.0), (1.6, 0.4), (3.5, 0.15)]
GAMMA = 0.6              # height = brightness ** GAMMA (< 1 lifts dark textures)
THRESHOLD = 0.035        # luminance slope (per 1024-px pixel) below which detail fades out
HIGHPASS = 1 / 100         # remove brightness changes broader than this fraction of the texture (big colour areas)


def s3o_textures(path):
    d = open(path, 'rb').read()
    if not d.startswith(b'Spring unit'):
        return None
    t1, t2 = struct.unpack_from('<ii', d, 44)
    rd = lambda o: d[o:d.index(b'\0', o)].decode('latin-1') if o else ''
    return rd(t1), rd(t2)


def texture_list():
    files = {f.lower(): f for f in os.listdir(TEX)}
    out = {}
    for f in sorted(os.listdir(OBJ)):
        if f.lower().endswith('.s3o'):
            t = s3o_textures(os.path.join(OBJ, f))
            if t and t[0] and t[0].lower() in files and not t[0].lower().startswith('dummy'):  # dummy: blank.s3o, planets
                out[files[t[0].lower()]] = True
    return sorted(out)


def normal_name(tex1):
    return os.path.splitext(tex1)[0] + '_normals.dds'


def blur(img, sigma):
    """Gaussian blur via FFT (wraps at the borders; texture atlases have padding, so that is harmless)."""
    if sigma <= 0:
        return img
    h, w = img.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.rfftfreq(w)[None, :]
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (fx * fx + fy * fy))
    return np.fft.irfft2(np.fft.rfft2(img) * g, s=img.shape).astype(np.float32)


def make_normals(rgb, strength, limit, threshold=THRESHOLD):
    """rgb: HxWx3 float 0..1 -> (normal HxWx3 unit vectors, height HxW 0..1)."""
    h, w, _ = rgb.shape
    k = w / 1024.0                                   # scales are defined at 1024 px
    lum = (rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114).astype(np.float32)
    # height curve: expands dark tones so dark (Core) textures get about as much relief as bright (Arm) ones;
    # scaled to keep the slope at brightness 0.7 unchanged
    lum = lum ** GAMMA / (GAMMA * 0.7 ** (GAMMA - 1))
    lum = lum - blur(lum, w * HIGHPASS)              # detail only: no slope across big colour areas
    gx = np.zeros_like(lum)
    gy = np.zeros_like(lum)
    for sigma, weight in SCALES:
        b = blur(lum, sigma * k)
        dy, dx = np.gradient(b)
        gx += weight * dx * k                        # per 1024-px pixel, so strength means the same at any size
        gy += weight * dy * k
    if threshold > 0:                                # fade out faint slopes (dirt blotches, noise); keep distinct lines
        m = np.hypot(gx, gy)
        t = np.clip((m - threshold) / (1.5 * threshold), 0, 1)
        f = t * t * (3 - 2 * t)
        gx *= f; gy *= f
    sx = limit * np.tanh(-gx * strength / limit)     # soft limit: steep colour edges saturate instead of spiking
    sy = limit * np.tanh(-gy * strength / limit)
    # flat on average: baked one-sided lighting in the diffuse makes slopes rise more one way than the other, which
    # would tilt whole surfaces; remove the broad lean, keep the detail
    sx = sx - blur(sx, w * HIGHPASS * 2)
    sy = sy - blur(sy, w * HIGHPASS * 2)
    n = np.stack([sx, sy, np.ones_like(sx)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    height = np.clip(0.5 + lum * 2.0, 0, 1)
    return n.astype(np.float32), height.astype(np.float32)


def downsample(a):
    h, w = a.shape[:2]
    a = a[:h // 2 * 2, :w // 2 * 2]
    return (a[0::2, 0::2] + a[1::2, 0::2] + a[0::2, 1::2] + a[1::2, 1::2]) * 0.25


def _q565(c):
    """float 0..255 RGB -> 5/6/5 integer channels, floor and ceil candidates"""
    m = np.array([31, 63, 31], np.float32) / 255
    v = c * m
    return np.floor(v), np.ceil(v)


def _dq565(q):
    return q * (255 / np.array([31, 63, 31], np.float32))


def encode_bc3(rgba):
    """RGBA uint8 HxWx4 (H, W multiples of 4) -> BC3/DXT5 bytes. Own encoder: Pillow's rounds both endpoints the
    same way, so a flat normal (128,128,255) came out as (132,130,255), tilting every flat area ~3 degrees. Here
    each block tries floor/ceil roundings of its two endpoints (the 1/3-2/3 blends then land close to the true
    value) and keeps the one with the least error."""
    h, w, _ = rgba.shape
    blk = rgba.reshape(h // 4, 4, w // 4, 4, 4).transpose(0, 2, 1, 3, 4).reshape(-1, 16, 4).astype(np.float32)
    rgb, alpha = blk[..., :3], blk[..., 3]
    nb = blk.shape[0]
    # colour endpoint candidates: the block's bounding box and its principal axis (normals in a block mostly vary
    # along one slanted line), each with floor/ceil roundings; the one with the least error wins
    mean = rgb.mean(1)
    cen = rgb - mean[:, None, :]
    cov = np.einsum('bki,bkj->bij', cen, cen)
    axis = np.ones((nb, 3), np.float32)
    for _ in range(8):                                 # power iteration
        axis = np.einsum('bij,bj->bi', cov, axis)
        axis /= np.maximum(np.linalg.norm(axis, axis=1, keepdims=True), 1e-9)
    t = np.einsum('bki,bi->bk', cen, axis)
    p_hi = np.clip(mean + axis * t.max(1, keepdims=True), 0, 255)
    p_lo = np.clip(mean + axis * t.min(1, keepdims=True), 0, 255)
    cands = []
    for lo, hi in ((rgb.min(1), rgb.max(1)), (p_lo, p_hi)):
        (flo, clo), (fhi, chi) = _q565(lo), _q565(hi)
        cands += [(chi, flo), (fhi, clo), (chi, clo), (fhi, flo)]
    best_err = np.full(nb, np.inf, np.float32)
    best_e0 = np.zeros((nb, 3), np.float32); best_e1 = np.zeros((nb, 3), np.float32)
    best_idx = np.zeros((nb, 16), np.int64)
    for e0q, e1q in cands:
        e0, e1 = _dq565(e0q), _dq565(e1q)
        pal = np.stack([e0, e1, (2 * e0 + e1) / 3, (e0 + 2 * e1) / 3], 1)          # (nb, 4, 3)
        d = ((rgb[:, :, None, :] - pal[:, None, :, :]) ** 2).sum(-1)                  # (nb, 16, 4)
        idx = d.argmin(-1)
        err = np.take_along_axis(d, idx[..., None], -1)[..., 0].sum(-1)
        better = err < best_err
        best_err[better] = err[better]; best_e0[better] = e0q[better]; best_e1[better] = e1q[better]
        best_idx[better] = idx[better]
    c0 = (best_e0[:, 0].astype(np.uint16) << 11) | (best_e0[:, 1].astype(np.uint16) << 5) | best_e0[:, 2].astype(np.uint16)
    c1 = (best_e1[:, 0].astype(np.uint16) << 11) | (best_e1[:, 1].astype(np.uint16) << 5) | best_e1[:, 2].astype(np.uint16)
    cidx = (best_idx.astype(np.uint32) << (2 * np.arange(16, dtype=np.uint32))).sum(1).astype(np.uint32)
    # alpha: 8-alpha mode, a0 = max > a1 = min
    a0, a1 = alpha.max(1), alpha.min(1)
    apal = np.stack([a0, a1] + [((7 - i) * a0 + i * a1) / 7 for i in range(1, 7)], 1)  # (nb, 8)
    aidx = np.abs(alpha[:, :, None] - apal[:, None, :]).argmin(-1).astype(np.uint64)
    flat = a0 == a1
    aidx[flat] = 0
    abits = (aidx << (3 * np.arange(16, dtype=np.uint64))).sum(1).astype(np.uint64)
    out = np.zeros((nb, 16), np.uint8)
    out[:, 0] = a0.astype(np.uint8); out[:, 1] = a1.astype(np.uint8)
    for i in range(6):
        out[:, 2 + i] = ((abits >> np.uint64(8 * i)) & np.uint64(255)).astype(np.uint8)
    out[:, 8] = c0 & 255; out[:, 9] = c0 >> 8
    out[:, 10] = c1 & 255; out[:, 11] = c1 >> 8
    for i in range(4):
        out[:, 12 + i] = (cidx >> np.uint32(8 * i)) & 255
    return out.tobytes()


def encode_level(n, height):
    rgba = np.concatenate([n * 0.5 + 0.5, height[..., None]], axis=-1)
    u8 = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w = u8.shape[:2]
    ph, pw = (-h) % 4, (-w) % 4                       # 2x2 / 1x1 mips: pad to a whole block
    if ph or pw:
        u8 = np.pad(u8, ((0, ph), (0, pw), (0, 0)), mode='edge')
    return encode_bc3(u8)


def dds_header(w, h, mips):
    hd = bytearray(128)
    hd[0:4] = b'DDS '
    struct.pack_into('<7I', hd, 4, 124, 0x1 | 0x2 | 0x4 | 0x1000 | 0x20000 | 0x80000, h, w,
                     max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * 16, 0, mips)
    struct.pack_into('<2I4s5I', hd, 76, 32, 0x4, b'DXT5', 0, 0, 0, 0, 0)          # pixel format
    struct.pack_into('<I', hd, 108, 0x1000 | 0x8 | 0x400000)                         # TEXTURE | COMPLEX | MIPMAP
    return bytes(hd)


def write_dds(path, n, height, max_size):
    while n.shape[1] > max_size:                      # average down to the cap, renormalising
        n = downsample(n); height = downsample(height)
        n /= np.linalg.norm(n, axis=-1, keepdims=True)
    w, h = n.shape[1], n.shape[0]
    levels = []
    while True:
        levels.append(encode_level(n, height))
        if n.shape[0] == 1 and n.shape[1] == 1:
            break
        if n.shape[0] > 1 and n.shape[1] > 1:
            n = downsample(n); height = downsample(height)
        else:                                          # non-square tail
            n = n[::2, ::2] if n.shape[0] > 1 else n[:, ::2]; height = height[::2, ::2] if height.shape[0] > 1 else height[:, ::2]
        n /= np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-6)
    tmp = path + '.tmp'
    with open(tmp, 'wb') as f:
        f.write(dds_header(w, h, len(levels)))
        for lv in levels:
            f.write(lv)
    os.replace(tmp, path)


def lit_preview(rgb, n, light=(-0.55, -0.55, 0.63)):
    """Diffuse lit by a low light from the image's upper left (green = image down, so 'up' is -y)."""
    L = np.array(light, np.float32); L /= np.linalg.norm(L)
    d = np.clip((n * L).sum(-1), 0, 1)
    return np.clip(rgb * (0.35 + 0.9 * d[..., None]), 0, 1)


def process(job):
    tex1, a = job
    src = os.path.join(TEX, tex1)
    dst = os.path.join(TEX, normal_name(tex1))
    if not a['force'] and os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
        return tex1, 'skip'
    img = Image.open(src).convert('RGBA')
    rgb = np.asarray(img, np.float32)[..., :3] / 255
    n, height = make_normals(rgb, a['strength'], a['limit'])
    if a['preview']:
        flat = lit_preview(rgb, np.dstack([np.zeros_like(height), np.zeros_like(height), np.ones_like(height)]))
        lit = lit_preview(rgb, n)
        both = np.concatenate([flat, lit], axis=1)
        Image.fromarray((both * 255).astype(np.uint8)).save(
            os.path.join(a['preview'], os.path.splitext(tex1)[0] + '_preview.jpg'), quality=88)
    else:
        write_dds(dst, n, height, a['max'])
    return tex1, 'ok %dx%d' % (img.width, img.height)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--strength', type=float, default=5.0)
    ap.add_argument('--limit', type=float, default=0.3)
    ap.add_argument('--max', type=int, default=2048)
    ap.add_argument('--only', default='')
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--preview', default='')
    ap.add_argument('--force', action='store_true')
    a = vars(ap.parse_args())
    todo = texture_list()
    if a['only']:
        want = [w.lower() for w in a['only'].split(',')]
        todo = [t for t in todo if any(w in t.lower() for w in want)]
    if a['preview']:
        os.makedirs(a['preview'], exist_ok=True)
    print(len(todo), 'textures')
    with ProcessPoolExecutor(a['jobs']) as ex:
        for i, (t, r) in enumerate(ex.map(process, [(t, a) for t in todo])):
            if r != 'skip' or i % 50 == 0:
                print('%4d/%d %-50s %s' % (i + 1, len(todo), t, r), flush=True)


if __name__ == '__main__':
    main()
