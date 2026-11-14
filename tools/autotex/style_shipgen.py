"""Generic ship paint: the fleet look driven by face direction and piece names, with a small per-ship config.
Used by the Eclipse, the Quasar and the two Gunstars (style_eclipse.py etc. call make(cfg)).
World axes: +z bow, +y up.

auto (small craft): a dict, possibly empty, that switches on the layout worked out from the hull's own shape --
spine (half-width of the team stripe as a fraction of the half-beam, 0 = none), tips (team colour outboard of this
fraction, 0 = none), canopy (start, end, half-width as fractions; None = none), eng_zone (rear-facing faces within
this fraction of the length from the stern are engine candidates), eng_min (keep candidates at least this fraction
of the largest), eng (lambda c: mask -- name the engine faces yourself when the guess is wrong).

cfg keys: k (feature scale, 1 = capital ship), plan (UV plan), eng_z (rear faces behind this z are engines),
nozzle=(cell, radius), team(c) -> mask of extra team-colour texels, team_pieces (name prefixes painted as team
panels), slate(c) -> mask, extra(c) -> None for anything else. c is a namespace of per-texel arrays."""
import numpy as np
from types import SimpleNamespace
from hullkit import *

def make(cfg):
    k = cfg.get('k', 1.0)
    def paint(F):
        P = Painter(F, k=k); pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']; pk = F['piece'] * 0
        name = np.array(F['names'])[F['piece']]; has = lambda s: np.char.find(name, s) >= 0; pre = lambda s: np.char.startswith(name, s)
        x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x)
        G = np.zeros(len(x), bool)
        for s in cfg.get('guns', ('barrel', 'sleeve', 'turret')): G |= has(s)
        for s in cfg.get('not_guns', ()): G &= ~pre(s)
        T = pre('torp'); TH = pre('thruster'); S = ~G & ~T
        top = nrm[:, 1] > 0.6; bot = nrm[:, 1] < -0.6; wall = ~top & ~bot; up = nrm[:, 1] > 0.8; side = np.abs(nrm[:, 1]) < 0.35
        rear = nrm[:, 2] < -0.7; fwd = nrm[:, 2] > 0.7
        h = np.hypot(nrm[:, 0], nrm[:, 2]) + 1e-9; t = x * (-nrm[:, 2] / h) + z * (nrm[:, 0] / h)
        big = (7.0 * k, 4.6 * k); small = (1.75 * k, 1.53 * k)
        P.hull(S & top, x, z, big=big, small=small, key=pk); P.hull(S & bot, x, z, tone=0.62, big=big, small=(3.5 * k, 3.06 * k), key=pk)
        P.hull(S & wall, t, y, tone=0.97, big=big, small=small)
        if cfg.get('round'):                                                       # cigar hulls: no per-facet edge lines
            for s in cfg['round']: P.noedge |= pre(s)
        c = SimpleNamespace(P=P, F=F, x=x, y=y, z=z, xa=xa, nrm=nrm, name=name, has=has, pre=pre, top=top, bot=bot, wall=wall, up=up, side=side, rear=rear, fwd=fwd,
                            t=t, a=a, b=b, dcv=dcv, S=S, k=k, pk=pk)
        # team colour
        if 'team' in cfg: P.paint_team(S & cfg['team'](c))
        for s in cfg.get('team_pieces', ()): P.paint_team(pre(s) & (dcv > 0.9 * k) & ~rear)
        if 'slate' in cfg: P.paint_slate(S & cfg['slate'](c))
        # windows along the walls, running lights
        wn = S & side & ~rear & ~TH & (dcv > 1.2 * k)
        if 'windows' in cfg: wn &= cfg['windows'](c)
        P.windows(wn, t, y, 1.5 * k, cfg.get('win_dens', 0.5), 7)
        P.lamp(S & side & ~rear & (np.abs((y / k) % 9.0 - 4.5) < 0.14) & (np.abs((t / k) % 12.0 - 6.0) < 0.2) & (dcv > 0.5 * k) & ~P.lock)
        # engines
        cell, rad = cfg.get('nozzle', (5.0 * k, 1.7 * k)); ez = cfg.get('eng_z', -1e9)
        eng = (S | TH) & rear & (z < ez)
        if 'engine' in cfg: eng &= cfg['engine'](c)
        P.nozzles(eng, x + cell / 2, y + cfg.get('nozzle_y', 0.0), cell, rad)
        P.mech(TH & ~rear & ~top, t, z, rib=1.4 * k, pipes=False)
        # bow sensors
        if cfg.get('bow_z') is not None:
            bw = S & fwd & (z > cfg['bow_z']); P.dark(bw, SLATE * 0.6); P.lamp(bw & (dcv > 0.5 * k) & (np.abs(((x / k) % 2.4) - 1.2) < 0.25) & (np.abs(((y / k) % 2.0) - 1.0) < 0.2), WINC, e=0.9, glow=0.5)
        # torpedoes: dark casings, red warheads
        if T.any():
            zt0 = np.array([F['bbox'][nm][0][2] for nm in F['names']])[F['piece']]; zt1 = np.array([F['bbox'][nm][1][2] for nm in F['names']])[F['piece']]; zl = (F['lpos'][:, 2] - zt0) / (zt1 - zt0 + 1e-9)
            P.dark(T, MECH * 1.25); P.noedge |= T; P.alb[T & (zl > 0.8)] = np.array([0.62, 0.10, 0.08]); P.alb[T & (np.abs(zl - 0.74) < 0.03)] = HAZ_Y * 0.9
            P.alb[T & (np.abs(zl - 0.3) < 0.02)] = LIGHT * 0.7; P.lamp(T & rear & (zl < 0.03), ENGINE, e=0.7, glow=0.5)
        if 'auto' in cfg:                                                        # small craft: layout worked out from the shape itself
            zs = z[S]; z0, z1 = zs.min(), zs.max(); L = z1 - z0; W = xa[S].max(); c.z0, c.z1, c.L, c.W = z0, z1, L, W
            au = cfg['auto'] if isinstance(cfg['auto'], dict) else {}
            sp = au.get('spine', 0.11); tp = au.get('tips', 0.7)
            if sp: P.paint_team(S & top & (xa < sp * W) & (z > z0 + 0.22 * L) & (z < z1 - au.get('spine_front', 0.32) * L))
            if tp: P.paint_team(S & top & (xa > tp * W))
            cn = au.get('canopy', (0.36, 0.17, 0.12))
            if cn:
                can = S & (nrm[:, 1] > 0.3) & (xa < cn[2] * W) & (z > z1 - cn[0] * L) & (z < z1 - cn[1] * L); P.dark(can, SLATE * 0.5); P.refl[can] = 0.5
                P.lamp(can & (np.abs(z - (z1 - (cn[0] + cn[1]) / 2 * L)) < 0.012 * L) & (xa < cn[2] * W * 0.6), WINC, e=0.9, glow=0.5)
            # engines: the big rear-facing faces at the stern, each glowing from its middle
            fk = F['facet']; u, inv = np.unique(fk, return_inverse=True); inr = np.zeros(len(u)); np.maximum.at(inr, inv, dcv); inr = inr[inv]
            rs = (S | TH) & (nrm[:, 2] < -0.8) & (z < z0 + au.get('eng_zone', 0.22) * L)
            if 'eng' in au: rs = (S | TH) & au['eng'](c)                             # explicit engine faces: a mask from the namespace c
            if rs.any():
                e = rs if 'eng' in au else rs & (inr >= au.get('eng_min', 0.45) * inr[rs].max()); P.dark(e, MECH * 0.9); core = np.clip((dcv / (inr + 1e-9) - 0.22) / 0.78, 0, 1); hot = e & (core > 0)
                P.alb[hot] = ENGINE[None] * (0.55 + 0.45 * core[hot])[:, None] + np.array([0.0, 0.25, 0.5])[None] * (core[hot] ** 3)[:, None]; P.emit[hot] = 1.0; P.glow[hot] = 1.0
            P.lamp(S & top & (xa > 0.93 * W) & (dcv > 0.05) & (np.abs(z - (z0 + z1) / 2) < 0.03 * L), RED, glow=0.6)
        if 'extra' in cfg: cfg['extra'](c)
        P.guns(G, cut=-1)
        return P.finish()
    return cfg['plan'], paint
