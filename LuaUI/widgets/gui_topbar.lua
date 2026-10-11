--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Top bar and alerts, the first piece of the RmlUi HUD.
--
--  Shows credits, income, planets held, game time, the chosen perks and the
--  game's messages. Everything is read from rules params published by
--  LuaRules/Gadgets/hud_state.lua.
--
--  While this widget is running it sets WG.thisTopBar, which tells the legacy
--  HUD widget to stop drawing the old money panel and messages. If RmlUi is
--  missing or the document fails to load, the legacy drawing stays.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Top Bar",
		desc = "Credits, income, planets, game time, perks and alerts",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/topbar.rml"
local UPDATE_INTERVAL = 0.2 -- seconds between refreshes
local GAME_SPEED = 30       -- sim frames per second

local hud
local perkList
local document
local elements = {}   -- id -> element
local shownText = {}  -- id -> last inner_rml written
local shownClass = {} -- id .. class -> last state written
local lastUpdate
local accentTeam, accentColour

local floor = math.floor
local ceil = math.ceil

--------------------------------------------------------------------------------
-- small DOM helpers that only touch the document when something changed

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

--------------------------------------------------------------------------------

local function FormatClock(seconds)
	seconds = floor(seconds or 0)
	local hours = floor(seconds / 3600)
	local minutes = floor(seconds / 60) % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, seconds % 60)
	end
	return string.format("%d:%02d", minutes, seconds % 60)
end

local function CountPlanets(team)
	local total = Spring.GetGameRulesParam("planet_count") or 0
	local held = 0
	for i = 1, total do
		local owner = Spring.GetGameRulesParam("planet_" .. i .. "_owner")
		if owner and owner >= 0 and (owner == team or Spring.AreTeamsAllied(owner, team)) then
			held = held + 1
		end
	end
	return held, total
end

local function PerkChips(team)
	local chips = {}
	for i = 1, #perkList do
		if Spring.GetTeamRulesParam(team, "hasperk_" .. i) == 1 then
			chips[#chips + 1] = '<span class="chip">' .. hud.Escape(perkList[i][1]) .. '</span>'
		end
	end
	return table.concat(chips)
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local frame = Spring.GetGameFrame()

	-- accent follows the team colour (it changes when a spectator switches team)
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {"money"}, {"accent-line"})
	end

	-- credits and income
	local money = Spring.GetTeamRulesParam(team, "money") or 0
	local income = Spring.GetTeamRulesParam(team, "income") or 0
	SetText("money", tostring(floor(money)))
	SetText("income", "+" .. floor(income) .. " /s")

	-- planets, or the countdown when the team holds none and will lose
	local held, total = CountPlanets(team)
	local defeatFrame = Spring.GetTeamRulesParam(team, "defeat_frame") or 0
	local losing = defeatFrame > frame
	if losing then
		SetText("planets-label", "NO PLANETS")
		SetText("planets", ceil((defeatFrame - frame) / GAME_SPEED) .. "s")
		SetText("planets-total", "until defeat")
	else
		SetText("planets-label", "PLANETS HELD")
		SetText("planets", tostring(held))
		SetText("planets-total", "of " .. total)
	end
	SetClass("planets", "bad", losing)
	SetClass("topbar", "danger", losing)

	SetText("clock", FormatClock(Spring.GetGameSeconds()))

	SetText("perks", PerkChips(team))

	-- messages from the game
	local alertUntil = Spring.GetTeamRulesParam(team, "alert_until") or 0
	local showAlert = frame < alertUntil
	if showAlert then
		SetText("alert-text", hud.Escape(Spring.GetTeamRulesParam(team, "alert_text")))
		SetText("alert-hint", hud.Escape(Spring.GetTeamRulesParam(team, "alert_hint")))
	end
	SetClass("alert", "hidden", not showAlert)
end

--------------------------------------------------------------------------------

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Top Bar] RmlUi is not available, keeping the legacy HUD")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")
	perkList = include("perks/perks.lua")

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Top Bar] no RmlUi context, keeping the legacy HUD")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts() -- before the document, so its text is laid out with them

	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Top Bar] could not load " .. DOCUMENT_PATH .. ", keeping the legacy HUD", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	-- the "hidden" class is set in the markup, so start the cache from there
	shownClass["alert.hidden"] = true

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
	WG.thisTopBar = true
end

function widget:Shutdown()
	WG.thisTopBar = nil
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
