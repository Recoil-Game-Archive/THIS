--  LuaUI/rml_setup.lua
--  RmlUi setup for THIS. Included once from LuaUI/main.lua; it replaces the
--  engine's base-content copy, which only loads a font and a cursor.
--
--  Based on the Recoil setup example by lov + ChrisFloofyKitsune
--  (Copyright (C) 2024, GNU GPL v2 or later).

if (RmlGuard or not RmlUi) then
	return
end
-- don't allow this initialization code to be run multiple times
RmlGuard = true

-- Fonts. Exo 2 is the HUD typeface (SIL Open Font License, see
-- LuaUI/Fonts/Exo2-OFL.txt). FreeMonoBold comes with the engine and is only a
-- fallback for glyphs Exo 2 does not have.
local fontFiles = {
	{"LuaUI/Fonts/Exo2-Regular.ttf", false},
	{"LuaUI/Fonts/Exo2-Bold.ttf", false},
	{"Fonts/FreeMonoBold.ttf", true},
}
for _, font in ipairs(fontFiles) do
	local ok, loaded = pcall(RmlUi.LoadFontFace, font[1], font[2])
	if not ok or loaded == false then
		Spring.Echo("[rml_setup] could not load font " .. font[1])
	end
end

-- Mouse cursor aliases: lets RCSS use the standard CSS cursor names.
RmlUi.SetMouseCursorAlias("default", 'cursornormal')
RmlUi.SetMouseCursorAlias("move", 'uimove')
RmlUi.SetMouseCursorAlias("nesw-resize", 'uiresized2')
RmlUi.SetMouseCursorAlias("nwse-resize", 'uiresized1')
RmlUi.SetMouseCursorAlias("ns-resize", 'uiresizev')
RmlUi.SetMouseCursorAlias("ew-resize", 'uiresizeh')

-- One shared context for every HUD document. Its dp_ratio (the size of one
-- "dp" in pixels) is set and kept up to date by LuaUI/rml/hud.lua.
RmlUi.CreateContext("shared")
