--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Fleet yard: the large-ship column of the RmlUi HUD.
--
--  One card per large hull (left-click queues it, Alt+click puts it at the
--  front, right-click cancels one), the active build with its progress, the
--  queue (click an entry to cancel it) and a Deploy button for the finished
--  ship. Deploy mode highlights where the ship may jump in and shows whether
--  the spot under the cursor is valid before you click.
--
--  State comes from the rules params published by hud_state.lua; orders go
--  out as the gbuild / gcancel / gplace Lua messages handled by the build
--  gadget.
--
--  While this widget runs it sets WG.thisFleetYard, which switches off the
--  old build list, dispatch button and queue drawing.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Fleet Yard",
		desc = "Order, queue and deploy large ships",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/fleetyard.rml"
local UPDATE_INTERVAL = 0.1

-- these mirror build.locals.lua and planets.locals.lua
local JUMP_DISTANCE = 600     -- how close to a friendly carrier a ship may jump in
local OCCUPATION_RANGE = 500  -- radius of a planet's circle
local PERK_AUTOMATION = 4     -- "Advanced Automation": large ships build 15% faster
local AUTOMATION_FACTOR = 0.85

local hud
local perkList
local document
local elements = {}
local shownText = {}
local shownClass = {}
local shownStyle = {}
local lastUpdate

local hulls = {}       -- ordered list of {id=, name=, cost=, buildtime=, perk=, tooltip=}
local hullByID = {}
local builderDefs = {} -- unitDefIDs a large ship may jump in next to

local readyDef         -- unitDefID waiting to be deployed, or nil
local deploying = false
local hoverDef
local accentTeam, accentColour
local accentR, accentG, accentB = 0.4, 0.8, 1

local floor = math.floor
local ceil = math.ceil

--------------------------------------------------------------------------------
-- DOM helpers: only touch the document when something changed

local function Element(id)
	local element = elements[id]
	if element == nil then
		element = document:GetElementById(id) or false
		elements[id] = element
	end
	return element
end

local function SetText(id, text)
	if shownText[id] ~= text then
		local element = Element(id)
		if element then
			element.inner_rml = text
		end
		shownText[id] = text
	end
end

local function SetClass(id, class, state)
	local key = id .. "." .. class
	if shownClass[key] ~= state then
		local element = Element(id)
		if element then
			element:SetClass(class, state)
		end
		shownClass[key] = state
	end
end

local function SetStyle(id, property, value)
	local key = id .. "." .. property
	if shownStyle[key] ~= value then
		local element = Element(id)
		if element then
			element.style[property] = value
		end
		shownStyle[key] = value
	end
end

--------------------------------------------------------------------------------
-- data

local function DefParam(value)
	if value and value > 0 and hullByID[value] then
		return value
	end
	return nil
end

