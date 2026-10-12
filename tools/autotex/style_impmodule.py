"""Imperator modules: the hardpoint pedestal and the gun turrets that mount on it. One shared paint routine with a
few per-model details; each model has a thin style_imp_<kind>.py that calls make(kind). 1024 main texture each.
World axes: +z is where the gun points, +y up. Every model is mirror-symmetric in x."""
import numpy as np
from hullkit import *

KINDS = dict(
    hardpoint=dict(sym={'body': 4}, planar=['body']),
    turret_am=dict(mirror={'body': 'x', 'extra': 'x'}, facet_angle={'body': 20, 'extra': 30}, planar=['body', 'extra']),
    turret_cannon=dict(mirror={'foot': 'x', 'turret_1': 'x', 'sleeve_1': 'x', 'barrel_1': 'x'}, planar=['foot', 'turret', 'sleeve', 'barrel'], facet_angle={'barrel_1': 40, 'barrel_2': 40, 'sleeve_1': 40}),
    turret_pd=dict(mirror={'body': 'x'}, planar=['body', 'barrel'], facet_angle={'body': 20, 'barrel_1': 40, 'barrel_2': 40, 'barrel_3': 40}),
    turret_plasma=dict(mirror={'foot': 'x', 'turret_1': 'x', 'barrel_1': 'x'}, planar=['foot', 'turret', 'barrel'], facet_angle={'barrel_1': 30}),
    hangar=dict(mirror={'body': 'x'}, planar=['body']),
    hive=dict(sym={'body': 3}, planar=['body'], tol={'body': 0.05}),
    turret_plasma2=dict(mirror={'body': 'x', 'barrel_1': 'x'}, planar=['body', 'barrel'], facet_angle={'barrel_1': 30}),
)

