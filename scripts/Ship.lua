-- Generic ship script
info = GG.lusHelper[unitDefID]
body = piece("body") -- global for the killed animation include
ex = piece("ex") -- global for the init animation include
local grav = piece("grav")
local base = piece("base")

include "THIS.lua"

function DamageLoop()
	if not info.damages[1] then return end -- carrier.bos seems to have no smoke/damage loop?
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
afterBurnSpeed = 0

function MoveRate(rate)
	if rate == 0 then
		if permaStealth == 0 then
			isMoving = 0
			StartThread(RestoreStealth)
		end
		if EngineEnabled ~= 0 then
			if GG.RemoveTrail and ex then GG.RemoveTrail(unitID, unitDefID, teamID, ex - 1) end
			EngineEnabled = 0
		end
	elseif rate > 0 then
		if permaStealth == 0 then
			isMoving = 1
			SetUnitValue(COB.STEALTH, 0)
		end
		if EngineEnabled == 0 then
			if GG.AddTrail and ex then 
				GG.AddTrail(unitID, unitDefID, teamID, ex - 1, info.trail.width, info.trail.ttl, info.trail.rate) 
			end
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
	elseif p == perkGravRange then
		local weapNum = next(info.gravitics) -- just get the first one, next one will be FLAK
		Spring.SetUnitWeaponState(unitID, weapNum, "range", GSTANDARD_RANGE_BOOST)
		Spring.SetUnitWeaponState(unitID, weapNum+1, "range", GFLAK_RANGE_BOOST)
	end
end

local anims = "anims/" .. unitDef.name .. ".lua"
if VFS.FileExists("scripts/" .. anims) then 
	--Spring.Echo("LUS found an animation file for", unitDef.name)
	include(anims)
end

function script.Create()
	fireStealthTime = info.fireStealthTime -- TODO: due to being in the THIS.lua include
	for i, pieceNum in pairs(info.extras) do
		GG.RecursiveHide(unitID, pieceNum, true)
	end
	for perk in pairs(teamPerks.have) do
		NewPerk(perk)
	end
	if Init then
		StartThread(Init)
	end
end

function script.HitByWeapon(x_, z_, id, damage)
	StartThread(DamageLoop)
	return damage
end

local currGPs = {}

function script.AimWeapon(weapNum, heading, pitch)
	Signal(2^weapNum)
	SetSignalMask(2^weapNum)
	if info.moreGuns == weapNum and not teamPerks.have[perkMoreGuns] then return false end
	if info.gravitics[weapNum] and info.gravitics[weapNum-1] then return teamPerks.have[perkGravFlak] end
	if info.gravitics[weapNum] then return true end
	if info.torpedos[weapNum] then return true end
	local hPiece = info.pivotIDs[weapNum] or info.turretIDs[weapNum] or info.barrelIDs[weapNum]
	if hPiece then Turn(hPiece, y_axis, heading, info.headingAims[weapNum]) end
	local pPiece = info.sleeveIDs[weapNum] or info.barrelIDs[weapNum]
	if not pPiece and info.gBarrelIDs[weapNum] then
		currGPs[weapNum] = (currGPs[weapNum] or 1)
		pPiece = info.gBarrelIDs[weapNum][currGPs[weapNum]]
	end
	if pPiece then Turn(pPiece, x_axis, -pitch, info.pitchAims[weapNum]) end
	if hPiece then WaitForTurn(hPiece, y_axis) end
	if pPiece then WaitForTurn(pPiece, x_axis) end
	return true
end

function script.AimFromWeapon(weapNum)
	if info.gravitics[weapNum] then return grav end
	return info.sleeveIDs[weapNum] or info.turretIDs[weapNum] or info.pivotIDs[weapNum] or body
end

function script.QueryWeapon(weapNum)
	if info.gravitics[weapNum] then return grav end
	if info.gpIDs[weapNum] then -- a switching gun point
		return info.gpIDs[weapNum][currGPs[weapNum] or 1]
	end
	return info.flareIDs[weapNum] or base or body
end

function script.FireWeapon(weapNum)
	local torpedoType = info.torpedos[weapNum]
	if torpedoType then
		local tType, tUser, tUnitID = Spring.GetUnitWeaponTarget(unitID, weapNum)
		if tType > 0 and GG.LaunchDroneAsWeapon then
			if volley and volley == 1 then VolleyTorpedos(tUnitID) else
				for wave, tPieces in pairs(info.torpedoPieces) do
					local launcherPieces = info.torpedoLaunchers and info.torpedoLaunchers[wave]
					for i, tPiece in pairs(tPieces) do
						GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, tUnitID, torpedoType, tPiece, 0, info.torpedoPitch)
						if launcherPieces then
							Move(launcherPieces[i], z_axis, -1.5, 10)
						end
					end
					Sleep(300) -- between each wave
					if launcherPieces then
						for i, launcherPiece in pairs(launcherPieces) do
							Move(launcherPiece, z_axis, 0, 0.4)
						end
					end
				end
			end
		end
	end
end

function script.Shot(weapNum)
	if info.gpIDs[weapNum] then -- a switching gun point
		currGPs[weapNum] = (currGPs[weapNum] or 0) + 1
		if currGPs[weapNum] > info.numGPs[weapNum] then
			currGPs[weapNum] = 1
		end
	end
	if info.plasmas[weapNum] or info.gravitics[weapNum] then
		SetUnitValue(COB.STEALTH, 0)
		StartThread(RestoreStealth)
		-- currently only plasma seem to have barrel recoil so put it here to avoid recoiling kinetics
		local recoilDist = info.barrelRecoilDist[weapNum]
		if recoilDist then
			local bPiece = info.barrelIDs[weapNum] or info.gBarrelIDs[weapNum][currGPs[weapNum]]
			Move(bPiece, z_axis, -recoilDist, 180) -- TODO: claymore was originally instant
			Sleep(400)
			Move(bPiece, z_axis, 0, 25) -- TODO: claymore was originally 2
		end
	end
	if info.kinetics[weapNum] then
		local emitPiece = currGPs[weapNum] and info.gpIDs[weapNum][currGPs[weapNum]] or info.flareIDs[weapNum]
		GG.EmitSfxName(unitID, emitPiece, teamPerks.have[perkMassDriver] and "muzzlemassdriver" or "muzzlekinetic")
	end
end

function script.BlockShot(weapNum, targetID, userTarget)
	if info.torpedos[weapNum] then 
		--Spring.Echo("BlockShot torpedo", targetID)
		return targetID == nil
	end
	return false
end