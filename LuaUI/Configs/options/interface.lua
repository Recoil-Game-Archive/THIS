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
		{ id = "uisounds", name = "Interface sounds", type = "bool", store = true, default = true, applyOnLoad = true,
		  desc = "Hover and click sounds on buttons and cards. Their volume is the Interface volume under Sound.",
		  onSet = function(v) WG.thisUiSoundsOff = not v end },
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
		{ id = "playerslist", name = "Players list", type = "bool", widget = "THIS Players List", requires = "THIS Players List",
		  desc = "Players, planets held and ping in the bottom-right corner." },
		{ id = "simpleminimapcolors", name = "Simple minimap colours", type = "bool", config = "SimpleMiniMapColors", cmd = "minimap simplecolors %d",
		  desc = "Your units, allies and enemies each in one colour on the minimap." },

		{ type = "separator", name = "In the world" },
		{ id = "healthbars", name = "Health bars", type = "bool", widget = "HealthBars THIS", requires = "HealthBars THIS" },
		{ id = "altitudelines", name = "Altitude lines", type = "bool", widget = "THIS Altitude Lines", requires = "THIS Altitude Lines",
		  desc = "A line from every ship down to the plane of the capture rings, with a small circle where it lands." },
		{ id = "commandlines", name = "Animated order lines", type = "bool", widget = "THIS Command Lines", requires = "THIS Command Lines",
		  desc = "Glowing lines with running lights for the orders of selected ships. Off: the engine's plain lines." },
		{ id = "formations", name = "Drag formations", type = "bool", widget = "Formations", requires = "Formations",
		  desc = "Drag a line while giving a move order to spread ships along it." },

		{ type = "separator", name = "Advanced" },
		{ id = "widgetlist", name = "Widget list", type = "action", button = "Open",
		  desc = "Turn individual widgets on and off.",
		  set = function()
			OPT.close()
			if WG.thisWidgetList then
				WG.thisWidgetList.Open()
			else
				Spring.SendCommands("luaui selector") -- the list widget is off
			end
		  end },
	},
}
