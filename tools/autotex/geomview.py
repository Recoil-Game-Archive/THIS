"""usage: geomview.py model.s3o out.png  -- untextured views of the model, one colour per piece (prints the piece names)"""
import sys, numpy as np, colorsys
from PIL import Image
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s3o, render
m = s3o.load(sys.argv[1]); P, N, UV, T, TP, names = s3o.flatten(m)
ids = sorted(set(TP)); pal = np.zeros((1, len(ids), 4), np.uint8)
for i, k in enumerate(ids):
    pal[0, i, :3] = [int(c * 255) for c in colorsys.hsv_to_rgb(i * 0.618 % 1, 0.35, 0.95)]; print(i, names[k], end='; ')
Pf = P[T].reshape(-1, 3); fn = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]]); fn /= np.linalg.norm(fn, axis=1)[:, None] + 1e-12
Nf = np.repeat(fn, 3, 0); UVf = np.zeros((len(Pf), 2)); UVf[:, 0] = (np.repeat([ids.index(k) for k in TP], 3) + 0.5) / len(ids); UVf[:, 1] = 0.5
Tf = np.arange(len(Pf)).reshape(-1, 3)
views = [(35, 30), (215, 25), (90, 5), (0, 89), (0, -89), (180, 10), (0, 10), (140, -30)]
S = 520; sheet = Image.new('RGB', (S * 4, S * 2))
for i, (az, el) in enumerate(views):
    sheet.paste(render.render(Pf, Nf, UVf, Tf, np.repeat(pal, 2, 0), None, az=az, el=el, size=S), (S * (i % 4), S * (i // 4)))
sheet.save(sys.argv[2])
