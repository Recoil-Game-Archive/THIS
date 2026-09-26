
include "constants.lua"

dirBack = math.rad(180)
dirLeft = math.rad(90)
dirRight = math.rad(-90)

perkMassDriver = 1
perkMoreGuns = 2
perkGravRange = 6
perkGravFlak = 12

PERK_BETTER_KINETICS = 2049

KLIGHT_ROF_BOOST = 16
KLIGHT_SPRAY_BOOST = 50
KDUAL_ROF_BOOST = 12
KLIGHT_DUAL_BOOST = 100
KMEDIUM_ROF_BOOST = 48
KMEDIUMD_ROF_BOOST = 16
KMEDIUM_SPRAY_BOOST = 50
KHEAVY_ROF_BOOST = 96
KHEAVY_SPRAY_BOOST = 10
PERK_MORE_GUNS = 2050
PERK_BETTER_GRAV = 2054
GSTANDARD_RANGE_BOOST = 650
PERK_GRAV_FLAK = 2060
GFLAK_RANGE_BOOST = 650
PERK_ANTIMATTER_WARHEAD = 2059

DRONE_K = 1
TORPEDO = 2
FTORPEDO = 3

--[[
SIG_Aim1 = 1
SIG_Aim2 = 2
SIG_Aim3 = 4
SIG_Aim4 = 8
SIG_Aim5 = 16
SIG_Aim6 = 32
SIG_Aim7 = 64
SIG_Damage = 128
SIG_RestoreStealth = 256
]]--

--[[SIG_Aim1 = 1
SIG_Aim2 = 2
SIG_Aim3 = 4
SIG_Aim4 = 8
SIG_Aim5 = 16
SIG_Aim6 = 32
SIG_Aim7 = 64
SIG_Aim8 = 128
SIG_Aim9 = 256
SIG_Aim10 = 512
SIG_Aim11 = 1024
SIG_Aim12 = 2048
SIG_Aim13 = 4096
SIG_Aim14 = 8192
SIG_Aim15 = 16384
SIG_Aim16 = 32768
SIG_Aim17 = 65536
SIG_Aim18 = 131072
SIG_Aim19 = 262144
SIG_Aim20 = 524288]]

SIG_Damage = 1048576
SIG_RestoreStealth = 2097152

--[[SoundDefs() {
	play-sound ("deathsmall",1);
	S_DEATH_SMALL 0
	play-sound ("deathmed",1);
	S_DEATH_MED 1
	play-sound ("deathlarge",1);
	S_DEATH_LARGE 2
}
]]--

--function LaunchDroneWeapon()
--	return 0;
--end

--TRAIL(p,width,ttl,rate) = EngineEnabled

spSetUnitStealth = Spring.SetUnitStealth

fireStealthTime = 1000
permaStealth = false

function RestoreStealth()
	Signal(SIG_RestoreStealth)
	SetSignalMask(SIG_RestoreStealth)
	Sleep(fireStealthTime)
	if (not isMoving) then spSetUnitStealth(unitID,true) end
end

function script.MoveRate(rate)
	if rate > 0 then
		if not permaStealth then StartThread(RestoreStealth) end
		if (EngineEnabled) then
			--RemoveTrail(p)
			EngineEnabled = 0
		end
	else
		if not permaStealth then spSetUnitStealth(unitID,false) end
		if (not EngineEnabled) then
			--AddTrail(p,width,ttl,rate)
			EngineEnabled = 1
		end
	end
end

function CreateWeaponStateTable(a, b)
	local getWep = Spring.GetUnitWeaponState
	local weaponState = {
	    reloadState = getWep(a,b,"reloadState"),
		reloadTime  = getWep(a,b,"reloadTime"),
		accuracy   = getWep(a,b,"Accuracy"),
		sprayAngle  = getWep(a,b,"sprayAngle"),
		range       = getWep(a,b,"range"),
		projectileSpeed = getWep(a,b,"projectileSpeed"),
		burst = getWep(a,b,"burst"),
		burstRate = getWep(a,b,"burstRate"),
		projectiles = getWep(a,b,"projectiles"),
	}
	return weaponState
end

function NewPerk(perk)
	--just so it doesn't call a non-existent function; each ship should have its own implementation of this function
end
