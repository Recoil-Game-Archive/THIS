"""usage: sheet.py dir out.png model [model ...] [--zoom Z] [--size N]
One row per model, four views each (front quarter, rear quarter, top, side) in four team colours. Reads
<dir>/<model>.s3o and the PNG copies of its textures that bake.py / dice.py write next to the DDS files.
This is a plain software renderer: a guide to the layout, not what the engine will show."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import argparse, numpy as np
from PIL import Image
import s3o, render
ap = argparse.ArgumentParser(); ap.add_argument('dir'); ap.add_argument('out'); ap.add_argument('models', nargs='+'); ap.add_argument('--zoom', type=float); ap.add_argument('--size', type=int, default=600)
a = ap.parse_args()
R = (0.85, 0.12, 0.10); B = (0.15, 0.35, 0.95); G = (0.15, 0.75, 0.25); Y = (0.95, 0.75, 0.1)
views = [dict(az=30, el=25, team=R), dict(az=210, el=28, team=B), dict(az=0, el=89, team=Y), dict(az=75, el=8, team=G)]
Sz = a.size; sheet = Image.new('RGB', (Sz * len(views), Sz * len(a.models)))
for j, name in enumerate(a.models):
    m = s3o.load(f'{a.dir}/{name}.s3o'); P, N, UV, T, TP, nm = s3o.flatten(m)
    ld = lambda n: np.array(Image.open(f'{a.dir}/{n.rsplit(".", 1)[0]}.png').convert('RGBA'))
    t1 = ld(m.tex1); t2 = ld(m.tex2)
    for i, v in enumerate(views):
        if a.zoom: v = dict(v, zoom=a.zoom)
        sheet.paste(render.render(P, N, UV, T, t1, t2, size=Sz, ambient=0.22, **v), (Sz * i, Sz * j))
sheet.save(a.out)
