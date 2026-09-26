-- Generic ship script
info = GG.lusHelper[unitDefID]

local body = piece("body")
local ex = piece("ex")

include "THIS.lua"

function DamageLoop()
	Signal(SIG_Damage)
	SetSignalMask(SIG_Damage)
	while GetUnitValue(COB.HEALTH) < 50 do
		SetUnitValue(COB.CEG_DAMAGE, 25 - math.floor(GetUnitValue(COB.HEALTH) / 2))
		EmitSfx(info.damages[1], 1024)
		if GetUnitValue(COB.HEALTH) < 30 then
			EmitSfx(info.damages[2], 1024)
		end
		Sleep(50)
	end
end

local EngineEnabled = 0

function MoveRate(rate)
	if rate == 0 then
		if permaStealth == 0 then
			isMoving = 0
			StartThread(RestoreStealth)
		end
		if EngineEnabled ~= 0 then
			if GG.RemoveTrail then GG.RemoveTrail(unitID, unitDefID, Spring.GetUnitTeam(unitID), ex - 1) end
			EngineEnabled = 0
		end
	elseif rate > 0 then
		if permaStealth == 0 then
			isMoving = 1
			SetUnitValue(COB.STEALTH, 0)
		end
		if EngineEnabled == 0 then
			if GG.AddTrail then GG.AddTrail(unitID, unitDefID, Spring.GetUnitTeam(unitID), ex - 1, 5, 128, 16) end
			EngineEnabled = 1
		end
	end
end

local teamPerks = GG.perks[teamID]

function NewPerk(p)
	if p == perkMoreGuns then
		for i, pieceNum in pairs(info.extras) do
			GG.RecursiveHide(unitID, pieceNum, false)
		end
	elseif p == perkMassDriver then
		for weapNum, data in pairs(info.kinetics) do
			Spring.SetUnitWeaponState(unitID, weapNum, "reloadTime", data.rofBoost / 30)
			Spring.SetUnitWeaponState(unitID, weapNum, "sprayangle", data.sprayBoost)
		end
	end
end

function script.Create()
	fireStealthTime = 2000
	for i, pieceNum in pairs(info.extras) do
		GG.RecursiveHide(unitID, pieceNum, true)
	end
	for perk in pairs(teamPerks.have) do
		NewPerk(perk)
	end
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
end



function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end

function script.HitByWeapon(x_, z_, id, damage)
	StartThread(DamageLoop)
	return damage
end

local currGPs = {}

function script.AimWeapon(weapNum, heading, pitch)
	if info.moreGuns[weapNum] and not teamPerks.have[perkMoreGuns] then return false end
	
	Signal(2^weapNum)
	SetSignalMask(2^weapNum)
	local hPiece = info.pivotIDs[weapNum] or info.turretIDs[weapNum]
	if hPiece then
		Turn(hPiece, y_axis, heading, math.rad(90))
	end
	local pPiece = info.sleeveIDs[weapNum] or info.barrelIDs[weapNum]
	if not pPiece then
		if info.gBarrelIDs[weapNum] then
			currGPs[weapNum] = (currGPs[weapNum] or 1)
			pPiece = info.gBarrelIDs[weapNum][currGPs[weapNum]]
		else
			--Spring.Echo("no pPiece for weapon", weapNum)
			return false
		end
	end
	Turn(pPiece, x_axis, -pitch, math.rad(90))
	if hPiece then WaitForTurn(hPiece, y_axis) end
	WaitForTurn(pPiece, x_axis)
	return true
end

function script.AimFromWeapon(weapNum)
	return info.sleeveIDs[weapNum] or info.turretIDs[weapNum] or info.pivotIDs[weapNum] or body
end

function script.QueryWeapon(weapNum)
	if info.gpIDs[weapNum] then -- a switching gun point
		currGPs[weapNum] = (currGPs[weapNum] or 0) + 1
		if currGPs[weapNum] > info.numGPs[weapNum] then
			currGPs[weapNum] = 1
		end
		--Spring.Echo(unitDef.name, "QueryWeapon GP", weapNum)
		return info.gpIDs[weapNum][currGPs[weapNum]]
	end
	return info.flareIDs[weapNum]
end

function script.Shot(weapNum)
	if info.breakStealths[weapNum] then
		SetUnitValue(COB.STEALTH, 0)
		StartThread(RestoreStealth)
	end
	if info.kinetics[weapNum] then
		local emitPiece = currGPs[weapNum] and info.gpIDs[weapNum][currGPs[weapNum]] or info.flareIDs[weapNum]
		GG.EmitSfxName(unitID, emitPiece, teamPerks.have[perkMassDriver] and "muzzlemassdriver" or "muzzlekinetic")
	end
	local recoilDist = info.barrelRecoilDist[weapNum]
	if recoilDist then
		Move(info.barrelIDs[weapNum], z_axis, -recoilDist)
		Sleep(400)
		Move(info.barrelIDs[weapNum], z_axis, 0, 2)
	end
end