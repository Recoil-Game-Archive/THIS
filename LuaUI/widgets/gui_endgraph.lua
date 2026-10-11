--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  End-of-game results of the RmlUi HUD. Replaces the engine's statistics box.
--
--  When the game ends this shows who won, a line chart with one line per
--  team, and a table of all teams. The chart can show planets held, income,
--  units alive, kills or losses over the course of the game.
--
--  The numbers come from LuaRules/Gadgets/game_history.lua, which publishes
--  them as game rules params (hist_*) at the moment the game ends.
--
--  The window can be closed to keep watching; the game menu then has a
--  "Results" entry that brings it back (WG.thisEndGraph).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS End Graph",
		desc = "Results and per-team graphs when the game ends",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 80, -- sees Esc before the settings window and the game menu
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/endgraph.rml"
local KEY_ESCAPE = 27
local GAME_SPEED = 30
-- the window opens this long after the game has ended
local OPEN_DELAY = 2.5
-- size of the plot in dp; must match #chart in endgraph.rml
local PLOT_W, PLOT_H = 740, 260
-- a line is drawn from at most this many points
local MAX_POINTS = 90

-- {series in the rules params, tab label, sentence above the chart}
local CHARTS = {
	{"planets", "Planets", "Planets held"},
	{"income", "Income", "Income per second"},
	{"units", "Units", "Units alive"},
	{"kills", "Kills", "Enemy units destroyed, running total"},
	{"losses", "Losses", "Units lost to the enemy, running total"},
}

local hud
local document
local view
local lastUpdate

local gameOver = false
local winners = {}       -- ally team -> true
local sinceOver = 0
local autoOpened = false
local open = false
local data                -- {count, interval, teams = {...}} once the history has arrived
local currentChart = 1
local accentTeam, accentColour
-- the team this player played, kept from before a defeat turns them into a spectator
local playedTeam, playedAlly

--------------------------------------------------------------------------------
-- data

local function TeamName(teamID, leader, isAI)
	local luaAI = Spring.GetTeamLuaAI(teamID)
	if luaAI and luaAI ~= "" then
		return luaAI
	end
	if isAI then
		local _, name, _, shortName = Spring.GetAIInfo(teamID)
		if not name or name == "" or name == "UNKNOWN" then
			name = shortName
		end
		return name or "AI"
	end
	local name = leader and leader >= 0 and Spring.GetPlayerInfo(leader, false)
	return name or ("Team " .. teamID)
end

