--------------------------------------------------------------------------------
-- Settings: Interface tab. See LuaUI/widgets/gui_settings.lua for the fields.
--------------------------------------------------------------------------------

return {
	id = "ui", name = "Interface", order = 20,
	options = {
		{ type = "separator", name = "HUD" },
		{ id = "uiscale", name = "Interface size", type = "slider", min = 0.7, max = 1.5, step = 0.05, config = "ui_scale", default = 1,
		  format = "%.2f", applyOnRelease = true,
		  desc = "Scales every panel of the HUD.",
		  onSet = function() OPT.hud.UpdateScale() end },
		{ id = "enginetooltip", name = "Engine tooltip", type = "bool", store = true, default = false, applyOnLoad = true,
		  desc = "The engine's own text box in the bottom-left corner.",
		  onSet = function(v)
			Spring.SendCommands("tooltip " .. (v and 1 or 0))
			WG.thisEngineTooltipHidden = not v -- the chat panel sits lower while it is hidden
		  end,
		  onUnload = function()
			Spring.SendCommands("tooltip 1")
			WG.thisEngineTooltipHidden = nil
		  end },
		{ id = "simpleminimapcolors", name = "Simple minimap colours", type = "bool", config = "SimpleMiniMapColors", cmd = "minimap simplecolors %d",
		  desc = "Your units, allies and enemies each in one colour on the minimap." },

		{ type = "separator", name = "In the world" },
		{ id = "healthbars", name = "Health bars", type = "bool", widget = "HealthBars THIS", requires = "HealthBars THIS" },
		{ id = "formations", name = "Drag formations", type = "bool", widget = "Formations", requires = "Formations",
		  desc = "Drag a line while giving a move order to spread ships along it." },

		{ type = "separator", name = "Advanced" },
		{ id = "widgetlist", name = "Widget list", type = "action", button = "Open",
		  desc = "Turn individual widgets on and off.",
		  set = function()
			OPT.close()
			Spring.SendCommands("luaui selector")
		  end },
	},
}
