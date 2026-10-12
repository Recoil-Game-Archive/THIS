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
