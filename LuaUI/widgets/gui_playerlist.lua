--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Players list of the RmlUi HUD, in the bottom-right corner.
--
--  One row per player (or AI), grouped by alliance with your own alliance
--  first: team colour, name, planets held, ping. Defeated teams and players
--  who left are greyed out. Spectators are counted on one line; click it to
--  see their names.
--
--  Planets held comes from the game rules params planet_count and
--  planet_<i>_owner (LuaRules/Gadgets/hud_state.lua).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Players List",
		desc = "Players by alliance with planets held and ping",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/playerlist.rml"
local UPDATE_INTERVAL = 1
-- ping in milliseconds from which it is shown as a warning / as bad
local PING_WARN = 300
local PING_BAD = 800

local hud
local document
local view
local lastUpdate
local shownRows
local showSpectators = false
local accentTeam, accentColour

--------------------------------------------------------------------------------

local function PlanetsByTeam()
	local held = {}
	local count = Spring.GetGameRulesParam("planet_count") or 0
	for i = 1, count do
		local owner = Spring.GetGameRulesParam("planet_" .. i .. "_owner")
		if owner and owner >= 0 then
			held[owner] = (held[owner] or 0) + 1
		end
	end
	return held
end

local function PingRML(seconds)
	local ms = math.floor((seconds or 0) * 1000 + 0.5)
	local class = (ms >= PING_BAD) and "bad" or ((ms >= PING_WARN) and "warn" or "")
	return string.format('<span class="%s">%d ms</span>', class, ms)
end

-- Everything the list shows: rows grouped by alliance, and spectator names.
local function Collect()
	local myPlayer = Spring.GetMyPlayerID()
	local myAlly = Spring.GetMyAllyTeamID()
	local gaia = Spring.GetGaiaTeamID()
	local planets = PlanetsByTeam()

	-- players by team, and spectators
	local byTeam, spectators = {}, {}
	for _, playerID in ipairs(Spring.GetPlayerList() or {}) do
		local name, active, spectator, teamID, _, ping = Spring.GetPlayerInfo(playerID, false)
		if name then
			if spectator then
				if active then
					spectators[#spectators + 1] = name
				end
			else
				byTeam[teamID] = byTeam[teamID] or {}
				table.insert(byTeam[teamID], {id = playerID, name = name, active = active, ping = ping})
			end
		end
	end
	table.sort(spectators, function(a, b) return a:lower() < b:lower() end)

	local groups, order = {}, {}
	for _, teamID in ipairs(Spring.GetTeamList() or {}) do
		if teamID ~= gaia then
			local _, leader, dead, isAI, _, allyTeam = Spring.GetTeamInfo(teamID, false)
			local r, g, b = Spring.GetTeamColor(teamID)
			local colour = string.format("rgb(%d,%d,%d)", (r or 0.5) * 255, (g or 0.5) * 255, (b or 0.5) * 255)
			local group = groups[allyTeam]
			if not group then
				group = {ally = allyTeam, rows = {}}
				groups[allyTeam] = group
				order[#order + 1] = group
			end
			local function Add(row)
				row.colour = colour
				row.planets = planets[teamID] or 0
				row.out = row.out or dead
				group.rows[#group.rows + 1] = row
			end

			local luaAI = Spring.GetTeamLuaAI(teamID)
			if luaAI and luaAI ~= "" then
				Add({name = luaAI, ai = true})
			elseif isAI then
				local _, aiName, _, shortName = Spring.GetAIInfo(teamID)
				local name = aiName
				if not name or name == "" or name == "UNKNOWN" then
					name = shortName
				end
				Add({name = name or "AI", ai = true})
			else
				local members = byTeam[teamID] or {}
				table.sort(members, function(a, b) return a.id < b.id end)
				if #members == 0 then
					-- nobody plays this team any more
					local name = leader and leader >= 0 and Spring.GetPlayerInfo(leader, false)
					Add({name = name or ("Team " .. teamID), out = true})
				end
				for _, member in ipairs(members) do
					Add({name = member.name, me = member.id == myPlayer, out = not member.active, ping = member.active and member.ping or nil})
				end
			end
		end
	end
	table.sort(order, function(a, b)
		if (a.ally == myAlly) ~= (b.ally == myAlly) then
			return a.ally == myAlly
		end
		return a.ally < b.ally
	end)
	return order, spectators
end

local function RowsRML(groups)
	local rml = {}
	for index, group in ipairs(groups) do
		if index > 1 then
			rml[#rml + 1] = '<div class="gap"/>'
		end
		for _, row in ipairs(group.rows) do
			rml[#rml + 1] = string.format(
				'<div class="prow%s%s"><div class="dot" style="background-color: %s;"/>' ..
				'<div class="c-name">%s%s</div><div class="c-planets">%d</div><div class="c-ping">%s</div></div>',
				row.me and " me" or "", row.out and " out" or "", row.colour,
				hud.Escape(row.name), row.ai and '<span class="tag">AI</span>' or "",
				row.planets, row.ping and PingRML(row.ping) or "")
		end
	end
	return table.concat(rml)
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		hud.ApplyAccent(document, team, {}, {"players-accent"})
	end

	local groups, spectators = Collect()
	local rml = RowsRML(groups)
	if rml ~= shownRows then
		shownRows = rml
		view.Element("rows").inner_rml = rml
	end
	view.SetClass("players", "hidden", #groups == 0)

	local count = #spectators
	view.SetClass("specs", "hidden", count == 0)
	view.SetClass("spec-names", "hidden", count == 0 or not showSpectators)
	if count > 0 then
		view.SetText("specs", count .. (count == 1 and " spectator" or " spectators") .. (showSpectators and "" or " \194\183 click for names"))
		local names = {}
		for i, name in ipairs(spectators) do
			names[i] = hud.Escape(name)
		end
		view.SetText("spec-names", table.concat(names, ", "))
	end
end

--------------------------------------------------------------------------------

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
		Spring.Echo("[THIS Players List] could not load " .. DOCUMENT_PATH .. "", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("players", "hidden", true)
	view.Assume("specs", "hidden", true)
	view.Assume("spec-names", "hidden", true)
	view.Element("specs"):AddEventListener("mousedown", function(event)
		if event.parameters and event.parameters.button == 0 then
			showSpectators = not showSpectators
			Refresh()
		end
	end)

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
