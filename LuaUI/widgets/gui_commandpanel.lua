--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Selection and command panel of the RmlUi HUD.
--
--  Replaces the engine's command menu. For the current selection it shows
--    * what is selected and its health,
--    * every order and setting the selection has, with its hotkey,
--    * for carriers, minelayers, hangars and Imperator hardpoints: the things
--      they can build, with cost, queued count and progress, and the queue of
--      a single selected builder.
--
--  The orders are the engine's own command descriptions
--  (Spring.GetActiveCmdDescs) and a click is passed back with
--  Spring.SetActiveCommand, exactly as a click on the engine menu would be, so
--  modifier keys behave the same: Shift queues or builds five, right-click on
--  a build card cancels one, Alt puts a build at the front.
--
--  The engine menu is hidden with the "dummy" layout handler while this widget
--  runs and restored when it stops. Hotkeys are unaffected.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Command Panel",
		desc = "Selection, orders and production (replaces the engine command menu)",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/commandpanel.rml"
local UPDATE_INTERVAL = 0.1

local CMD_BUILD = 31000        -- build.locals.lua: build command = CMD_BUILD + unitDefID
local CMD_BUILD_MAX = 32000
local MAX_HEALTH_UNITS = 300   -- units summed for the health bar
local MAX_TYPE_CHIPS = 6
local MAX_QUEUE_PICS = 14

-- orders that stay off the panel (their hotkeys still work)
local hiddenOrders = {
	[CMD.SELFD] = true,
}

local hud
local document
local view
local lastUpdate
local dirty = true

local shownSignature     -- which commands the panel was last built for
local orders = {}        -- list of {index=, id=} as shown
local builds = {}        -- list of {index=, id=, def=, cost=}
local buildIndexByDef = {}
local hoverIndex
local accentTeam, accentColour

local floor = math.floor

--------------------------------------------------------------------------------
-- command descriptions

local function BuildDefOf(cmd)
	if cmd.id > CMD_BUILD and cmd.id < CMD_BUILD_MAX then
		local defID = cmd.id - CMD_BUILD
		if UnitDefs[defID] then
			return defID
		end
	end
	return nil
end

local function CostOf(cmd, defID)
	local def = UnitDefs[defID]
	local cost = def and def.customParams and tonumber(def.customParams.cost)
	if not cost then
		cost = tonumber((cmd.tooltip or ""):match("Cost: (%d+)"))
	end
	return cost
end

-- the first hotkey bound to a command, formatted for display
local function HotkeyOf(cmd)
	if not cmd.action or cmd.action == "" then
		return ""
	end
	local keys = Spring.GetActionHotKeys(cmd.action)
	local key = keys and keys[1]
	if not key then
		return ""
	end
	key = key:gsub("^[Aa]ny%+", "")
	return key:upper()
end

-- a setting shows its current state, an order its name
local function LabelOf(cmd)
	if cmd.type == CMDTYPE.ICON_MODE and cmd.params then
		local current = tonumber(cmd.params[1]) or 0
		local label = cmd.params[current + 2]
		if label and label ~= "" then
			return label
		end
	end
	return cmd.name or ""
end

