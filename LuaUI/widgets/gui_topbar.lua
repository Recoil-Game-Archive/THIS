--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Top bar and alerts, the first piece of the RmlUi HUD.
--
--  Shows credits, income, planets held, game time, the chosen perks and the
--  game's messages. Everything is read from rules params published by
--  LuaRules/Gadgets/hud_state.lua.
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
local view
local SetText, SetClass
local lastUpdate
local accentTeam, accentColour

local floor = math.floor
local ceil = math.ceil

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
	if losing then
		-- The capture countdown is worked out here from defeat_frame instead of
		-- being taken from the game's message, which is re-sent once a second
		-- and can leave gaps. It also counts smoothly this way.
		showAlert = true
		local seconds = ceil((defeatFrame - frame) / GAME_SPEED)
		SetText("alert-text", "You have " .. seconds .. (seconds == 1 and " second" or " seconds") .. " to capture a planet")
		SetText("alert-hint", "Move a ship into the circle, if you don't capture a planet in time you lose the game!")
	elseif showAlert then
		SetText("alert-text", hud.Escape(Spring.GetTeamRulesParam(team, "alert_text")))
		SetText("alert-hint", hud.Escape(Spring.GetTeamRulesParam(team, "alert_hint")))
	end
	SetClass("alert", "hidden", not showAlert)
end

--------------------------------------------------------------------------------

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Top Bar] RmlUi is not available")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")
	perkList = include("perks/perks.lua")

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Top Bar] no RmlUi context")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts() -- before the document, so its text is laid out with them

	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Top Bar] could not load " .. DOCUMENT_PATH .. "", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	SetText, SetClass = view.SetText, view.SetClass
	view.Assume("alert", "hidden", true) -- set in the markup

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
end

function widget:Shutdown()
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
	if hud.FollowGuiHidden(document) then
		return -- hidden with the rest of the GUI (F5)
	end
	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end
