"""usage: preview.py model.s3o texdir out.png  -- renders the textured model from several angles/team colours"""
import sys, numpy as np
from PIL import Image
import s3o, render
m = s3o.load(sys.argv[1]); P, N, UV, T, TP, names = s3o.flatten(m)
t1 = np.array(Image.open(f'{sys.argv[2]}/{m.tex1}').convert('RGBA')); t2 = np.array(Image.open(f'{sys.argv[2]}/{m.tex2}').convert('RGBA'))
views = [(35, 32, (0.85, 0.12, 0.10)), (120, 12, (0.15, 0.35, 0.95)), (40, -30, (0.15, 0.75, 0.25)), (0, 89, (0.95, 0.75, 0.1))]
S = int(sys.argv[4]) if len(sys.argv) > 4 else 560
sheet = Image.new('RGB', (S * len(views), S))
for i, (az, el, tc) in enumerate(views):
    sheet.paste(render.render(P, N, UV, T, t1, t2, team=tc, az=az, el=el, size=S, ambient=0.22), (S * i, 0))
sheet.save(sys.argv[3])