local function Signature(descs)
	local parts = {}
	for i = 1, #descs do
		local cmd = descs[i]
		if not cmd.hidden then
			parts[#parts + 1] = cmd.id .. (cmd.disabled and "d" or "")
		end
	end
	return table.concat(parts, ",")
end

--------------------------------------------------------------------------------
-- building the panel for a set of commands

local function Rebuild(descs)
	orders, builds, buildIndexByDef = {}, {}, {}
	local orderRml, buildRml = {}, {}
	view.Forget() -- ids are about to be reused by new elements

	for i = 1, #descs do
		local cmd = descs[i]
		if not cmd.hidden then
			local defID = BuildDefOf(cmd)
			if defID then
				builds[#builds + 1] = {index = i, id = cmd.id, def = defID, cost = CostOf(cmd, defID)}
				buildIndexByDef[defID] = i
				local build = builds[#builds]
				buildRml[#buildRml + 1] = string.format(
					'<div id="b-%d" class="bcard%s" data-cmd="%d">' ..
						'%s' ..
						'<span class="bcost">%s</span>' ..
						'<span id="b-%d-count" class="badge bcount hidden"/>' ..
						'<div id="b-%d-bar" class="bprogress"/>' ..
					'</div>',
					i, cmd.disabled and " disabled" or "", i,
					hud.UnitPictureRML(defID, "bpic"),
					build.cost and tostring(build.cost) or "",
					i, i)
				view.Assume("b-" .. i .. "-count", "hidden", true)
			elseif cmd.id >= 0 and not hiddenOrders[cmd.id] then
				orders[#orders + 1] = {index = i, id = cmd.id}
				orderRml[#orderRml + 1] = string.format(
					'<div id="c-%d" class="cmd%s%s" data-cmd="%d">' ..
						'<span id="c-%d-name" class="cmd-name"/>' ..
						'<span class="cmd-key">%s</span>' ..
					'</div>',
					i, (cmd.type == CMDTYPE.ICON_MODE) and " mode" or "", cmd.disabled and " disabled" or "", i,
					i, hud.Escape(HotkeyOf(cmd)))
			end
		end
	end

	view.Element("orders").inner_rml = table.concat(orderRml)
	view.Element("builds").inner_rml = table.concat(buildRml)
	view.SetClass("build-wrap", "hidden", #builds == 0)
	hoverIndex = nil
end

--------------------------------------------------------------------------------
-- selection

local function SelectionSummary(selected)
	local count = #selected
	local counts = Spring.GetSelectedUnitsCounts() or {}
	local types = {}
	for defID, n in pairs(counts) do
		if type(defID) == "number" and UnitDefs[defID] then
			types[#types + 1] = {def = defID, count = n}
		end
	end
	table.sort(types, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.def < b.def
	end)

	local title
	if #types == 1 then
		local name = UnitDefs[types[1].def].humanName
		title = (count == 1) and name or (count .. " " .. name)
	else
		title = count .. " ships"
	end

	local chips = {}
	if #types > 1 then
		for i = 1, math.min(#types, MAX_TYPE_CHIPS) do
			chips[#chips + 1] = '<span class="chip">' .. types[i].count .. " " .. hud.Escape(UnitDefs[types[i].def].humanName) .. '</span>'
		end
		if #types > MAX_TYPE_CHIPS then
			chips[#chips + 1] = '<span class="chip">+' .. (#types - MAX_TYPE_CHIPS) .. ' more</span>'
		end
	end

	local health, maxHealth = 0, 0
	for i = 1, math.min(count, MAX_HEALTH_UNITS) do
		local h, m = Spring.GetUnitHealth(selected[i])
		if h and m then
			health = health + math.max(h, 0)
			maxHealth = maxHealth + m
		end
	end
	return title, table.concat(chips), health, maxHealth
end

-- builders in the selection: per unit def how many are queued or being built,
-- and the single selected builder's own state
local function ProductionState(selected)
	local queued = {}
	local builders = 0
	local single
	for i = 1, #selected do
		local unitID = selected[i]
		local queueStr = Spring.GetUnitRulesParam(unitID, "build_queue")
		if queueStr then
			builders = builders + 1
			local current = Spring.GetUnitRulesParam(unitID, "build_current") or 0
			local queue = {}
			if type(queueStr) == "number" then
				queueStr = tostring(queueStr)
			end
			for id in tostring(queueStr):gmatch("%d+") do
				id = tonumber(id)
				queue[#queue + 1] = id
				queued[id] = (queued[id] or 0) + 1
			end
			if current > 0 then
				queued[current] = (queued[current] or 0) + 1
			end
			single = {
				current = current > 0 and current or nil,
				progress = Spring.GetUnitRulesParam(unitID, "build_progress") or 0,
				queue = queue,
			}
		end
	end
	if builders ~= 1 then
		single = nil
	end
	return queued, single, builders
end

--------------------------------------------------------------------------------
-- refresh

local function InfoText(descs)
	local cmd = hoverIndex and descs[hoverIndex]
	if not cmd then
		return ""
	end
	local text = cmd.tooltip
	if not text or text == "" then
		text = cmd.name or ""
	end
	text = hud.Escape(text):gsub("\r", ""):gsub("\n+", " \194\183 ")
	return text
end

local function Refresh()
	local selected = Spring.GetSelectedUnits() or {}
	local descs = Spring.GetActiveCmdDescs() or {}
	local visible = #selected > 0

	view.SetClass("cmdpanel", "hidden", not visible)
	if not visible then
		hoverIndex = nil
		return
	end

	local signature = Signature(descs)
	if signature ~= shownSignature then
		shownSignature = signature
		Rebuild(descs)
		accentColour = nil -- new progress bars need the accent again
	end

	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		local bars = {"cmd-accent"}
		for i = 1, #builds do
			bars[#bars + 1] = "b-" .. builds[i].index .. "-bar"
		end
		hud.ApplyAccent(document, team, {}, bars)
	end

	-- selection
	local title, chips, health, maxHealth = SelectionSummary(selected)
	view.SetText("sel-title", hud.Escape(title))
	view.SetText("sel-types", chips)
	local fraction = (maxHealth > 0) and (health / maxHealth) or 0
	view.SetStyle("sel-health", "width", floor(fraction * 100 + 0.5) .. "%")
	view.SetClass("sel-health", "health-good", fraction > 0.6)
	view.SetClass("sel-health", "health-warn", fraction <= 0.6 and fraction > 0.3)
	view.SetClass("sel-health", "health-bad", fraction <= 0.3)
	view.SetText("sel-health-text", floor(health) .. " / " .. floor(maxHealth) .. " hull")

	-- orders
	local activeIndex = Spring.GetActiveCommand()
	for i = 1, #orders do
		local order = orders[i]
		local cmd = descs[order.index]
		if cmd then
			view.SetText("c-" .. order.index .. "-name", hud.Escape(LabelOf(cmd)))
			view.SetClass("c-" .. order.index, "active", activeIndex == order.index)
		end
	end

	-- production
	if #builds > 0 then
		local money = Spring.GetTeamRulesParam(team, "money") or 0
		local queued, single = ProductionState(selected)
		for i = 1, #builds do
			local build = builds[i]
			local id = "b-" .. build.index
			local count = queued[build.def] or 0
			view.SetClass(id .. "-count", "hidden", count == 0)
			if count > 0 then
				view.SetText(id .. "-count", tostring(count))
			end
			view.SetClass(id, "poor", build.cost ~= nil and money < build.cost)
			local building = single and single.current == build.def
			view.SetStyle(id .. "-bar", "width", building and (floor(single.progress * 100) .. "%") or "0%")
		end

		if single and single.current and UnitDefs[single.current] then
			view.SetText("bstatus", "Building " .. hud.Escape(UnitDefs[single.current].humanName) .. " \194\183 " .. floor(single.progress * 100) .. "%")
		else
			view.SetText("bstatus", "")
		end
		local queueRml = {}
		if single then
			for i = 1, math.min(#single.queue, MAX_QUEUE_PICS) do
				local defID = single.queue[i]
				queueRml[#queueRml + 1] = hud.UnitPictureRML(defID, "qpic", 'data-def="' .. defID .. '"')
			end
			if #single.queue > MAX_QUEUE_PICS then
				queueRml[#queueRml + 1] = '<span class="sub"> +' .. (#single.queue - MAX_QUEUE_PICS) .. '</span>'
			end
		end
		view.SetText("bqueue", table.concat(queueRml))
	end

	view.SetText("cmd-info", InfoText(descs))
end

--------------------------------------------------------------------------------
-- input

-- pass a click on to the engine as if its own menu button had been clicked
local function Activate(index, rightButton)
	local descs = Spring.GetActiveCmdDescs() or {}
	local cmd = descs[index]
	if not cmd or cmd.disabled then
		return
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if rightButton then
		Spring.SetActiveCommand(index, 3, false, true, alt, ctrl, meta, shift)
	else
		Spring.SetActiveCommand(index, 1, true, false, alt, ctrl, meta, shift)
	end
	dirty = true
end

local function OnCommandMouseDown(event)
	local index = hud.EventAttribute(event, "data-cmd")
	local button = event.parameters and event.parameters.button
	if index and (button == 0 or button == 1) then
		Activate(index, button == 1)
	end
end

-- clicking a queue entry cancels one of that type, like a right-click on its card
local function OnQueueMouseDown(event)
	local defID = hud.EventAttribute(event, "data-def")
	local index = defID and buildIndexByDef[defID]
	if index then
		Activate(index, true)
	end
end

local function OnMouseOver(event)
	hoverIndex = hud.EventAttribute(event, "data-cmd")
	dirty = true
end

local function OnMouseOut(event)
	hoverIndex = nil
	dirty = true
end

--------------------------------------------------------------------------------
-- call-ins

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Command Panel] RmlUi is not available, keeping the engine command menu")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Command Panel] no RmlUi context, keeping the engine command menu")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Command Panel] could not load " .. DOCUMENT_PATH .. ", keeping the engine command menu", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("cmdpanel", "hidden", true)
	view.Assume("build-wrap", "hidden", true)
	view.Assume("sel-health", "health-good", true)

	for _, id in ipairs({"orders", "builds"}) do
		view.Element(id):AddEventListener("mousedown", OnCommandMouseDown)
		view.Element(id):AddEventListener("mouseover", OnMouseOver)
		view.Element(id):AddEventListener("mouseout", OnMouseOut)
	end
	view.Element("bqueue"):AddEventListener("mousedown", OnQueueMouseDown)

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()

	-- hide the engine's own command menu; commands and hotkeys stay
	widgetHandler:ConfigLayoutHandler(false)
	WG.thisCommandPanel = true
end

function widget:Shutdown()
	if WG.thisCommandPanel then
		widgetHandler:ConfigLayoutHandler(true) -- back to the engine menu
	end
	WG.thisCommandPanel = nil
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

function widget:CommandsChanged()
	dirty = true
end

function widget:Update()
	if not document then
		return
	end
	local now = Spring.GetTimer()
	if dirty or Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		dirty = false
		Refresh()
	end
end
