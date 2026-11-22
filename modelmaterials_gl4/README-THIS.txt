Custom Unit Shaders GL4 (CUS GL4)
=================================

From https://github.com/Spring-Helper-Projects/Custom-Unit-Shaders-GL4 (commit 5f5c4fc), by way of
Total Annihilation: Recoil's copy. Lua: GPL v2, shaders: MIT (LICENSE-CUS-GL4).

Files
  LuaRules/Gadgets/cus_gl4.lua, api_pbr_enabler.lua, Include/Gen*Lut.lua    the gadget
  LuaRules/Configs/cus_defs.lua            our settings (options per kind of unit, brightness)
  modelmaterials_gl4/                      shader templates and lookup textures
  modules/graphics/                        LuaShader and the instance buffer helpers (shared with the lights widget)
  unittextures/blank_normal.dds            normal map for models that have none
  unittextures/<texture 1>_normals.dds     generated normal maps (tools/textures/normalmaps.py)

Changes to the upstream code are marked "TA:Recoil" (made there, kept here) or "THIS":
  - OPTION_TEX2_SPECULAR: our texture 2 is a classic one (red = glow, green = reflectivity, blue unused). Read as
    PBR, blue 0 would make every ship a mirror. Glow stays; green sets metalness and roughness (THIS: glossier
    than TA: Recoil, for sleek hulls).
  - albedoFactor uniform and "/luarules unitbrightness <x>".
  - Without GL4 (headless, dedicated servers) the gadget removes itself.
  - THIS: a model's normal map is found by name, unittextures/<texture 1>_normals.dds (customParams.normaltex
    still wins).
  - THIS: cloaked ships are left to the engine, which draws them see-through.
  - THIS: no fog on units.

Dynamic lights (from Splinter Faction, by way of TA: Recoil)
  LuaUI/widgets/gfx_deferred_rendering_gl4.lua, api_unit_tracker_gl4.lua   the widgets
  LuaUI/shaders/deferred_lights_gl4.*.glsl
  LuaUI/Configs/DeferredLightsGL4config.lua           hand-made unit lights (none yet)
  LuaUI/Configs/DeferredLightsGL4unitLights.lua       GENERATED: tools/textures/unitlights.py
  LuaUI/Configs/DeferredLightsGL4WeaponsConfig.lua    weapon, muzzle and explosion lights by weapon type and colour
  LuaRules/Gadgets/gfx_explosion_lights.lua           tells the widget about shots and explosions
  LuaIntro/Addons/this_graphics_settings.lua          switches on AllowDeferredMapRendering/ModelRendering
  - THIS: the space maps draw no ground, so the map depth buffer stays 0; the light shaders read that as
    "nothing there" (it hid every light).
  - THIS: lights also work below water level (VOIDWATER = 0).

After changing a model or its textures
  python3 tools/textures/normalmaps.py     normal maps for new or changed textures (--force: all)
  python3 tools/textures/unitlights.py     the unit lights table

In game
  Settings > Graphics > Ships: detailed ship shading, ship brightness, dynamic lights
  /luarules disablecusgl4, /luarules reloadcusgl4, /luarules unitbrightness <0.25-3>

Testing: tools/visual-test/run.sh runs the game in the Windows engine from WSL and takes screenshots.
