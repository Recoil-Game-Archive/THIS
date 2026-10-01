-- Torpedo script
local base = piece("base")
local trail = piece("trail")

local forwardsTorp = unitDef.name == "ftorpedo"

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

function script.Create()
	SetUnitValue(COB.STEALTH, 0)
	Sleep(1)
	Turn(trail, y_axis, math.rad(90))
	if GG.AddTrail then GG.AddTrail(unitID, unitDefID, teamID, trail-1, 1, 64, 2) end
	Sleep(forwardsTorp and 6000 or 12000)
	GetUnitValue(COB.KILL_UNIT)
end

local perkAntiMatter = 11
local teamPerks = GG.perks[teamID]

function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025) -- fires weapon 1, regular torpedo?
	Hide(base)
	if teamPerks.have[perkAntiMatter] then
		EmitSfx(base, 4097) -- explodes weapon 2, AM warhead
	end
	return 0
end

function script.QueryWeapon()
	return base
end

--[[function script.FireWeapon()
	GetUnitValue(COB.KILL_UNIT, 0, 1)
end]]

function script.AimWeapon(weapNum, heading, pitch)
	return false
end

function script.AimFromWeapon()
	return base
end