local function ParseSeries(text)
	local values = {}
	if type(text) == "string" then
		for number in text:gmatch("[^,]+") do
			values[#values + 1] = tonumber(number) or 0
		end
	elseif type(text) == "number" then
		values[1] = text -- a single sample comes back as a number
	end
	return values
end

-- Reads the published history. Returns nil until it is there.
local function LoadData()
	local count = Spring.GetGameRulesParam("hist_count")
	if not count or count < 1 then
		return nil
	end
	local loaded = {count = count, interval = Spring.GetGameRulesParam("hist_interval") or 300, teams = {}}
	local gaia = Spring.GetGaiaTeamID()
	for _, teamID in ipairs(Spring.GetTeamList() or {}) do
		if teamID ~= gaia then
			local _, leader, _, isAI, _, allyTeam = Spring.GetTeamInfo(teamID, false)
			local r, g, b = Spring.GetTeamColor(teamID)
			local team = {
				id = teamID,
				ally = allyTeam,
				name = TeamName(teamID, leader, isAI),
				colour = string.format("rgb(%d,%d,%d)", (r or 0.5) * 255, (g or 0.5) * 255, (b or 0.5) * 255),
				me = teamID == playedTeam,
				won = winners[allyTeam] == true,
				series = {},
			}
			for _, chart in ipairs(CHARTS) do
				team.series[chart[1]] = ParseSeries(Spring.GetGameRulesParam("hist_" .. teamID .. "_" .. chart[1]))
			end
			loaded.teams[#loaded.teams + 1] = team
		end
	end
	return loaded
end

--------------------------------------------------------------------------------
-- drawing

local function FormatTime(frames)
	local seconds = math.floor(frames / GAME_SPEED + 0.5)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function FormatNumber(value)
	if value >= 10000 then
		return string.format("%.0fk", value / 1000)
	elseif value >= 1000 then
		return string.format("%.1fk", value / 1000)
	end
	return tostring(math.floor(value + 0.5))
end

-- A round number at or above the largest value, and how many steps the
-- scale is divided into.
local function Scale(maximum)
	if maximum <= 8 then
		-- small whole numbers (planets): one line per unit
		local top = math.max(1, math.ceil(maximum))
		return top, top
	end
	local magnitude = 10 ^ math.floor(math.log(maximum) / math.log(10))
	for _, factor in ipairs({1, 1.2, 1.6, 2, 2.4, 3.2, 4, 6, 8, 10}) do
		local top = factor * magnitude
		if top >= maximum then
			return top, 4
		end
	end
	return maximum, 4
end

-- The samples of a line that are drawn: all of them, or an even selection.
local function PointIndices(count)
	local indices = {}
	if count <= MAX_POINTS then
		for i = 1, count do
			indices[i] = i
		end
	else
		for n = 1, MAX_POINTS do
			indices[n] = math.floor((n - 1) * (count - 1) / (MAX_POINTS - 1) + 1.5)
		end
	end
	return indices
end

local function ChartRML(series)
	local rml = {}
	local count = data.count
	local maximum = 0
	for _, team in ipairs(data.teams) do
		for _, value in ipairs(team.series[series]) do
			if value > maximum then
				maximum = value
			end
		end
	end
	local top, steps = Scale(maximum)

	-- scale lines and their numbers
	for step = 0, steps do
		local y = PLOT_H - step * PLOT_H / steps
		rml[#rml + 1] = string.format('<div class="grid%s" style="top: %.1fdp;"/><div class="ylabel" style="top: %.1fdp;">%s</div>',
			step == 0 and " base" or "", y, y - 7, FormatNumber(top * step / steps))
	end
	-- times along the bottom
	local duration = (count - 1) * data.interval
	for step = 0, 4 do
		rml[#rml + 1] = string.format('<div class="xlabel" style="left: %.1fdp;">%s</div>', step * PLOT_W / 4, FormatTime(duration * step / 4))
	end

	if count < 2 then
		rml[#rml + 1] = '<div id="no-data">The game was too short for a graph.</div>'
		return table.concat(rml)
	end

	local indices = PointIndices(count)
	local function X(i)
		return (i - 1) / (count - 1) * PLOT_W
	end
	local function Y(value)
		return PLOT_H - math.min(1, value / top) * PLOT_H
	end
	-- your own line is drawn last, on top of the others
	local order = {}
	for _, team in ipairs(data.teams) do
		if not team.me then
			order[#order + 1] = team
		end
	end
	for _, team in ipairs(data.teams) do
		if team.me then
			order[#order + 1] = team
		end
	end
	for _, team in ipairs(order) do
		local values = team.series[series]
		local x1, y1
		for _, i in ipairs(indices) do
			local x2, y2 = X(i), Y(values[i] or 0)
			if x1 then
				local dx, dy = x2 - x1, y2 - y1
				local length = math.sqrt(dx * dx + dy * dy)
				rml[#rml + 1] = string.format(
					'<div class="seg" style="left: %.1fdp; top: %.1fdp; width: %.1fdp; transform: rotate(%.2fdeg); background-color: %s;"/>',
					x1, y1 - 1, length + 0.6, math.deg(math.atan2(dy, dx)), team.colour)
			end
			x1, y1 = x2, y2
		end
		if x1 then
			rml[#rml + 1] = string.format('<div class="end-dot" style="left: %.1fdp; top: %.1fdp; background-color: %s;"/>', x1 - 3, y1 - 3, team.colour)
		end
	end
	return table.concat(rml)
end

local function TableRML(series)
	local rows = {}
	for _, team in ipairs(data.teams) do
		rows[#rows + 1] = team
	end
	local function Final(team, name)
		local values = team.series[name]
		return values[#values] or 0
	end
	local function Peak(team, name)
		local peak = 0
		for _, value in ipairs(team.series[name]) do
			if value > peak then
				peak = value
			end
		end
		return peak
	end
	-- the chart's own column decides the order
	local function Shown(team)
		if series == "kills" or series == "losses" then
			return Final(team, series)
		end
		return Peak(team, series)
	end
	table.sort(rows, function(a, b)
		local va, vb = Shown(a), Shown(b)
		if va ~= vb then
			return va > vb
		end
		return a.id < b.id
	end)

	local function Class(name)
		return (name == series) and "t-num shown" or "t-num"
	end
	local rml = {string.format(
		'<div class="trow head"><div class="t-name">TEAM</div><div class="%s">MOST PLANETS</div><div class="%s">TOP INCOME</div>' ..
		'<div class="%s">MOST UNITS</div><div class="%s">KILLS</div><div class="%s">LOSSES</div></div>',
		Class("planets"), Class("income"), Class("units"), Class("kills"), Class("losses"))}
	for _, team in ipairs(rows) do
		rml[#rml + 1] = string.format(
			'<div class="trow%s"><div class="dot" style="background-color: %s;"/><div class="t-name">%s%s</div>' ..
			'<div class="%s">%s</div><div class="%s">%s</div><div class="%s">%s</div><div class="%s">%s</div><div class="%s">%s</div></div>',
			team.me and " me" or "", team.colour, hud.Escape(team.name), team.won and '<span class="tag good">WINNER</span>' or "",
			Class("planets"), FormatNumber(Peak(team, "planets")), Class("income"), FormatNumber(Peak(team, "income")),
			Class("units"), FormatNumber(Peak(team, "units")), Class("kills"), FormatNumber(Final(team, "kills")),
			Class("losses"), FormatNumber(Final(team, "losses")))
	end
	return table.concat(rml)
end

local function BuildTabs()
	local rml = {}
	for i, chart in ipairs(CHARTS) do
		rml[#rml + 1] = string.format('<div id="tab-%d" class="tab" data-tab="%d">%s</div>', i, i, chart[2]:upper())
	end
	view.Element("tabs").inner_rml = table.concat(rml)
end

local function BuildChart()
	if not data then
		return
	end
	local chart = CHARTS[currentChart]
	view.SetText("chart-title", chart[3])
	view.Element("chart").inner_rml = ChartRML(chart[1])
	view.Element("table").inner_rml = TableRML(chart[1])
	for i = 1, #CHARTS do
		view.SetClass("tab-" .. i, "active", i == currentChart)
		view.SetStyle("tab-" .. i, "border-bottom-color", (i == currentChart) and accentColour or "rgba(0, 0, 0, 0)")
	end
end

-- The headline, and either "good"/"bad" to colour it or a line saying who won.
local function Outcome()
	if next(winners) == nil then
		return "GAME OVER", ""
	elseif playedTeam then
		if winners[playedAlly] then
			return "VICTORY", "good"
		end
		return "DEFEAT", "bad"
	end
	-- someone who only watched is told who won
	local names = {}
	for _, team in ipairs(data and data.teams or {}) do
		if team.won then
			names[#names + 1] = team.name
		end
	end
	return "GAME OVER", (#names > 0) and (table.concat(names, ", ") .. " won") or ""
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"results-accent", "close"})
		view.ForgetStyles()
		if open then
			BuildChart()
		end
	end
	view.SetClass("results", "hidden", not open)
	view.SetClass("backdrop", "hidden", not open)
end

local function SetOpen(state)
	if state and not data then
		data = LoadData()
	end
	open = state and data ~= nil
	if open then
		local title, extra = Outcome()
		view.SetText("outcome", title)
		view.SetClass("outcome", "good", extra == "good")
		view.SetClass("outcome", "bad", extra == "bad")
		local length = FormatTime((data.count - 1) * data.interval)
		local summary = "Game length " .. length
		if extra ~= "good" and extra ~= "bad" and extra ~= "" then
			summary = hud.Escape(extra) .. " \194\183 " .. summary
		end
		view.SetText("summary", summary)
		BuildChart()
		pcall(function() document:PullToFront() end)
	end
	Refresh()
end

--------------------------------------------------------------------------------
-- call-ins

local function OnClick(id, handler)
	view.Element(id):AddEventListener("mousedown", function(event)
		if event.parameters and event.parameters.button == 0 then
			handler()
		end
	end)
end

function widget:Initialize()
	if not RmlUi then
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")
	local context = hud.UpdateScale()
	if not context then
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS End Graph] could not load " .. DOCUMENT_PATH .. ", the engine's statistics box stays", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("results", "hidden", true)
	view.Assume("backdrop", "hidden", true)
	accentTeam = Spring.GetLocalTeamID()
	accentColour = hud.ApplyAccent(document, accentTeam, {}, {"results-accent", "close"})
	BuildTabs()
	view.Element("tabs"):AddEventListener("mousedown", function(event)
		if not (event.parameters and event.parameters.button == 0) then
			return
		end
		local index = hud.EventAttribute(event, "data-tab")
		if index and CHARTS[index] and index ~= currentChart then
			currentChart = index
			BuildChart()
		end
	end)
	OnClick("close", function() SetOpen(false) end)
	OnClick("backdrop", function() SetOpen(false) end)
	OnClick("quit", function() Spring.SendCommands("quitforce") end)

	Spring.SendCommands("endgraph 0") -- this window takes the place of the engine's
	WG.thisEndGraph = {
		Available = function() return gameOver end,
		Open = function() SetOpen(true) end,
	}

	if Spring.IsGameOver and Spring.IsGameOver() then
		gameOver = true -- LuaUI was reloaded after the end of the game
	end

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
end

function widget:Shutdown()
	WG.thisEndGraph = nil
	Spring.SendCommands("endgraph 1")
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

function widget:GameOver(winningAllyTeams)
	gameOver = true
	winners = {}
	for _, allyTeam in ipairs(winningAllyTeams or {}) do
		winners[allyTeam] = true
	end
	data = nil
	sinceOver = 0
	autoOpened = false
end

function widget:KeyPress(key, mods, isRepeat)
	if document and open and key == KEY_ESCAPE and not isRepeat then
		SetOpen(false)
		return true
	end
	return false
end

function widget:Update()
	if not document then
		return
	end
	local now = Spring.GetTimer()
	local elapsed = Spring.DiffTimers(now, lastUpdate)
	lastUpdate = now
	if hud.FollowGuiHidden(document) then
		return
	end
	if not gameOver and not Spring.GetSpectatingState() then
		playedTeam, playedAlly = Spring.GetMyTeamID(), Spring.GetMyAllyTeamID()
	end
	if gameOver and not autoOpened then
		sinceOver = sinceOver + elapsed
		if sinceOver >= OPEN_DELAY then
			-- wait for the history; give up after a while (old replay, gadget missing)
			if Spring.GetGameRulesParam("hist_count") or sinceOver > OPEN_DELAY + 10 then
				autoOpened = true
				SetOpen(true)
			end
		end
	end
	if open then
		Refresh()
	end
end
