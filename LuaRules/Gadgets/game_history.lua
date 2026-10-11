--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Game history for the end-of-game graph.
--
--  Every SAMPLE_FRAMES frames this gadget notes, for each team: planets held,
--  income, units alive, and the running totals of kills and losses. Nothing
--  is shown to anyone during the game. When the game ends, the history is
--  published as public game rules params, where LuaUI (gui_endgraph.lua)
--  reads it:
--
--    hist_count              number of samples per series
--    hist_interval           game frames between two samples
--    hist_<team>_<series>    "v1,v2,v3,..." for the series planets, income,
--                            units, kills, losses
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Game History",
		desc = "Records per-team history and publishes it when the game ends",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 110, -- after hud_state, whose planet owner params are read here
		enabled = true
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local SAMPLE_FRAMES = 300   -- 10 seconds
local MAX_PUBLISHED = 180   -- longer histories are thinned out to about this many samples
local SERIES = {"planets", "income", "units", "kills", "losses"}

local teams = {}
local history = {}   -- team -> series name -> list of values
local kills = {}
local losses = {}
local samples = 0
local published = false

local floor = math.floor

local function Sample()
	local planets = {}
	local count = Spring.GetGameRulesParam("planet_count") or 0
	for i = 1, count do
		local owner = Spring.GetGameRulesParam("planet_" .. i .. "_owner")
		if owner and owner >= 0 then
			planets[owner] = (planets[owner] or 0) + 1
		end
	end
	local income = GG.lastIncome or {}
	samples = samples + 1
	for _, team in ipairs(teams) do
		local h = history[team]
		h.planets[samples] = planets[team] or 0
		h.income[samples] = floor((income[team] or 0) + 0.5)
		h.units[samples] = Spring.GetTeamUnitCount(team) or 0
		h.kills[samples] = kills[team]
		h.losses[samples] = losses[team]
	end
end

local function Publish()
	if published then
		return
	end
	published = true
	Sample() -- the state at the end
	-- thin out a long game, always keeping the first and the last sample
	local step = math.max(1, math.ceil(samples / MAX_PUBLISHED))
	local picks = {}
	for i = 1, samples, step do
		picks[#picks + 1] = i
	end
	if picks[#picks] ~= samples then
		picks[#picks + 1] = samples
	end
	local public = {public = true}
	for _, team in ipairs(teams) do
		for _, series in ipairs(SERIES) do
			local values = {}
			for n, i in ipairs(picks) do
				values[n] = history[team][series][i]
			end
			Spring.SetGameRulesParam("hist_" .. team .. "_" .. series, table.concat(values, ","), public)
		end
	end
	Spring.SetGameRulesParam("hist_interval", SAMPLE_FRAMES * step, public)
	Spring.SetGameRulesParam("hist_count", #picks, public)
end

function gadget:Initialize()
	local gaia = Spring.GetGaiaTeamID()
	for _, team in ipairs(Spring.GetTeamList()) do
		if team ~= gaia then
			teams[#teams + 1] = team
			history[team] = {}
			for _, series in ipairs(SERIES) do
				history[team][series] = {}
			end
			kills[team] = 0
			losses[team] = 0
		end
	end
end

function gadget:GameFrame(f)
	if not published and f % SAMPLE_FRAMES == 1 then
		Sample()
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, team, attackerID, attackerDefID, attackerTeam)
	if published then
		return
	end
	-- a unit that was never finished, or scrapped by its owner, is not a loss in battle
	if attackerTeam and attackerTeam ~= team and kills[attackerTeam] and losses[team] then
		if not Spring.AreTeamsAllied(attackerTeam, team) then
			kills[attackerTeam] = kills[attackerTeam] + 1
			losses[team] = losses[team] + 1
		end
	end
end

function gadget:GameOver()
	Publish()
end
