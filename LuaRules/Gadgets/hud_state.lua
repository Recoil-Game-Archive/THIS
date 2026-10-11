--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Publishes the state the HUD needs as rules params, so that LuaUI never has
--  to reach into SYNCED tables and no gadget has to draw to the screen.
--
--  Team rules params (visible to the team, its allies and spectators):
--    money          credits, rounded down
--    income         credits gained in the last second
--    gb_current     unitDefID of the large ship being built, 0 = none
--    gb_progress    0..1 progress of that build
--    gb_ready       unitDefID of the large ship waiting to be placed, 0 = none
--    gb_queue       queued large ships as "defID,defID,...", "" = empty
--
--  Team rules params (visible to the team and spectators only):
--    alert_text     current message, see message.locals.lua
--    alert_hint     second line of that message
--    alert_until    game frame at which the message expires
--
--  Set elsewhere: hasperk_<n> and perks_left (perks.locals.lua),
--                 defeat_frame (endGame.locals.lua).
--
--  Unit rules params on carriers, minelayers and hangars (team and allies):
--    build_current  unitDefID being built, 0 = none
--    build_progress 0..1 progress of that build
--    build_queue    queued units as "defID,defID,...", "" = empty
--    build_repeat   1 if the queue repeats, else 0
--
--  Game rules params (public, like the planet rings themselves):
--    planet_count
--    planet_<i>_x, planet_<i>_z
--    planet_<i>_owner   teamID holding the planet, -1 = none or contested
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "HUD State",
		desc = "Publishes game state as rules params for LuaUI",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 100, -- after money, planets, build, message and perks
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetGameRulesParam = Spring.SetGameRulesParam
local floor = math.floor
local concat = table.concat

local ALLIED = {allied = true}
local PRIVATE = {private = true}

local PERIOD = 6      -- game frames; matches BUILD_PERIOD in build.locals.lua
local MAX_QUEUE = 64  -- longest queue written into a param

local teams = {}
local teamCache = {}
local unitCache = {}
local planetOwner = {}
local planetsPublished = false

local function SetTeam(team, key, value, access)
	local cache = teamCache[team]
	if cache[key] ~= value then
		cache[key] = value
		spSetTeamRulesParam(team, key, value, access)
	end
end

local function SetUnit(unitID, cache, key, value)
	if cache[key] ~= value then
		cache[key] = value
		spSetUnitRulesParam(unitID, key, value, ALLIED)
	end
end

-- build queues are linked lists: {build = unitDefID, next = node or false}
local function EncodeQueue(node)
	local ids, n = {}, 0
	while node and n < MAX_QUEUE do
		n = n + 1
		ids[n] = node.build
		node = node.next
	end
	return concat(ids, ",")
end

local function Progress(p)
	p = p or 0
	if p >= 1 then
		return 1
	elseif p <= 0 then
		return 0
	end
	return floor(p * 1000 + 0.5) / 1000
end

local function PublishTeams()
	local money, income = GG.money, GG.lastIncome
	local globalbuild, ready, message = GG.globalbuild, GG.ready, GG.message
	for i = 1, #teams do
		local team = teams[i]
		if money and money[team] then
			SetTeam(team, "money", floor(money[team]), ALLIED)
		end
		if income and income[team] then
			SetTeam(team, "income", income[team], ALLIED)
		end
		local gb = globalbuild and globalbuild[team]
		if gb then
			SetTeam(team, "gb_current", gb.current or 0, ALLIED)
			SetTeam(team, "gb_progress", gb.current and Progress(gb.progress) or 0, ALLIED)
			SetTeam(team, "gb_ready", ready and ready[team] or 0, ALLIED)
			SetTeam(team, "gb_queue", EncodeQueue(gb.first), ALLIED)
		end
		local m = message and message[team]
		if m then
			SetTeam(team, "alert_text", m.text or "", PRIVATE)
			SetTeam(team, "alert_hint", m.hint or "", PRIVATE)
			SetTeam(team, "alert_until", m.timeout or 0, PRIVATE)
		end
	end
end

local function PublishBuilders()
	local buildstate = GG.buildstate
	if not buildstate then
		return
	end
	for unitID, b in pairs(buildstate) do
		local cache = unitCache[unitID]
		if not cache then
			cache = {}
			unitCache[unitID] = cache
		end
		SetUnit(unitID, cache, "build_current", b.current or 0)
		SetUnit(unitID, cache, "build_progress", b.current and Progress(b.progress) or 0)
		SetUnit(unitID, cache, "build_queue", EncodeQueue(b.first))
		SetUnit(unitID, cache, "build_repeat", b.Repeat and 1 or 0)
	end
	for unitID in pairs(unitCache) do
		if not buildstate[unitID] then
			unitCache[unitID] = nil
		end
	end
end

local function PublishPlanets()
	local planets = GG.planets
	if not planets then
		return
	end
	if not planetsPublished then
		local count = 0
		for i, p in pairs(planets) do
			count = count + 1
			spSetGameRulesParam("planet_" .. i .. "_x", p.x)
			spSetGameRulesParam("planet_" .. i .. "_z", p.z)
		end
		spSetGameRulesParam("planet_count", count)
		planetsPublished = true
	end
	for i, p in pairs(planets) do
		local owner = p.lastOwner or -1
		if planetOwner[i] ~= owner then
			planetOwner[i] = owner
			spSetGameRulesParam("planet_" .. i .. "_owner", owner)
		end
	end
end

local function Publish()
	PublishTeams()
	PublishBuilders()
	PublishPlanets()
end

function gadget:Initialize()
	teams = Spring.GetTeamList()
	for i = 1, #teams do
		teamCache[teams[i]] = {}
	end
	Publish()
end

function gadget:GameFrame(f)
	if f % PERIOD == 0 then
		Publish()
	end
end
