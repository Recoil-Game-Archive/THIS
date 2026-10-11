# autotex — unwrap and texture S3O models procedurally

Most THIS models shipped with no UVs and `dummy.tga`. These scripts give a model a UV atlas and bake
a tex1/tex2 pair for it.

    pip install numpy pillow scipy xatlas trimesh embreex

    # 1. unwrap (identical pieces such as repeated turrets share UV space; --boost gives pieces more texels)
    python unwrap.py ../../objects3d/starbase.s3o out/starbase.s3o --boost turret:1.6 barrel:1.6 \
        --tex1 starbase.dds --tex2 starbase2.dds
    # 2. bake textures using a style module (style_<unit>.py, a paint(F) function)
    python bake.py out/starbase.s3o style_starbase out
    # 3. look at it
    python preview.py out/starbase.s3o out preview.png

`paint(F)` gets per-texel fields (world position, face normal, piece name, facet-local coords `a`/`b`,
distance to convex/concave facet edges `dcv`/`dcc`, ambient occlusion `ao`) and returns albedo, team-colour
mask, emission and reflectivity. Patterns are defined in model space, so they line up across UV seams.

Texture conventions: tex1 RGB = diffuse, A = team colour; tex2 R = glow, G = reflectivity.
DDS is written as DXT5 with mipmaps, V flipped the way the engine expects for DDS (matches sword.dds).
