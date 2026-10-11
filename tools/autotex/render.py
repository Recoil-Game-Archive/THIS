"""Tiny software renderer for previewing textured S3O models (numpy z-buffer)."""
import numpy as np
from PIL import Image

def look(az, el, dist, target):
    az, el = np.radians(az), np.radians(el)
    eye = target + dist * np.array([np.cos(el) * np.sin(az), np.sin(el), np.cos(el) * np.cos(az)])
    f = target - eye; f /= np.linalg.norm(f)
    r = np.cross(f, [0, 1, 0]); r /= np.linalg.norm(r); u = np.cross(r, f)
    return eye, np.stack([r, u, -f])

def sample(tex, u, v):
    h, w = tex.shape[:2]
    x = (u % 1.0) * w - 0.5; y = (v % 1.0) * h - 0.5
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = (x - x0)[:, None]; fy = (y - y0)[:, None]
    g = lambda xx, yy: tex[yy % h, xx % w]
    return (g(x0, y0) * (1 - fx) + g(x0 + 1, y0) * fx) * (1 - fy) + (g(x0, y0 + 1) * (1 - fx) + g(x0 + 1, y0 + 1) * fx) * fy

def render(P, N, UV, T, tex1, tex2, team=(0.9, 0.1, 0.1), az=35, el=30, size=640, flip_v=True, fov=30,
           light=(0.5, 0.8, 0.4), ambient=0.35, bg=(8, 10, 18), ss=2):
    S = size * ss
    c = (P.min(0) + P.max(0)) / 2; rad = np.linalg.norm(P - c, axis=1).max()
    dist = rad / np.sin(np.radians(fov / 2)) * 1.05
    eye, R = look(az, el, dist, c)
    V = (P - eye) @ R.T
    f = 1 / np.tan(np.radians(fov / 2))
    sx = (V[:, 0] / -V[:, 2] * f * 0.5 + 0.5) * S; sy = (0.5 - V[:, 1] / -V[:, 2] * f * 0.5) * S; w = 1 / -V[:, 2]
    zb = np.full((S, S), -1.0); col = np.zeros((S, S, 3)) + np.array(bg) / 255
    L = np.array(light, float); L /= np.linalg.norm(L)
    t1 = np.asarray(tex1, float) / 255; t2 = np.asarray(tex2, float) / 255 if tex2 is not None else None
    team = np.array(team)
    for a, b, cc in T:
        x = sx[[a, b, cc]]; y = sy[[a, b, cc]]
        x0, x1 = int(max(np.floor(x.min()), 0)), int(min(np.ceil(x.max()), S - 1))
        y0, y1 = int(max(np.floor(y.min()), 0)), int(min(np.ceil(y.max()), S - 1))
        if x1 < x0 or y1 < y0: continue
        den = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
        if abs(den) < 1e-9: continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        l0 = ((y[1] - y[2]) * (gx - x[2]) + (x[2] - x[1]) * (gy - y[2])) / den
        l1 = ((y[2] - y[0]) * (gx - x[2]) + (x[0] - x[2]) * (gy - y[2])) / den
        l2 = 1 - l0 - l1
        m = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
        if not m.any(): continue
        ww = np.stack([l0 * w[a], l1 * w[b], l2 * w[cc]], -1); wsum = ww.sum(-1)
        sub = zb[y0:y1 + 1, x0:x1 + 1]; m &= wsum > sub
        if not m.any(): continue
        ww = ww[m] / wsum[m][:, None]
        uv = ww @ UV[[a, b, cc]]; n = ww @ N[[a, b, cc]]; n /= np.linalg.norm(n, axis=1)[:, None] + 1e-9
        v = 1 - uv[:, 1] if flip_v else uv[:, 1]
        s1 = sample(t1, uv[:, 0], v)
        base = s1[:, :3] * (1 - s1[:, 3:4]) + team * s1[:, 3:4]
        dif = np.clip(n @ L, 0, 1)[:, None]
        # view-space fill light so dark sides stay readable
        fill = np.clip(n @ (-R[2] * -1), 0, 1)[:, None] * 0.15
        emit = sample(t2, uv[:, 0], v)[:, 0:1] if t2 is not None else 0
        c3 = base * np.clip(ambient + dif * 0.9 + fill + emit, 0, 1.6)
        sub[m] = wsum[m]; col[y0:y1 + 1, x0:x1 + 1][m] = c3
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))
    return img.resize((size, size), Image.LANCZOS) if ss > 1 else img
