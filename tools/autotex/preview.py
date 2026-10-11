"""usage: preview.py model.s3o texdir out.png [size] [--close]  -- renders the textured model from several angles/team colours"""
import sys, numpy as np
from PIL import Image
import s3o, render
m = s3o.load(sys.argv[1]); P, N, UV, T, TP, names = s3o.flatten(m)
ld = lambda n: np.array(Image.open(f'{sys.argv[2]}/{n.rsplit(".", 1)[0]}.png').convert('RGBA'))
t1 = ld(m.tex1); t2 = ld(m.tex2)
S = int(sys.argv[4]) if len(sys.argv) > 4 else 560
views = [dict(az=35, el=32, team=(0.85, 0.12, 0.10)), dict(az=120, el=12, team=(0.15, 0.35, 0.95)), dict(az=40, el=-30, team=(0.15, 0.75, 0.25)), dict(az=0, el=89, team=(0.95, 0.75, 0.1))]
if '--close' in sys.argv:
    c = (P.min(0) + P.max(0)) / 2
    views = [dict(az=20, el=35, team=(0.85, 0.12, 0.10), zoom=3.2, target=(0, 6, 0)), dict(az=150, el=40, team=(0.15, 0.35, 0.95), zoom=3.0, target=(-55, 4, 0)),
             dict(az=100, el=5, team=(0.15, 0.75, 0.25), zoom=3.0, target=(0, -44, 0)), dict(az=0, el=89, team=(0.95, 0.75, 0.1), zoom=2.4, target=(28, 4, 40))]
sheet = Image.new('RGB', (S * 2, S * 2))
for i, v in enumerate(views):
    sheet.paste(render.render(P, N, UV, T, t1, t2, size=S, ambient=0.22, **v), (S * (i % 2), S * (i // 2)))
sheet.save(sys.argv[3])
