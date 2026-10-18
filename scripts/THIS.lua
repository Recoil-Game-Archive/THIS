
include "constants.lua"

dirBack = math.rad(180)
dirLeft = math.rad(90)
dirRight = math.rad(-90)

perkMassDriver = 1
perkMoreGuns = 2
perkGravRange = 6
perkGravFlak = 12
perkAntiMatter = 11

DRONE_K = 1
TORPEDO = 2
FTORPEDO = 3

SIG_Damage = 1048576
SIG_RestoreStealth = 2097152

spSetUnitStealth = Spring.SetUnitStealth

fireStealthTime = 1000
permaStealth = false

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
end--]]

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
