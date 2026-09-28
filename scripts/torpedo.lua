-- scripts/torpedo.bos converted from BOS by coilbox.

-- Unit values 1024 to 8191 were numbers BOS scripts shared: 8 per unit, 64 per
-- team, 64 per allyteam and 4096 for the whole game. The engine stopped keeping
-- them in Spring 102.0, so these keep them as rules params, which gadgets and
-- widgets can read too: cobUnitVar<n> on the unit, cobTeamVar<n> on the team,
-- cobAllyVar<n> on every team in the allyteam and cobGlobalVar<n> on the game,
-- with n counted from 0. lualibs/cob_vars.lua reads and writes the same ones
-- through Spring.GetCOBTeamVar, Spring.SetUnitCOBValue and their siblings.
--
-- Recoil builds its Lua with numbers as C floats, so a value beyond 16777216
-- rounds, the same as it would anywhere else in a Lua unit script. A packed
-- map position is usually beyond that.
local cobAllied = { allied = true }

-- get, keeping the shared values. A unit value with a positive first argument
-- reads that unit's, and with a negative one sets that unit's to the second.
-- Any other id goes to the engine.
local function cobGet(id, ...)
	if id >= 1024 and id <= 1031 then
		local p1, p2 = ...
		p1 = p1 or 0
		local name = "cobUnitVar" .. (id - 1024)
		if p1 == 0 then
			return Spring.GetUnitRulesParam(unitID, name) or 0
		elseif p1 > 0 then
			return Spring.GetUnitRulesParam(p1, name) or 0
		elseif Spring.ValidUnitID(-p1) then
			Spring.SetUnitRulesParam(-p1, name, p2 or 0, cobAllied)
			return 1
		end
		return 0
	elseif id >= 2048 and id <= 2111 then
		return Spring.GetTeamRulesParam(Spring.GetUnitTeam(unitID), "cobTeamVar" .. (id - 2048)) or 0
	elseif id >= 3072 and id <= 3135 then
		return Spring.GetTeamRulesParam(Spring.GetUnitTeam(unitID), "cobAllyVar" .. (id - 3072)) or 0
	elseif id >= 4096 and id <= 8191 then
		return Spring.GetGameRulesParam("cobGlobalVar" .. (id - 4096)) or 0
	end
	return GetUnitValue(id, ...)
end


local base = piece("base")
local trail = piece("trail")

-- Start of THIS.h
local PERK_BETTER_KINETICS = 2049
local KLIGHT_ROF_BOOST = 16
local KLIGHT_SPRAY_BOOST = 50
local KDUAL_ROF_BOOST = 12
local KLIGHT_DUAL_BOOST = 100
local KMEDIUM_ROF_BOOST = 48
local KMEDIUMD_ROF_BOOST = 24
local KMEDIUM_SPRAY_BOOST = 50
local KHEAVY_ROF_BOOST = 96
local KHEAVY_SPRAY_BOOST = 10
local PERK_MORE_GUNS = 2050
local PERK_BETTER_GRAV = 2054
local GSTANDARD_RANGE_BOOST = 42598400
local PERK_GRAV_FLAK = 2060
local GFLAK_RANGE_BOOST = 42598400
local PERK_ANTIMATTER_WARHEAD = 2059
local DRONE_K = 1
local TORPEDO = 2
local FTORPEDO = 3

local SIG_Aim1 = 1
local SIG_Aim2 = 2
local SIG_Aim3 = 4
local SIG_Aim4 = 8
local SIG_Aim5 = 16
local SIG_Aim6 = 32
local SIG_Aim7 = 64
local SIG_Aim8 = 128
local SIG_Aim9 = 256
local SIG_Aim10 = 512
local SIG_Aim11 = 1024
local SIG_Aim12 = 2048
local SIG_Aim13 = 4096
local SIG_Aim14 = 8192
local SIG_Aim15 = 16384
local SIG_Aim16 = 32768
local SIG_Aim17 = 65536
local SIG_Aim18 = 131072
local SIG_Aim19 = 262144
local SIG_Aim20 = 524288
local SIG_Damage = 1048576
local SIG_RestoreStealth = 2097152

-- SoundDefs() {
-- play-sound ("deathsmall",1);
-- #define S_DEATH_SMALL 0
-- play-sound ("deathmed",1);
-- #define S_DEATH_MED 1
-- play-sound ("deathlarge",1);
-- #define S_DEATH_LARGE 2
-- }
local isMoving = 0

local fireStealthTime = 0

local permaStealth = 0

function RestoreStealth()
	Signal(SIG_RestoreStealth)
	SetSignalMask(SIG_RestoreStealth)
	BosSleep(fireStealthTime)
	if isMoving == 0 then
		SetUnitValue(COB.STEALTH, 1)
	end
end

function lua_AddTrail()
	return 0
end

function lua_RemoveTrail()
	return 0
end

function lua_LaunchDroneWeapon()
	return 0
end

function lua_GetGameFrame()
	return 0
end
-- End of THIS.h

function DamageLoop()
	Signal(SIG_Damage)
	SetSignalMask(SIG_Damage)
	while GetUnitValue(COB.HEALTH) < 50 do
		SetUnitValue(COB.CEG_DAMAGE, 25 - div(GetUnitValue(COB.HEALTH), 2))
		EmitSfx(base, 1024)
		if GetUnitValue(COB.HEALTH) < 30 then
			EmitSfx(trail, 1024)
		end
		Sleep(50)
	end
end

local EngineEnabled = 0

function MoveRate0()
	if permaStealth == 0 then
		isMoving = 0
		StartThread(RestoreStealth)
	end
	if EngineEnabled ~= 0 then
		if GG.RemoveTrail then GG.RemoveTrail(unitID, unitDefID, Spring.GetUnitTeam(unitID), trail - 1) end
		EngineEnabled = 0
	end
end

function MoveRate1()
	if permaStealth == 0 then
		isMoving = 1
		SetUnitValue(COB.STEALTH, 0)
	end
	if EngineEnabled == 0 then
		if GG.AddTrail then GG.AddTrail(unitID, unitDefID, Spring.GetUnitTeam(unitID), trail - 1, 1, 64, 2) end
		EngineEnabled = 1
	end
end

function MoveRate2()
	MoveRate1()
end

function script.Create()
	permaStealth = 1
	Sleep(1)
	Turn(trail, y_axis, math.rad(90))
	StartThread(MoveRate1)
	Sleep(12000)
	GetUnitValue(COB.KILL_UNIT)
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025)
	Hide(base)
	if cobGet(PERK_ANTIMATTER_WARHEAD) ~= 0 then
		EmitSfx(base, 4097)
	end
	return 0
end

function script.QueryWeapon()
	return base
end

function script.FireWeapon()
	GetUnitValue(COB.KILL_UNIT, 0, 1)
end

function script.AimWeapon(weapNum, heading, pitch)
	return false
end

function script.AimFromWeapon()
	return base
end

-- The engine's call-ins, handed on to the functions above.

function script.MoveRate(rate)
	if rate == 0 then
		MoveRate0()
	elseif rate == 1 then
		MoveRate1()
	elseif rate == 2 then
		MoveRate2()
	end
end
