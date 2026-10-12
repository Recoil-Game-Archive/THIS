"""usage: make.py model [model ...] [--out DIR] [--res N] [--tries N]
Rebuild a unit from its original model: unwrap, bake, check. e.g.  python make.py sword torpedo
Reads originals/<model>.s3o, uses style_<model>.py (see STYLE for the exceptions) and the RES it declares,
and writes <out>/<model>.s3o, the two DDS textures and PNG copies. Copy the .s3o to objects3d/, the .dds
files to unittextures/ and the .uvmeta.json next to the styles when you are happy with sheet.py's preview."""
import sys, os, argparse, importlib, subprocess
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
STYLE = {'dronek': 'style_drone', 'imperator': 'style_imperator'}                       # default: style_<model>, or style_imp_<x> for imperator_<x>
TEX = {'imperator_turret_plasma2': ('imperator_turret_plasma2_1.dds', 'imperator_turret_plasma2_2.dds')}   # default: <model>.dds, <model>2.dds
def style_of(n): return STYLE.get(n) or ('style_imp_' + n[len('imperator_'):] if n.startswith('imperator_') else 'style_' + n)
def run(*c):
    print('>', ' '.join(c), flush=True); subprocess.run([sys.executable, *c], cwd=HERE, check=True)
if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('models', nargs='+'); ap.add_argument('--out', default='out'); ap.add_argument('--res', type=int); ap.add_argument('--tries', type=int, default=8)
    a = ap.parse_args(); out = os.path.abspath(a.out); os.makedirs(out, exist_ok=True)
    for n in a.models:
        src = f'{HERE}/originals/{n}.s3o'; st = style_of(n)
        if n == 'imperator':                                                              # tileset hull: no unwrap or bake
            run('dice.py', src, out, st); continue
        res = a.res or getattr(importlib.import_module(st), 'RES', 2048); t1, t2 = TEX.get(n, (n + '.dds', n + '2.dds'))
        run('unwrap2.py', src, f'{out}/{n}.s3o', st, '--res', str(res), '--pack-tries', str(a.tries), '--tex1', t1, '--tex2', t2)
        big = res >= 4096                                                                 # 4096 does not fit in memory supersampled
        run('bake.py', f'{out}/{n}.s3o', st, out, '--res', str(res), '--ss', '1' if big else '2', '--rays', '48', '--tex2-div', '2', *(['--ao-step', '2'] if big else []))
        if n not in TEX: run('check.py', src, out, n)
