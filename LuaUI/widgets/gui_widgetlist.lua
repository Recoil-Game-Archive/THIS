--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Widget list of the RmlUi HUD. Opened from Settings > Interface, it lists
--  every widget the game knows with an on/off switch, the game's own widgets
--  and the player's own ones on separate tabs. Switching a widget on loads
--  it at once; the choice is saved by the widget handler as usual.
--
--  Takes the place of the engine's /luaui selector window, and of its F11
--  key: F11 opens and closes this list instead.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Widget List",
		desc = "Widget list window with on/off switches",
		author = "THIS contributors",
		date = "2026-10-13",
		license = "GNU GPL, v2 or later",
		layer = 90,      -- sees Esc before the game menu
		handler = true,  -- the real widgetHandler, to switch widgets on and off
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/widgetlist.rml"
local UPDATE_INTERVAL = 0.5
local KEY_ESCAPE = 27
local keyF11
-- the engine's own selector window; this one replaces it
local HIDDEN_BASENAMES = {["selector.lua"] = true}

local hud
local document
local view
local lastUpdate
local open = false
local currentTab = 1
local rows = {}          -- row number -> widget name
local shownList          -- the markup last written, to skip rewrites
local accentTeam, accentColour

local OFF_COLOUR = "rgba(255, 255, 255, 40)"

--------------------------------------------------------------------------------

-- true: running; "half": switched on but not running; false: off
local function State(name, known)
	if known.active then
		return true
	end
	local order = widgetHandler.orderList and widgetHandler.orderList[name]
	if order and order > 0 then
		return "half"
	end
	return false
end