def make(kind):
    def _scale(name, c, n):
        if 'barrel' in name or 'sleeve' in name or name in ('turret_2', 'extra'): return 1.25
        if n[1] < -0.9: return 0.5
        return 1.0
    plan = dict(KINDS[kind], scale=_scale, occlusion=True, maxlen=120.0)

    def paint(F):
        P = Painter(F); pos = F['pos']; nrm = F['nrm']; a, b, dcv = F['a'], F['b'], F['dcv']
        name = np.array(F['names'])[F['piece']]; has = lambda s: np.char.find(name, s) >= 0; pk = F['piece'] * 0
        x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]; xa = np.abs(x)
        G = has('barrel') | has('sleeve') | (name == 'turret_2'); X = name == 'extra'; S = ~G & ~X
        up = nrm[:, 1] > 0.8; down = nrm[:, 1] < -0.8; side = np.abs(nrm[:, 1]) < 0.35; slant = ~up & ~down & ~side
        h = np.hypot(nrm[:, 0], nrm[:, 2]) + 1e-9; t = x * (-nrm[:, 2] / h) + z * (nrm[:, 0] / h)        # coordinate running round the walls
        lo = np.array([F['bbox'][nm][0][1] for nm in F['names']])[F['piece']]; hi = np.array([F['bbox'][nm][1][1] for nm in F['names']])[F['piece']]
        yn = (y - lo) / (hi - lo + 1e-9)                                                             # height within the piece, 0..1
        P.hull(S & up, x, z, key=pk); P.hull(S & down, x, z, tone=0.62, small=(3.5, 3.06), key=pk)
        P.hull(S & side, t, y, key=pk); P.hull(S & slant, a, b, tone=0.96)

        if kind == 'hardpoint':
            top = S & up; r = np.hypot(x, z); P.dark(top, DECK * 0.72); P.ring(top, x, z, 22.0, w=2.2)
            P.paint_team(top & (np.maximum(xa, np.abs(z)) > 27.0) & (np.maximum(xa, np.abs(z)) < 29.0)); P.lamp(top & (np.hypot(xa - 27, np.abs(z) - 27) < 1.0), RED)
            P.dark(S & slant, DECK * 0.8); P.hazard(S & slant & (y < -9.2), t, y * 1.3, 1.1); P.paint_slate(S & slant & (y > -3.4) & (y < -2.2))
            P.paint_team(S & side & (y < -15) & (y > -22)); P.paint_slate(S & side & (y < -23.2) & (y > -24.6))
            P.windows(S & side & (y < -30) & (y > -92) & (np.abs(t) < 38), t, y, 2.2, 0.55, 3, key=pk)
            P.lamp(S & side & (np.abs(y + 27) < 0.35) & (np.abs((t % 11.0) - 5.5) < 0.5) & (np.abs(t) < 40))
            P.mech(S & side & (y < -97), t, y, rib=1.6, pipes=False)
        else:
            house = S & ((name == 'turret_1') | (name == 'body'))                                    # the rotating housing
            roof = house & up & (yn > 0.7)
            P.paint_team(roof & (dcv > 3.2)); P.paint_slate(roof & (dcv > 5.4) & (dcv < 6.6) & (((z + 0.3) % 2.6) < 1.5))
            P.paint_team(house & slant & (nrm[:, 1] > 0.3) & (np.abs(nrm[:, 0]) > 0.4) & (dcv > 1.8) & (dcv < 4.6) & ((kind != 'hive') | (y > 62)))
            wall = house & side & (dcv > 1.4) & (np.abs(nrm[:, 2]) < 0.6)
            P.windows(wall & (yn > 0.3) & (yn < 0.75), t, y, 2.0, 0.6, 5, key=pk)
            P.lamp(house & side & (np.abs(yn - 0.86) < 0.02) & (np.abs((t % 9.0) - 4.5) < 0.45) & (dcv > 0.8))
            rearw = house & side & (nrm[:, 2] < -0.7) & (dcv > 2.0); P.mech(rearw & (yn > 0.25) & (yn < 0.7), t, y, rib=1.3, pipes=True)
            P.dark(S & down, MECH * 0.9)
            foot = S & (name == 'foot')
            P.paint_team(foot & side & (yn > 0.80) & (yn < 0.90)); P.dark(foot & side & (yn < 0.07), MECH)
            P.hazard(foot & slant & (nrm[:, 1] > 0.3) & (dcv < 1.8), a, b, 0.9)
            P.lamp(foot & side & (np.abs(yn - 0.5) < 0.025) & (np.abs((t % 10.0) - 5.0) < 0.5) & (dcv > 1.0), AMBER)
            if kind == 'turret_am':                                                                  # emitter dish on the front, pods on the flanks, lens on the roof
                small = F['fcen'] is not None
                rd = np.hypot(x, y - 41.2); dish = S & (z > 24.5) & (rd < 21.5) & (nrm[:, 2] > 0.05)
                P.dark(dish, MECH * 0.8); rings = dish & (np.abs((rd % 5.0) - 2.5) < 0.55); P.lamp(rings, WINC, e=0.9, glow=0.7)
                P.lamp(dish & (rd < 4.0), np.array([0.85, 0.95, 1.0]), glow=1.0)
                pod = S & (xa > 30) & (z > 8) & (z < 18) & (np.abs(y - 24) < 7) & (np.abs(nrm[:, 0]) + np.abs(nrm[:, 2]) > 0.2) & ~up & ~down
                P.lamp(pod & (np.hypot(y - 24.2, z - 13) < 3.2), WINC, glow=0.8)
                P.dark(X, SLATE * 0.6); P.lamp(X & (np.hypot(x, z + 2) < 4.5) & (nrm[:, 1] > 0.3), WINC, glow=0.8); P.noedge |= X
            if kind == 'turret_pd':                                                                  # three muzzle cones on the nose
                nose = S & (z > 25.5) & (nrm[:, 2] > 0.2); P.dark(nose, MECH * 1.15)
            if kind in ('turret_plasma', 'turret_plasma2'):                                         # hot plasma coils in the barrel cluster
                B = has('barrel'); zb = F['lpos'][:, 2]
        if kind == 'hangar':                                                                        # open shed: lit bay inside, landing apron in front
            floor = S & up & (np.abs(y - 2) < 0.6); inw = S & side & (nrm[:, 0] * x < -0.5) & (xa < 35) & (y > 2); back = S & (nrm[:, 2] > 0.7) & (np.abs(z + 17) < 1); ceil = S & down & (y > 20)
            P.dark(floor, DECK * 0.75); P.hazard(floor & ((dcv < 1.6) & (z > 40)), x, z, 1.0)
            for cx in (-20.2, 20.2):                                                                  # two bay lanes
                P.paint_team(floor & (np.abs(np.abs(x - cx) - 9.5) < 0.45) & (z < 62) & (((z + 1.0) % 6.0) < 4.0))
                P.lamp(floor & (np.abs(x - cx) < 0.35) & (np.abs(((z + 1.5) % 5.0) - 2.5) < 0.5) & (z < 70), WINC, glow=0.6)
            P.dark(inw, MECH * 1.5); P.lamp(inw & (np.abs(y - 17) < 0.5) & (((z + 1.0) % 4.0) < 2.6), AMBER, e=0.9, glow=0.8); P.hazard(inw & (z > 60), z, y, 0.9)
            P.dark(back, MECH * 1.3); g = np.minimum(np.abs(((x + 1.6) % 3.2) - 1.6), np.abs(((y + 1.3) % 2.6) - 1.3)); bay = back & (np.abs(xa - 20.2) < 9.5) & (y > 5) & (y < 21)
            P.alb[bay] = AMBER * (0.35 + 0.3 * (g[bay] > 0.18))[:, None]; P.emit[bay] = 0.6; P.glow[bay] = 0.5; P.team[bay] = 0; P.lock[bay] = True
            P.dark(ceil, MECH * 1.2); P.lamp(ceil & (np.abs(((x + 2.5) % 5.0) - 2.5) < 0.4) & (np.abs(((z + 3.0) % 6.0) - 3.0) < 1.6), WIN, e=0.9, glow=0.8)
            P.lamp(S & (nrm[:, 2] > 0.7) & (z > 38) & (y > 27) & (np.abs(((x + 2.0) % 4.0) - 2.0) < 0.5) & (np.abs(y - 30.5) < 0.5), RED)
        if kind == 'hive':                                                                          # drone cells: dark bores glowing from inside, team collars
            cells = [(0.0, 12.9, 6.3), (-5.3, 12.9, -3.2), (5.3, 12.9, -3.2), (0.0, 26.7, -6.4), (-5.3, 26.7, 3.1), (5.3, 26.7, 3.1),
                     (0.0, 40.2, 6.3), (-5.3, 40.2, -3.2), (5.3, 40.2, -3.2), (0.0, 53.9, -6.4), (-5.3, 53.9, 3.1), (5.3, 53.9, 3.1)]
            mid = S & (y > 4.5) & (y < 62.5)
            for cx, cy, cz in cells:
                r0 = np.hypot(cx, cz); dx, dz = cx / r0, cz / r0; al = x * dx + z * dz; pr = np.hypot(x * dz - z * dx, y - cy); fo = nrm[:, 0] * dx + nrm[:, 2] * dz
                nd = (nrm[:, 0] * (x - al * dx) + nrm[:, 1] * (y - cy) + nrm[:, 2] * (z - al * dz)) / (pr + 1e-6)
                inner = mid & (pr < 9.0) & (nd < -0.4) & (al > 4)
                P.dark(inner, MECH * 0.75); P.lamp(inner & (np.abs(((al + 0.8) % 3.2) - 1.6) < 0.22), np.array([0.3, 0.95, 0.5]), e=0.8, glow=0.6)
                backw = mid & (fo > 0.5) & (pr < 5.0) & (al > 2) & (al < 12); P.dark(backw, MECH * 0.6); P.lamp(backw & (pr < 2.6), np.array([0.35, 1.0, 0.55]), e=0.9, glow=0.9)

            core = mid & (np.hypot(x, z) < 9.5) & side; P.dark(core, MECH * 1.3)
            P.lamp(core & (np.abs(((y + 1.0) % 6.9) - 3.45) < 0.3), AMBER, e=0.6, glow=0.4)
            P.dark(S & down & (y > 60), MECH); P.paint_team(S & (y < 4.2) & side & (np.abs(y - 2.1) < 0.9))
        P.guns(G, cut=-1)
        if kind in ('turret_plasma', 'turret_plasma2'):
            B = has('barrel'); zm = np.array([F['bbox'][nm][1][2] for nm in F['names']])[F['piece']]; z0 = np.array([F['bbox'][nm][0][2] for nm in F['names']])[F['piece']]
            zl = (F['lpos'][:, 2] - z0) / (zm - z0 + 1e-9)
            P.lamp(B & (zl > 0.2) & (zl < 0.5) & (np.abs(((zl * 10) % 1.0) - 0.5) < 0.09) & (np.abs(nrm[:, 2]) < 0.5), np.array([0.25, 0.9, 0.5]), e=0.8, glow=0.5)
            P.lamp(B & (nrm[:, 2] > 0.9) & (zl > 0.97), np.array([0.6, 1.0, 0.75]), glow=1.0)
        if kind == 'turret_cannon':
            B = name == 'barrel_1'; P.lamp(B & (nrm[:, 2] > 0.9) & (F['lpos'][:, 2] > 68.5) & (np.hypot(F['lpos'][:, 0], F['lpos'][:, 1] + 0.5) < 1.6), AMBER, e=0.7, glow=0.5)
        return P.finish()
    return plan, paint
