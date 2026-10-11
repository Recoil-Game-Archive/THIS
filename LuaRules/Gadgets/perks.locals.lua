--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spCallCOBScript        = Spring.CallCOBScript
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetTeamList          = Spring.GetTeamList
local spGetTeamUnits         = Spring.GetTeamUnits
local spSetUnitCOBValue      = Spring.SetUnitCOBValue
local spGetUnitDefID	     = Spring.GetUnitDefID
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Perks",
		desc = "don't leave the house without",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local perkCount =  tonumber(Spring.GetModOptions().perkcount) or 3

local perkList = include("LuaUI/perks/perks.lua")

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local function EnableWarhammer(team)
	GG.MakeSmallAvailable(team, UnitDefNames.warhammer.id)
end

local function MagShieldUser(team)
	GG.MagShieldUser(team)
end

local function GetEMP(team)
	GG.GetEMP(team)
end

local function CheckRadar(team)
	GG.CheckRadar(team)
end

local perks={}
local perkFunc={
	[5] = CheckRadar,
	[7] = EnableWarhammer,
	[8] = MagShieldUser,
	[10]= GetEMP,
}

local function PerkPicked(team, perk)
	local units= spGetTeamUnits(team)
	perks[team].left = perks[team].left - 1
	perks[team].have[perk] = true
	for _,u in ipairs(units) do
		if not Spring.UnitScript.GetScriptEnv(u) then
			spSetUnitCOBValue(u,2048+perk,1)
			break
		end
	end
	for _,u in ipairs(units) do
		local env = Spring.UnitScript.GetScriptEnv(u)
		if not env then
			spCallCOBScript(u, "NewPerk", 0, 2048+perk)
		elseif env and env.NewPerk then
			Spring.UnitScript.CallAsUnit(u, env.NewPerk, perk)
		end
	end
	if perkFunc[perk] then
		perkFunc[perk](team)
	end
	
	Spring.SetTeamRulesParam(team, "hasperk_"..perk, 1)
	Spring.SetTeamRulesParam(team, "perks_left", perks[team].left)
end

GG.PickPerk = PerkPicked

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("pickperk:",1,true) then
		local index = tonumber(msg:sub(10))
		local _,_,spec,team = Spring.GetPlayerInfo(playerID)
		if spec then return end
		if perks[team].left > 0 and not perks[team].have[index] and perkList[index] then
			PerkPicked(team, index)
		end
	end
end

function gadget:Initialize()
	local chickenTeamID
	local teams = Spring.GetTeamList()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
			chickenTeamID = teamID
		end
	end
	for _,t in ipairs(spGetTeamList()) do
		perks[t]={
			left = perkCount,
			have = {},
		}
	end
	--give the chicken team enough perks to choke a horse (so we can assign them without worrying about whether chickens have enough points)
	if (chickenTeamID) then
		perks[chickenTeamID].left = 20
	end
	for t,p in pairs(perks) do
		Spring.SetTeamRulesParam(t, "perks_left", p.left)
	end
	GG.perks = perks
	_G.perks = perks
end

else

--UNSYNCED
-- Perk state is published as team rules params (hasperk_<n>, perks_left)
-- and drawn by LuaUI.

return false

end