local function Listed()
	local list = {}
	for name, known in pairs(widgetHandler.knownWidgets or {}) do
		if not HIDDEN_BASENAMES[known.basename or ""] then
			local fromGame = known.fromZip and true or false
			if currentTab == 1 or (currentTab == 2) == fromGame then
				list[#list + 1] = {name = name, known = known, fromGame = fromGame}
			end
		end
	end
	table.sort(list, function(a, b)
		if a.fromGame ~= b.fromGame then
			return a.fromGame
		end
		return a.name:lower() < b.name:lower()
	end)
	return list
end

local function BuildList()
	local list = Listed()
	rows = {}
	local rml = {}
	local lastGroup
	local running, total = 0, 0
	for _, entry in ipairs(list) do
		local group = entry.fromGame and "GAME" or "YOURS"
		if currentTab == 1 and group ~= lastGroup then
			rml[#rml + 1] = '<div class="sep label">' .. group .. '</div>'
			lastGroup = group
		end
		local n = #rows + 1
		rows[n] = entry.name
		local state = State(entry.name, entry.known)
		total = total + 1
		if state == true then
			running = running + 1
		end
		local desc = entry.known.desc and entry.known.desc ~= "" and ('<div class="row-desc">' .. hud.Escape(entry.known.desc) .. '</div>') or ""
		local author = entry.known.author and entry.known.author ~= "" and ('<div class="row-author">' .. hud.Escape(entry.known.author) .. '</div>') or ""
		rml[#rml + 1] = string.format(
			'<div class="row%s" data-row="%d"><div class="row-text"><div class="row-name">%s</div>%s%s</div>' ..
			'<div id="tog-%d" class="toggle%s%s" data-row="%d"><div class="knob"/></div></div>',
			state == false and " off" or "", n, hud.Escape(entry.name), desc, author,
			n, state ~= false and " on" or "", state == "half" and " half" or "", n)
	end
	if #rows == 0 then
		rml[#rml + 1] = '<div id="empty">No widgets here.</div>'
	end
	local text = table.concat(rml)
	if text ~= shownList then
		shownList = text
		view.Forget()
		view.Element("list").inner_rml = text
		for n = 1, #rows do
			local state = State(rows[n], widgetHandler.knownWidgets[rows[n]])
			view.SetStyle("tog-" .. n, "background-color", state == true and accentColour or (state == "half" and "#f2b84b" or OFF_COLOUR))
		end
	end
	view.SetText("count", running .. " of " .. total .. " running")
	for i = 1, 3 do
		view.SetClass("tab-" .. i, "active", i == currentTab)
		view.SetStyle("tab-" .. i, "border-bottom-color", (i == currentTab) and accentColour or "rgba(0, 0, 0, 0)")
	end
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"widgets-accent", "close"})
		view.ForgetStyles()
		shownList = nil
	end
	view.SetClass("widgets", "hidden", not open)
	view.SetClass("backdrop", "hidden", not open)
	if open then
		BuildList()
	end
end

local function SetOpen(state)
	open = state
	if open then
		shownList = nil
		pcall(function() document:PullToFront() end)
	end
	Refresh()
end

--------------------------------------------------------------------------------

local function OnListMouseDown(event)
	if not (event.parameters and event.parameters.button == 0) then
		return
	end
	local n = hud.EventAttribute(event, "data-row")
	local name = n and rows[n]
	if not name then
		return
	end
	local known = widgetHandler.knownWidgets[name]
	if State(name, known) == false then
		widgetHandler:EnableWidget(name)
	else
		widgetHandler:DisableWidget(name)
	end
	if document then -- this widget may have switched itself off
		Refresh()
	end
end

local function OnClick(id, handler)
	view.Element(id):AddEventListener("mousedown", function(event)
		if event.parameters and event.parameters.button == 0 then
			handler()
		end
	end)
end

function widget:Initialize()
	if not RmlUi then
		widgetHandler:RemoveWidget(widget)
		return
	end
	hud = include("rml/hud.lua")
	local context = hud.UpdateScale()
	if not context then
		widgetHandler:RemoveWidget(widget)
		return
	end
	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Widget List] could not load " .. DOCUMENT_PATH .. "", ok and "" or result)
		widgetHandler:RemoveWidget(widget)
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("widgets", "hidden", true)
	view.Assume("backdrop", "hidden", true)
	view.Assume("tab-1", "active", true)
	accentTeam = Spring.GetLocalTeamID()
	accentColour = hud.ApplyAccent(document, accentTeam, {}, {"widgets-accent", "close"})

	view.Element("list"):AddEventListener("mousedown", OnListMouseDown)
	view.Element("tabs"):AddEventListener("mousedown", function(event)
		if not (event.parameters and event.parameters.button == 0) then
			return
		end
		local index = hud.EventAttribute(event, "data-tab")
		if index and index >= 1 and index <= 3 and index ~= currentTab then
			currentTab = index
			shownList = nil
			view.Element("list").scroll_top = 0
			Refresh()
		end
	end)
	OnClick("close", function() SetOpen(false) end)
	OnClick("backdrop", function() SetOpen(false) end)
	OnClick("reload", function() Spring.SendCommands("luaui reload") end)

	WG.thisWidgetList = {
		Open = function() SetOpen(true) end,
		Close = function() SetOpen(false) end,
		IsOpen = function() return open end,
	}
	keyF11 = Spring.GetKeyCode and Spring.GetKeyCode("f11") or nil
	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
end

function widget:Shutdown()
	WG.thisWidgetList = nil
	if document then
		document:Close()
		document = nil
	end
end

function widget:ViewResize()
	if hud then
		hud.UpdateScale()
	end
end

function widget:KeyPress(key, mods, isRepeat)
	if not document or isRepeat then
		return false
	end
	if key == keyF11 and not (mods.alt or mods.ctrl or mods.meta or mods.shift) then
		SetOpen(not open)
		return true -- consumed: the engine's own selector is not opened
	end
	if open and key == KEY_ESCAPE then
		SetOpen(false)
		return true
	end
	return false
end

function widget:Update()
	if not document then
		return
	end
	if hud.FollowGuiHidden(document) or not open then
		return
	end
	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end
