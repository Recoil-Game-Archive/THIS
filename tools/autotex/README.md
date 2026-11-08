# autotex — unwrap and texture S3O models procedurally

Most THIS models shipped with no UVs and `dummy.tga`. These scripts give a model a UV atlas and bake
a tex1/tex2 pair for it. Each unit has one file, `style_<unit>.py`, holding its UV plan and its paint job.

    pip install numpy pillow scipy xatlas trimesh embreex

    # 1. unwrap (always from the original, un-unwrapped model). Small ships: --res 1024 --padding 2
    python unwrap2.py original/starbase.s3o out/starbase.s3o style_starbase --res 2048 \
        --tex1 starbase.dds --tex2 starbase2.dds
    # 2. bake (tex1 2048, tex2 1024, 2x supersampled)
    python bake.py out/starbase.s3o style_starbase out --res 2048 --ss 2 --tex2-div 2
    # 3. look at it (add --close for close-ups)
    python preview.py out/starbase.s3o out preview.png 800

## UV plan (`UVPLAN` in the style file)

`unwrap2.py` spends texture space only where it buys detail:

* `sym {piece: k}` — the piece is k-fold symmetric about its Y axis; one sector is unwrapped and the others
  reuse it.
* `mirror {piece: 'x'}` — the piece is mirror-symmetric; one side is unwrapped, the other reuses it.
* `mirror_center` / `tol` — where the mirror plane sits and how far the halves may disagree and still share.
  Some of the old hulls are a few tenths of a unit off true symmetry (see `style_stealthcarrier.py`).
* Pieces that are copies of one another — identical, mirrored, flipped or shifted, even if triangulated
  differently — are detected and shared automatically.
* `unique(name, centroid, normal)` — keep a face out of the sharing. Needed under lettering, which would
  read backwards on the mirrored side.
* `unbend {piece: R0}` — a ring is unrolled so its arcs pack as straight strips.
* `planar [...]` — flat-faceted pieces: each coplanar facet is projected exactly, so there is no distortion.
  Anything else is charted by xatlas.
* `facet_angle {piece: deg}` — rounded pieces (a cigar fuselage, a dome) are charted in patches that grow over
  neighbouring faces within that angle, instead of one chart per flat face. `twin_tol` loosens how closely two
  pieces must agree to count as copies.
* `scale(name, centroid, normal)` — relative texel density per face (undersides lower, turrets higher).
* `occlusion True` — faces buried in crevices automatically get less texture space.

It writes `<model>.uvmeta.json` next to the output, which tells the baker which triangles own texels.
`unwrap.py` is the older plain xatlas unwrap without any of this.

## Paint (`paint(F)` in the style file)

`hullkit.py` holds the shared fleet look (panelled grey hull, slate stencils, team blocks, lit windows, running
lights, hazard stripes, engine nozzles, standard turret). A unit's style builds a `Painter`, lays those out over
its own geometry and returns `painter.finish()` — see `style_carrier.py`. The painter's `light`/`slate`/`edge_gain`
and the `base=` argument of `hull()` re-tint the kit (the stealth carrier runs it dark). (`style_starbase.py` predates the kit
and carries its own copy.)

`paint(F)` gets per-texel fields (world position, face normal, piece name, facet-local coords `a`/`b`,
distance to convex/concave facet edges `dcv`/`dcc`, ambient occlusion `ao`) and returns albedo, team-colour
mask, emission and reflectivity. Patterns are defined in model space, so they line up across UV seams.

Conventions: tex1 RGB = diffuse, A = team colour (fully opaque wherever team colour goes, otherwise it washes
out); tex2 R = glow, G = reflectivity. DDS is DXT5 with mipmaps, V flipped the way the engine expects for DDS.

## Giant hulls: tileset texturing (tiles.py, dice.py)

A hull the size of the Imperator (2245 units long, ten million square units of surface) would get about
1.3 texels per unit from a unique 4096 texture, against 12-18 for the rest of the fleet. For such hulls:

    python3 dice.py in.s3o out_dir style_module

`tiles.py` paints a sheet of 8x8 plating tiles (each covers 40 model units at 11.6 texels per unit, with a
wrapped gutter), and `dice.py` cuts every face along a 40-unit world lattice so that each cell shows one tile.
The style module supplies `TILES` and `tile_for(piece, centre, normal, axis, iu, iv, ao)`, which chooses the
tile and its rotation for each cell (lanes, pads, window walls, engines ...). The shape is unchanged; the
triangle count grows (Imperator: 640 -> 24k). There is no baked ambient occlusion in this mode.

## One command per unit (make.py)

    python make.py sword                 # unwrap + bake + check, into ./out
    python sheet.py out preview.png sword

`originals/` holds every model as it was before it was unwrapped; `make.py` always starts from those, picks
`style_<model>.py` and the `RES` it declares, and runs `check.py` at the end (geometry, normals and triangle
order identical to the original; UVs inside 0..1; mip levels sane; how much of the texture is team colour).
4096 textures are baked without supersampling (`--ss 1 --ao-step 2`) because the supersampled bake does not
fit in memory. A unit is not rebuilt bit-for-bit: the packer tries random layouts, so the atlas moves.

## Styles

* Hand-written, one per ship: `style_starbase`, `style_carrier`, `style_supportcarrier`, `style_stealthcarrier`,
  `style_comet`, `style_starslayer`, `style_meteor`, `style_minelayer`, `style_drone`.
* `style_shipgen.py` -- the same look driven by face direction and piece names, plus a small config per ship.
  Eclipse, Quasar and the Gunstars give it explicit team areas and engines; Dagger, Sword, Mace, Claymore,
  Wraith, Longbow, Warhammer, Iris (`probe`) and Crossbow (`dronelauncherk`) use its `auto` layout, which
  places the spine stripe, canopy and engines from the hull's shape. The automatic engine guess is the weak
  point: when it lights the wrong faces, set `eng_zone`, or name the faces with `eng=lambda c: ...`.
* `style_impmodule.py` -- the Imperator's pedestal, turrets, hangar and hive (`style_imp_*.py` are one-liners).
* `style_ordnance.py` -- torpedo and missile.
* `style_imperator.py` + `tiles.py` + `dice.py` -- the tileset hull described above.

More plan options: `twin_tol` (how far two pieces may differ and still share texels), `twin_loose` (fraction of
stray vertices allowed between near-identical mirrored pieces, e.g. the Quasar's fore hulls; faces without a
partner stay unique), `occlusion` (buried faces get less space), `scale(name, centroid, normal)` (density per face).
Painter helpers added since the first ships: `Painter(F, k=...)` scales every feature for small or giant hulls,
`exhaust(mask, distance, radius)` paints one modelled engine.

## Other tools

* `analyze.py model.s3o [piece ...]` -- symmetry report per piece, twin pieces, main faces by direction.
* `geomview.py model.s3o out.png` -- untextured views, one colour per piece. `s3otree.py model.s3o` -- piece tree.
* `sheet.py dir out.png model ...` -- preview sheet; `preview.py` -- single model straight from the DDS files.
* `check.py original.s3o dir model` -- the checks make.py runs.

The previews come from `render.py`, a plain software renderer. They show layout and colour, not what the
engine's shaders, mipmapping and lighting will do.