local function DecodeQueue(str)
	local queue = {}
	if type(str) == "number" then
		str = tostring(str)
	end
	if type(str) == "string" then
		for id in str:gmatch("%d+") do
			id = tonumber(id)
			if hullByID[id] then
				queue[#queue + 1] = id
			end
		end
	end
	return queue
end

local function CollectHulls()
	local _, orderLarge = include("Configs/build_order.lua")
	for id, def in pairs(UnitDefs) do
		local params = def.customParams
		if params.type == "large" and not params.nobuild then
			local hull = {
				id = id,
				name = def.humanName,
				tooltip = def.tooltip or "",
				cost = tonumber(params.cost) or 0,
				buildtime = tonumber(params.buildtime) or 0,
				perk = tonumber(params.needperk),
				order = orderLarge[def.name] or math.huge,
			}
			hulls[#hulls + 1] = hull
			hullByID[id] = hull
		end
		if params.builds or params.minelayer then
			builderDefs[#builderDefs + 1] = id
		end
	end
	table.sort(hulls, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.id < b.id
	end)
end

local function BuildCards()
	local rml = {}
	for i = 1, #hulls do
		local hull = hulls[i]
		local id = hull.id
		rml[#rml + 1] = string.format(
			'<div id="hull-%d" class="card" data-def="%d">' ..
				'<texture class="pic" src="#%d"/>' ..
				'<div class="card-text">' ..
					'<div class="card-name">%s</div>' ..
					'<div id="hull-%d-cost" class="card-cost">%d</div>' ..
				'</div>' ..
				'<span id="hull-%d-badge" class="badge hidden"/>' ..
				'<div id="hull-%d-bar" class="card-progress"/>' ..
			'</div>',
			id, id, id, hud.Escape(hull.name), id, hull.cost, id, id)
		-- these start hidden / empty in the markup
		shownClass["hull-" .. id .. "-badge.hidden"] = true
	end
	Element("hulls").inner_rml = table.concat(rml)
end

-- the hull card an event happened on, if any
local function EventDef(event)
	local element = event.target_element
	for _ = 1, 6 do
		if not element then
			return nil
		end
		if element:HasAttribute("data-def") then
			return tonumber(element:GetAttribute("data-def"))
		end
		element = element.parent_node
	end
	return nil
end

--------------------------------------------------------------------------------
-- deploy mode

-- places a large ship may jump to: {x, z, radius}
local function GetJumpZones(team)
	local zones = {}
	local allyTeam = Spring.GetMyAllyTeamID()
	local teams = Spring.GetTeamList(allyTeam) or {team}
	for i = 1, #teams do
		local units = Spring.GetTeamUnitsByDefs(teams[i], builderDefs) or {}
		for j = 1, #units do
			local x, _, z = Spring.GetUnitPosition(units[j])
			if x then
				zones[#zones + 1] = {x, z, JUMP_DISTANCE}
			end
		end
	end
	local planets = Spring.GetGameRulesParam("planet_count") or 0
	for i = 1, planets do
		local owner = Spring.GetGameRulesParam("planet_" .. i .. "_owner")
		if owner and owner >= 0 and (owner == team or Spring.AreTeamsAllied(owner, team)) then
			zones[#zones + 1] = {
				Spring.GetGameRulesParam("planet_" .. i .. "_x"),
				Spring.GetGameRulesParam("planet_" .. i .. "_z"),
				OCCUPATION_RANGE,
			}
		end
	end
	return zones
end

local function IsValidJump(zones, x, z)
	for i = 1, #zones do
		local zone = zones[i]
		local dx, dz = x - zone[1], z - zone[2]
		if dx * dx + dz * dz < zone[3] * zone[3] then
			return true
		end
	end
	return false
end

local function MouseGroundPosition(mx, my)
	if not mx then
		mx, my = Spring.GetMouseState()
	end
	local _, position = Spring.TraceScreenRay(mx, my, true)
	if position then
		return position[1], position[3]
	end
	return nil
end

local function SetDeploying(state)
	deploying = state and readyDef ~= nil
	SetClass("deploy", "armed", deploying)
	SetClass("deploy-hint", "hidden", not deploying)
	if deploying then
		SetClass("deploy-hint-text", "bad", false)
		SetText("deploy-hint-text", "Choose where " .. hud.Escape(hullByID[readyDef].name) .. " jumps in")
	end
end

--------------------------------------------------------------------------------
-- refresh

local function Refresh()
	local team = Spring.GetLocalTeamID()

	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"fleet-accent", "build-fill", "deploy"})
		local r, g, b = hud.GetAccent(team)
		accentR, accentG, accentB = r / 255, g / 255, b / 255
		shownStyle = {} -- card progress bars pick the colour up again below
	end

	local money = Spring.GetTeamRulesParam(team, "money") or 0
	local current = DefParam(Spring.GetTeamRulesParam(team, "gb_current"))
	local progress = Spring.GetTeamRulesParam(team, "gb_progress") or 0
	local queue = DecodeQueue(Spring.GetTeamRulesParam(team, "gb_queue"))
	readyDef = DefParam(Spring.GetTeamRulesParam(team, "gb_ready"))

	local queued = {}
	for i = 1, #queue do
		queued[queue[i]] = (queued[queue[i]] or 0) + 1
	end

	-- hull cards
	for i = 1, #hulls do
		local hull = hulls[i]
		local id = hull.id
		local card = "hull-" .. id
		local locked = hull.perk ~= nil and Spring.GetTeamRulesParam(team, "hasperk_" .. hull.perk) ~= 1
		SetClass(card, "locked", locked)
		if locked then
			local perk = perkList[hull.perk]
			SetText(card .. "-cost", "Needs " .. hud.Escape(perk and perk[1] or "a perk"))
		else
			SetText(card .. "-cost", tostring(hull.cost))
		end
		SetClass(card, "poor", (not locked) and money < hull.cost)

		local count = (queued[id] or 0) + ((current == id) and 1 or 0) + ((readyDef == id) and 1 or 0)
		SetClass(card .. "-badge", "hidden", count == 0)
		if count > 0 then
			SetText(card .. "-badge", tostring(count))
		end

		local building = (current == id)
		SetStyle(card .. "-bar", "width", building and (floor(progress * 100) .. "%") or "0%")
		SetStyle(card .. "-bar", "background-color", accentColour)
	end

	-- the active build
	SetClass("build-now", "hidden", current == nil)
	SetClass("idle", "hidden", current ~= nil or readyDef ~= nil or #queue > 0)
	if current then
		local hull = hullByID[current]
		local buildtime = hull.buildtime
		if Spring.GetTeamRulesParam(team, "hasperk_" .. PERK_AUTOMATION) == 1 then
			buildtime = buildtime * AUTOMATION_FACTOR
		end
		SetText("build-name", hud.Escape(hull.name))
		SetText("build-eta", ceil(buildtime * (1 - progress)) .. "s")
		SetStyle("build-fill", "width", floor(progress * 100) .. "%")
	end

	-- the queue
	SetClass("queue-wrap", "hidden", #queue == 0)
	local queueRml = {}
	for i = 1, #queue do
		queueRml[i] = string.format('<texture class="qpic" src="#%d" data-def="%d"/>', queue[i], queue[i])
	end
	SetText("queue", table.concat(queueRml))

	-- the finished ship
	SetClass("deploy", "hidden", readyDef == nil)
	if readyDef then
		SetText("deploy", "DEPLOY " .. hud.Escape(hullByID[readyDef].name:upper()))
	elseif deploying then
		SetDeploying(false)
	end

	-- what the mouse is over
	local hull = hoverDef and hullByID[hoverDef]
	SetClass("info", "hidden", hull == nil)
	if hull then
		SetText("info", hud.Escape(hull.tooltip) .. " Builds in " .. hull.buildtime .. "s.")
	end
end

--------------------------------------------------------------------------------
-- input from the panel

local function OnHullMouseDown(event)
	local id = EventDef(event)
	local hull = id and hullByID[id]
	if not hull then
		return
	end
	local button = event.parameters and event.parameters.button
	if button == 1 then -- right button
		Spring.SendLuaRulesMsg("gcancel:" .. id)
	elseif button == 0 then
		local alt = Spring.GetModKeyState()
		Spring.SendLuaRulesMsg("gbuild:" .. id .. (alt and ":alt" or ""))
	end
end

local function OnQueueMouseDown(event)
	local id = EventDef(event)
	if id and hullByID[id] then
		Spring.SendLuaRulesMsg("gcancel:" .. id)
	end
end

local function OnDeployMouseDown(event)
	local button = event.parameters and event.parameters.button
	if button == 0 then
		SetDeploying(not deploying)
	elseif button == 1 then
		SetDeploying(false)
	end
end

local function OnHullMouseOver(event)
	hoverDef = EventDef(event)
end

local function OnHullMouseOut(event)
	hoverDef = nil
end

--------------------------------------------------------------------------------
-- call-ins

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Fleet Yard] RmlUi is not available, keeping the legacy build list")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")
	perkList = include("perks/perks.lua")
	CollectHulls()

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Fleet Yard] no RmlUi context, keeping the legacy build list")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Fleet Yard] could not load " .. DOCUMENT_PATH .. ", keeping the legacy build list", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	-- classes set in the markup
	shownClass["build-now.hidden"] = true
	shownClass["queue-wrap.hidden"] = true
	shownClass["deploy.hidden"] = true
	shownClass["deploy-hint.hidden"] = true
	shownClass["info.hidden"] = true

	BuildCards()
	Element("hulls"):AddEventListener("mousedown", OnHullMouseDown)
	Element("hulls"):AddEventListener("mouseover", OnHullMouseOver)
	Element("hulls"):AddEventListener("mouseout", OnHullMouseOut)
	Element("queue"):AddEventListener("mousedown", OnQueueMouseDown)
	Element("deploy"):AddEventListener("mousedown", OnDeployMouseDown)

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
	WG.thisFleetYard = true
end

function widget:Shutdown()
	WG.thisFleetYard = nil
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

function widget:Update()
	if not document then
		return
	end
	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end

-- Deploy mode: the next left click in the world places the ship.
function widget:MousePress(mx, my, button)
	if not deploying then
		return false
	end
	if button == 3 then
		SetDeploying(false)
		return true
	end
	if button == 1 then
		local x, z = MouseGroundPosition(mx, my)
		if x and IsValidJump(GetJumpZones(Spring.GetLocalTeamID()), x, z) then
			Spring.SendLuaRulesMsg(string.format("gplace:%.1f:%.1f", x, z))
			SetDeploying(false)
		else
			SetClass("deploy-hint-text", "bad", true)
			SetText("deploy-hint-text", "Too far from a friendly carrier or planet")
		end
		return true
	end
	return false
end

function widget:KeyPress(key)
	if deploying and key == 27 then -- Esc
		SetDeploying(false)
		return true
	end
	return false
end

function widget:DrawWorld()
	if not deploying then
		return
	end
	local zones = GetJumpZones(Spring.GetLocalTeamID())
	gl.LineWidth(2)
	gl.Color(accentR, accentG, accentB, 0.9)
	for i = 1, #zones do
		local zone = zones[i]
		gl.DrawGroundCircle(zone[1], 0, zone[2], zone[3], 48)
	end
	local x, z = MouseGroundPosition()
	if x then
		if IsValidJump(zones, x, z) then
			gl.Color(0.44, 0.86, 0.55, 1)
		else
			gl.Color(1, 0.42, 0.37, 1)
		end
		gl.LineWidth(3)
		gl.DrawGroundCircle(x, 0, z, 60, 24)
	end
	gl.LineWidth(1)
	gl.Color(1, 1, 1, 1)
end
