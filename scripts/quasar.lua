--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--include "damage.lua"
include "THIS.lua"

--local MY_ID = GetUnitValue(71)
--local unitDef = Spring.GetUnitDefID(unitID)
local unitTeam = Spring.GetUnitTeam(unitID)

local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitHealth = Spring.GetUnitHealth
local spEcho = Spring.Echo
local spSetWepState = Spring.SetUnitWeaponState
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
local spGetUnitScriptPiece = Spring.GetUnitScriptPiece
local spSetUnitStealth = Spring.SetUnitStealth
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc

local LaunchDroneAsWeapon = GG.LaunchDroneAsWeapon

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------

--core hull pieces
local hullMain = piece "hullmain"
local head = piece "head" 
local hullLeft = piece "hulll"
local hullRight = piece "hullr"
local hullAft = piece "hullaft"
local noseLeft = piece "nosel"
local noseRight = piece "noser"
local plateLeft = piece "platel"
local plateRight = piece "plater"

--main hull weapons
local turretBaseAM = piece "amturretbase"
local turretAM = piece "amturret"
local flareAM = piece "amflare"
local grav = piece "grav"
local droneLeft = piece "dronel"
local droneRight = piece "droner"
local bay0 = piece "bay0"
local bay1 = piece "bay1"
local megaLaser = piece "megalaser"

--kinetic
local turretKForeLeft = piece "kturret_fore_l"
local sleeveKForeLeft = piece "ksleeve_fore_l"
local barrel1KForeLeft = piece "kbarrel1_fore_l"
local barrel2KForeLeft = piece "kbarrel2_fore_l"
local flare1KForeLeft = piece "kflare1_fore_l"
local flare2KForeLeft = piece "kflare2_fore_l"

local turretKForeRight = piece "kturret_fore_r"
local sleeveKForeRight = piece "ksleeve_fore_r"
local barrel1KForeRight = piece "kbarrel1_fore_r"
local barrel2KForeRight = piece "kbarrel2_fore_r"
local flare1KForeRight = piece "kflare1_fore_r"
local flare2KForeRight = piece "kflare2_fore_r"

local turretKMidLeft = piece "kturret_mid_l"
local sleeveKMidLeft = piece "ksleeve_mid_l"
local barrel1KMidLeft = piece "kbarrel1_mid_l"
local barrel2KMidLeft = piece "kbarrel2_mid_l"
local flare1KMidLeft = piece "kflare1_mid_l"
local flare2KMidLeft = piece "kflare2_mid_l"

local turretKMidRight = piece "kturret_mid_r"
local sleeveKMidRight = piece "ksleeve_mid_r"
local barrel1KMidRight = piece "kbarrel1_mid_r"
local barrel2KMidRight = piece "kbarrel2_mid_r"
local flare1KMidRight = piece "kflare1_mid_r"
local flare2KMidRight = piece "kflare2_mid_r"

local turretKAftLeft = piece "kturret_aft_l"
local sleeveKAftLeft = piece "ksleeve_aft_l"
local barrel1KAftLeft = piece "kbarrel1_aft_l"
local barrel2KAftLeft = piece "kbarrel2_aft_l"
local flare1KAftLeft = piece "kflare1_aft_l"
local flare2KAftLeft = piece "kflare2_aft_l"

local turretKAftRight = piece "kturret_aft_r"
local sleeveKAftRight = piece "ksleeve_aft_r"
local barrel1KAftRight = piece "kbarrel1_aft_r"
local barrel2KAftRight = piece "kbarrel2_aft_r"
local flare1KAftRight = piece "kflare1_aft_r"
local flare2KAftRight = piece "kflare2_aft_r"

--PDLs
local turretPDFore = piece "lturret_fore"
local sleevePDFore = piece "lsleeve_fore"
local barrelPDFore = piece "lbarrel_fore"
local flarePDFore = piece "lflare_fore"

local turretPDLeft = piece "lturret_mid_l"
local sleevePDLeft = piece "lsleeve_mid_l"
local barrelPDLeft = piece "lbarrel_mid_l"
local flarePDLeft = piece "lflare_mid_l"

local turretPDRight = piece "lturret_mid_r"
local sleevePDRight = piece "lsleeve_mid_r"
local barrelPDRight = piece "lbarrel_mid_r"
local flarePDRight = piece "lflare_mid_r"

local turretPDAft = piece "lturret_aft"
local sleevePDAft = piece "lsleeve_aft"
local barrelPDAft = piece "lbarrel_aft"
local flarePDAft = piece "lflare_aft"

--plasma
local turretPLeft = piece "pturret_l"
local sleevePLeft = piece "psleeve_l"
local barrelPLeft = piece "pbarrel_l"
local flarePLeft  = piece "pflare_l"

local turretPRight = piece "pturret_r"
local sleevePRight = piece "psleeve_r"
local barrelPRight = piece "pbarrel_r"
local flarePRight = piece "pflare_r"

--missiles
local turretMLeft = piece "mturret_l"
local sleeveMLeft = piece "msleeve_l"
local pod1MLeft = piece "mpod1_l"
local pod2MLeft = piece "mpod2_l"
local flare1MLeft = piece "mflare1_l"
local flare2MLeft = piece "mflare2_l"

local turretMRight = piece "mturret_r"
local sleeveMRight = piece "msleeve_r"
local pod1MRight = piece "mpod1_r"
local pod2MRight = piece "mpod2_r"
local flare1MRight = piece "mflare1_r"
local flare2MRight = piece "mflare2_r"

--torpedoes
local torp1 = piece "torp1"
local torp2 = piece "torp2"
local torp3 = piece "torp3"
local torp4 = piece "torp4"
local torp5 = piece "torp5"
local torp6 = piece "torp6"

--------------------------------------------------------------------------------
--PIECE DEBUG

--[[local pieceList = {hullMain, head, hullLeft, hullRight, hullAft, noseLeft, noseRight, plateLeft, plateRight, turretBaseAM, turretAM, flareAM, grav, droneLeft, droneRight, megaLaser, turretKForeLeft, sleeveKForeLeft, barrel1KForeLeft, barrel2KForeLeft, flare1KForeLeft, flare2KForeLeft,turretKForeRight, sleeveKForeRight, barrel1KForeRight, barrel2KForeRight, flare1KForeRight, flare2KForeRight,turretKMidLeft, sleeveKMidLeft, barrel1KMidLeft, barrel2KMidLeft, flare1KMidLeft, flare2KMidLeft, turretKMidRight, sleeveKMidRight, barrel1KMidRight, barrel2KMidRight, flare1KMidRight, flare2KMidRight, turretKAftLeft, sleeveKAftLeft, barrel1KAftLeft, barrel2KAftLeft, flare1KAftLeft, flare2KAftLeft, turretKAftRight, sleeveKAftRight, barrel1KAftRight, barrel2KAftRight, flare1KAftRight, flare2KAftRight,turretPDFore, sleevePDFore, barrelPDFore, flarePDFore,turretPDLeft, sleevePDLeft, barrelPDLeft, flarePDLeft, turretPDRight, sleevePDRight, barrelPDRight, flarePDRight, turretPDAft, sleevePDAft, barrelPDAft, flarePDAft,turretPLeft, sleevePLeft, barrelPLeft, flarePLeft, turretPRight, sleevePRight, barrelPRight, flarePRight,turretMLeft, pod1MLeft, pod2MLeft, flare1MLeft, flare2MLeft,turretMRight, pod1MRight, pod2MRight, flare1MRight, flare2MRight,torp1, torp2, torp3, torp4, torp5, torp6}

local numPieces = # pieceList

spEcho("START OF DEBUG")
spEcho("Number of pieces: "..numPieces)
spEcho()

for i,v in pairs(pieceList) do
	for n=i, (numPieces) do
		if pieceList[n] == pieceList[i] and n ~= i then spEcho("Overlap detected: " .. pieceList[n] .. " at " .. n .. " and " .. i) end
	end
end

spEcho()
spEcho("DEBUG LIST:")
for i,v in pairs(pieceList) do spEcho(i.."/t"..v) end
spEcho()
spEcho("END OF DEBUG")
]]--
--------------------------------------------------------------------------------
-- default values
--------------------------------------------------------------------------------
local deathMed = 1024
local deathLarge = 1025
local deathMultiMed = 1026
local sparksFX = 1031
local damageFX = 1034
local muzzleFX = 1028

local numWeapons = 21

--milliseconds * 150
local graserChargeTime = 90
local graserFireTime = 150
local megaLaserChargeTime = 180
local megaLaserFireTime = 240

--these indexes aren't really used atm
local weaponIndex = {
	amPrimer = 1,
	am = 2,
	megaLaserPrimer = 3,
	grav = 4,
	kForeL = 5,
	kForeR = 6,
	kMidL = 7,
	kMidR = 8,
	kAftL = 9,
	kAftR = 10,
	pdFore = 11,
	pdL = 12,
	pdR = 13,
	pdAft = 14,
	gravFlak = 15,
	pL = 16,
	pR = 17,
	torp = 18,
	mL = 19,
	mR = 20,
	megaLaser = 21,
	drone = 22,
}

local turretIndex = {
	[1] = turretAM,
	[2] = turretAM,
	[3] = megaLaser,
	[4] = grav,
	[5] = turretKForeLeft,
	[6] = turretKForeRight,
	[7] = turretKMidLeft,
	[8] = turretKMidRight,
	[9] = turretKAftLeft,
	[10] = turretKAftRight,
	[11] = turretPDFore,
	[12] = turretPDLeft,
	[13] = turretPDRight,
	[14] = turretPDAft,
	[15] = grav,
	[16] = turretPLeft,
	[17] = turretPRight,
	[18] = hullMain,
	[19] = turretMLeft,
	[20] = turretMRight,
	[21] = megaLaser,
}

local sleeveIndex = {
	[1] = turretAM,
	[2] = turretAM,
	[3] = megaLaser,
	[4] = grav,
	[5] = sleeveKForeLeft,
	[6] = sleeveKForeRight,
	[7] = sleeveKMidLeft,
	[8] = sleeveKMidRight,
	[9] = sleeveKAftLeft,
	[10] = sleeveKAftRight,
	[11] = sleevePDFore,
	[12] = sleevePDLeft,
	[13] = sleevePDRight,
	[14] = sleevePDAft,
	[15] = grav,
	[16] = sleevePLeft,
	[17] = sleevePRight,
	[18] = hullMain,
	[19] = sleeveMLeft,
	[20] = sleeveMRight,
	[21] = megaLaser,
}

local turretMinHealth = {
	[1] = 0.5,
	[4] = 0.25,
	[5] = 0.6,
	[6] = 0.6,
	[7] = 0.25,
	[8] = 0.25,
	[9] = 0.45,
	[10] = 0.45,
	[11] = 0.55,
	[12] = 0.7,
	[13] = 0.7,
	[14] = 0.60,
	[15] = 0.25,
	[16] = 0.45,
	[17] = 0.45,
	[18] = 0.2,
	[19] = 0.5,
	[20] = 0.5,
	[21] = 0.65,
}

--randomize the numbers a bit
for i=1,numWeapons do
	local v = turretMinHealth[i]
	if v then v = v + math.random(-5,5)
	else v = 0 end
end

local function SetNoMinHealth()
	for i=1,numWeapons do turretMinHealth[i] = 0 end
end

local SIG_AMBeam = 2^22
local SIG_MegaLaser = 2^23

local dead = false

local fireStealthTime = 3000

local function DamageGFX()
	while true do
		health, maxHealth = spGetUnitHealth(unitID)
		for i=1,numWeapons do
			local minHealth = turretMinHealth[i] or 0
			if (health/maxHealth <= minHealth) then
				SetUnitValue(COB.CEG_DAMAGE, math.floor(25 - (health/maxHealth)*0.5))
				if sleeveIndex[i] then
					EmitSfx(sleeveIndex[i], damageFX)
				end
			end
		end
		Sleep(50)
	end
end

--------------------------------------------------------------------------------
--perks
--------------------------------------------------------------------------------
local perks = GG.perks

local function PerkLoop()
	while true do
		perks = GG.perks
		if perks then return end
		Sleep(33)
	end
end

local haveMoreGuns = perks and perks[unitTeam].have[perkMoreGuns] or false
local haveGravFlak = perks and perks[unitTeam].have[perkGravFlak] or false

local gravRangeBonus = 350

local function HideExtraGuns()
	Hide(grav)
	Hide(turretMLeft)
	Hide(pod1MLeft)
	Hide(pod2MLeft)
	Hide(turretMRight)
	Hide(pod1MRight)
	Hide(pod2MRight)
	Hide(turretPDFore)
	Hide(sleevePDFore)
	Hide(barrelPDFore)
end

local function ShowExtraGuns()
	Show(grav)
	Show(turretMLeft)
	Show(pod1MLeft)
	Show(pod2MLeft)
	Show(turretMRight)
	Show(pod1MRight)
	Show(pod2MRight)
	Show(turretPDFore)
	Show(sleevePDFore)
	Show(barrelPDFore)
end

function NewPerk(perk)
	if (perk == perkMoreGuns) then
		haveMoreGuns = true
		ShowExtraGuns()
	end
	if (perk == perkMassDriver) then
		for i=5,10 do	-- weapons 5-10
			local weaponState = CreateWeaponStateTable(unitID, i)
			weaponState["reloadTime"] = weaponState["reloadTime"] + (KMEDIUMD_ROF_BOOST/100)
			weaponState["sprayangle"] = KMEDIUM_SPRAY_BOOST
			spSetWepState(unitID, i, weaponState)
		end
		muzzleFX = 1029
	end
	if perk == perkGravRange then
		local weaponState = CreateWeaponStateTable(unitID, 5)
		weaponState["range"] = weaponState["range"] + gravRangeBonus
		spSetWepState(unitID, 4, weaponState)
		weaponState = CreateWeaponStateTable(unitID, 16)
		weaponState["range"] = weaponState["range"] + gravRangeBonus
		spSetWepState(unitID, 15, weaponState)
	end
	if perk == perkGravFlak then haveGravFlak = true end
end

--wanky workaround for getting new perks: wait for it every half second
--[[
local function GetPerkMassDriver()
	while not perks[unitTeam].have[perkMassDriver] do
		Sleep(500)
		if perks[unitTeam].have[perkMassDriver] then
			for i=5,10 do
				--GetUnitValue(WEAPON_SPRAY, -i,KMEDIUM_SPRAY_BOOST)
				--GetUnitValue(WEAPON_RELOADTIME, -i,KMEDIUM_ROF_BOOST)
				weaponState = createWeaponStateTable(unitID, i)
				weaponState["reloadTime"] = weaponState["reloadTime"] + (KMEDIUMD_ROF_BOOST/100)
				weaponState["sprayangle"] = KMEDIUM_SPRAY_BOOST
				spSetWepState(unitID, i, weaponState)
			end
			muzzleFX = 1029
			return
		end
	end
end

local function GetPerkMoreGuns()
	while not perks[unitTeam].have[perkMoreGuns] do
		Sleep(500)
		if perks[unitTeam].have[perkMoreGuns] then
			haveMoreGuns = true
			ShowExtraGuns()
			return
		end
	end
end

local function GetPerkGravRange()
	while not perks[unitTeam].have[perkGravRange] do
		Sleep(500)
		if perks[unitTeam].have[perkGravRange] then
			weaponState = createWeaponStateTable(unitID, 4)
			weaponState["range"] = weaponState["range"] + gravRangeBonus
			spSetWepState(unitID, 4, weaponState)
			weaponState = createWeaponStateTable(unitID, 15)
			weaponState["range"] = weaponState["range"] + gravRangeBonus
			spSetWepState(unitID, 15, weaponState)
			return
		end
	end
end]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetDroneTarget()
	local commands = spGetUnitCommands(unitID)
	local target
	if commands == 0 then
		target = commands[0][params] or -1
	else target = -1 end
	return target
end

local function DroneSpawnLoop()
	local minHealth = turretMinHealth[22] or 0
	local health, maxHealth
	Sleep(1000)
	while true do
		--pause drone launching if damage threshold exceeded
		health, maxHealth = spGetUnitHealth(unitID)
		while (health/maxHealth <= minHealth) do
			Sleep(500)
			EmitSfx(droneLeft, 1031)
			EmitSfx(droneRight, 1031)
			health, maxHealth = spGetUnitHealth(unitID)
		end	
		if dead then return end
		--local target = GetDroneTarget()
		local target = GetUnitValue(COB.TARGET_ID, 18)	-- drones go after torpedo target
		LaunchDroneAsWeapon(unitID, nil, spGetUnitTeam(unitID), target, DRONE_K, droneLeft, -90, 0)
		LaunchDroneAsWeapon(unitID, nil, spGetUnitTeam(unitID), target, DRONE_K, droneRight, 90, 0)
		Sleep(10000)
	end
end

local function SetWeaponPerks()
	if (not haveMoreGuns) then HideExtraGuns() end
	if perks then
		if perks[unitTeam].have[perkMassDriver] then
			for i=4,9 do
				--GetUnitValue(WEAPON_SPRAY, -i,KMEDIUM_SPRAY_BOOST)
				--GetUnitValue(WEAPON_RELOADTIME, -i,KMEDIUM_ROF_BOOST)
				local weaponState = CreateWeaponStateTable(unitID, i)
				weaponState["reloadTime"] = weaponState["reloadTime"] + (KMEDIUMD_ROF_BOOST/100)
				weaponState["sprayangle"] = KMEDIUM_SPRAY_BOOST
				spSetWepState(unitID, i, weaponState)
			end
			muzzleFX = 1029
		end
		if perks[unitTeam].have[perkGravRange] then
			local weaponState = CreateWeaponStateTable(unitID, 4)
			weaponState["range"] = weaponState["range"] + gravRangeBonus
			spSetWepState(unitID, 4, weaponState)
			weaponState = CreateWeaponStateTable(unitID, 15)
			weaponState["range"] = weaponState["range"] + gravRangeBonus
			spSetWepState(unitID, 15, weaponState)
		end
	end
	--StartThread(GetPerkMoreGuns)
	--StartThread(GetPerkMassDriver)
	--StartThread(GetPerkGravRange)
end

local function TurnPieceInit()
	Turn(turretPLeft, y_axis, dirBack)
	Turn(turretPRight, y_axis, dirBack)
	Turn(turretKAftLeft, y_axis, dirBack)
	Turn(turretKAftRight, y_axis, dirBack)
	Turn(turretPDAft, y_axis, dirBack)
	
	Turn(droneLeft, y_axis, dirLeft)
	Turn(droneRight, y_axis, dirRight)
	
	Turn(torp1, y_axis, dirLeft)
	Turn(torp3, y_axis, dirLeft)
	Turn(torp5, y_axis, dirLeft)
	
	Turn(torp2, y_axis, dirRight)
	Turn(torp4, y_axis, dirRight)
	Turn(torp6, y_axis, dirRight)
	
	Move(megaLaser, z_axis, 1)
	--Move(flareAM, z_axis, 1)
	Hide(megaLaser)
	Hide(flareAM)
end

local function SetDGunCMD()
	local cmd = spFindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	local desc = {
		name = "MLaser",
		tooltip = "Megalaser: Fires an intense energy beam that obliterates anything in its path\nThe laser is hull-mounted and can only be aimed at large ships",
		type = CMDTYPE.ICON_UNIT_OR_MAP,
		texture = "&.1x.1&bitmaps/icons/megalaser.png&bitmaps/icons/frame_slate_128x96.png",
		onlyTexture = false,
	}
	if cmd then spEditUnitCmdDesc(unitID, cmd, desc) end
end

function script.Create()
	if not perks then StartThread(PerkLoop) end
	TurnPieceInit()	
	SetNoMinHealth()
	SetDGunCMD()
	Sleep(30)
	
	EmitSfx(hullMain, 1027)
	EmitSfx(hullAft, 1027)
	EmitSfx(megaLaser, 1027)
	--EmitSfx(droneLeft, 1027)
	--EmitSfx(droneRight, 1027)
	SetWeaponPerks()
	StartThread(DroneSpawnLoop)
	StartThread(DamageGFX)
end

local function RestoreStealth()
	Signal(SIG_RestoreStealth)
	SetSignalMask(SIG_RestoreStealth)
	Sleep(fireStealthTime)
	if not isMoving then spSetUnitStealth(unitID, true) end
end

function script.StartMoving()
	spSetUnitStealth(unitID, false)
	isMoving = true
end

function script.StopMoving()
	StartThread(RestoreStealth)
	isMoving = false
end

--------------------------------------------------------------------------------
--aiming code
--------------------------------------------------------------------------------
local mRad = math.rad

local turretSpeedK = mRad(180)
local sleeveSpeedK = mRad(120)
local turretSpeedP = mRad(60)
local sleeveSpeedP = mRad(40)
local turretSpeedM = mRad(120)
local podSpeedM = mRad(80)

local gun1, gun2, gun3, gun4, gun5, gun6, miss1, miss2 = false, false, false, false, false, false, false, false

local firingMegaLaser = false

local function AimTurret(heading, pitch, turret, sleeve, turretSpeed, sleeveSpeed, weaponNum)
	local SIG_AIM = 2^(weaponNum - 1)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	local minHealth = turretMinHealth[weaponNum] or 0
	local health, maxHealth = spGetUnitHealth(unitID)
	if (health/maxHealth) < minHealth then
		EmitSfx(sleeve, 1031)
		Sleep(500)
		return false
	end
	Turn(turret, y_axis, heading, turretSpeed)
	Turn(sleeve, x_axis, -pitch, sleeveSpeed)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	return true
end

local function AimWeaponKinetic(heading, pitch, turret, sleeve, weaponNum)
	return AimTurret(heading, pitch, turret, sleeve, turretSpeedK, sleeveSpeedK, weaponNum)
end

local function AimWeaponInstant(weaponNum, turret)
	local minHealth = turretMinHealth[weaponNum] or 0
	local health, maxHealth = spGetUnitHealth(unitID)
	if health/maxHealth < minHealth then
		EmitSfx(turret, sparksFX)
		Sleep(500)
		return false
	end
	return true
end

local function AimTorpedo()
	local minHealth = turretMinHealth[18] or 0
	local health, maxHealth = spGetUnitHealth(unitID)
	if health/maxHealth < minHealth then
		EmitSfx(torp1, sparksFX)
		EmitSfx(torp2, sparksFX)
		EmitSfx(torp3, sparksFX)
		EmitSfx(torp4, sparksFX)
		EmitSfx(torp5, sparksFX)
		EmitSfx(torp6, sparksFX)
		Sleep(500)
		return false
	end
	return true
end

function script.AimFromWeapon(weaponNum)
	--spEcho("Aiming weapon "..weaponNum)
	
	if turretIndex[weaponNum] then return turretIndex[weaponNum]
	else return hullMain end
	--[[legacy code
	if weaponNum == 1 or weaponNum == 2 then return turretAM
	elseif weaponNum == 3 or weaponNum == 21 then return megaLaser
	elseif weaponNum == 4 or weaponNum == 15 then return grav
	elseif weaponNum == 5 then return turretKForeLeft
	elseif weaponNum == 6 then return turretKForeRight
	elseif weaponNum == 7 then return turretKMidLeft
	elseif weaponNum == 8 then return turretKMidRight
	elseif weaponNum == 9 then return turretKAftLeft
	elseif weaponNum == 10 then return turretKAftRight
	elseif weaponNum == 11 then return turretPDFore
	elseif weaponNum == 12 then return turretPDLeft
	elseif weaponNum == 13 then return turretPDRight
	elseif weaponNum == 14 then return turretPDAft
	elseif weaponNum == 16 then return turretPLeft
	elseif weaponNum == 17 then return turretPRight
	elseif weaponNum == 18 then return hullMain
	elseif weaponNum == 19 then return turretMLeft
	elseif weaponNum == 20 then return turretMRight end
	return hullMain	--make sure the function has something to return
	]]--
end

function script.QueryWeapon(weaponNum)
	--spEcho("Querying weapon "..weaponNum)
	if weaponNum == 1 or weaponNum == 2 then return flareAM
	elseif weaponNum == 3 or weaponNum == 21 then return megaLaser
	elseif weaponNum == 4 or weaponNum == 15 then return grav
	elseif weaponNum == 5 then
		if gun1 then return flare1KForeLeft end
		return flare2KForeLeft
	elseif weaponNum == 6 then 
		if gun2 then return flare1KForeRight end
		return flare2KForeRight
	elseif weaponNum == 7 then 
		if gun3 then return flare1KMidLeft end
		return flare2KMidLeft
	elseif weaponNum == 8 then 
		if gun4 then return flare1KMidRight end
		return flare2KMidRight
	elseif weaponNum == 9 then 
		if gun5 then return flare1KAftLeft end
		return flare2KAftLeft
	elseif weaponNum == 10 then 
		if gun6 then return flare1KAftRight end
		return flare2KAftRight
	elseif weaponNum == 11 then return flarePDFore
	elseif weaponNum == 12 then return flarePDLeft
	elseif weaponNum == 13 then return flarePDRight
	elseif weaponNum == 14 then return flarePDAft
	elseif weaponNum == 16 then return flarePLeft
	elseif weaponNum == 17 then return flarePRight
	elseif weaponNum == 18 then return hullMain
	elseif weaponNum == 19 then
		if miss1 then return pod1MLeft end
		return pod2MLeft
	elseif weaponNum == 20 then
		if miss2 then return pod1MRight end
		return pod2MRight
	end
	return hullMain
end

function script.AimWeapon(weaponNum, heading, pitch)
	--spEcho("Aiming weapon "..weaponNum)
	--aim AM beam
	if weaponNum == 1 then
		turnSpeed = mRad(90)
		pitchSpeed = mRad(60)
		return AimTurret(heading, pitch, turretAM, turretAM, turnSpeed , pitchSpeed, 1)
	--aim gravitrics
	elseif weaponNum == 4 then
		if (not haveMoreGuns) then return false end
		return AimWeaponInstant(4, grav)
	elseif weaponNum == 15 then
		if (not haveMoreGuns or not perks[unitTeam].have[perkGravFlak]) then return false	end
		return AimWeaponInstant(15, grav)
	--aim kinetics and PDLs
	elseif (weaponNum >= 5 and weaponNum <= 10) or (weaponNum >= 12 and weaponNum <= 14) then
		return AimWeaponKinetic(heading, pitch, turretIndex[weaponNum], sleeveIndex[weaponNum], weaponNum)
	elseif weaponNum == 11 then
		if (not haveMoreGuns) then return false	end
		return AimWeaponKinetic(heading, pitch, turretPDFore, sleevePDFore, 11)
	--aim plasma cannons
	elseif weaponNum == 16 then return AimTurret(heading, pitch, turretPLeft, sleevePLeft, turretSpeedP, sleeveSpeedP, 16)
	elseif weaponNum == 17 then return AimTurret(heading, pitch, turretPRight, sleevePRight, turretSpeedP, sleeveSpeedP, 17)
	--aim drone launcher and torps
	elseif weaponNum == 18 then return AimTorpedo()
	elseif weaponNum == 19 then
		if (not haveMoreGuns) then return false end
		return AimTurret(heading, pitch, turretMLeft, sleeveMLeft, turretSpeedM, sleeveSpeedM, 19)
	elseif weaponNum == 20 then
		if (not haveMoreGuns) then return false end
		return AimTurret(heading, pitch, turretMRight, sleeveMRight, turretSpeedM, sleeveSpeedM, 20)
	end
	return false
end

local function FireAMBeam()
	Signal(SIG_AMBeam)
	SetSignalMask(SIG_AMBeam)
	for i=0,graserChargeTime do
		SetUnitValue(COB.CEG_DAMAGE,i/2)
		EmitSfx(flareAM, 1024 + 6)
		Sleep(30)
	end
	for i=0,graserFireTime do
		Sleep(30)
		EmitSfx(flareAM, 2048 + 1)
	end
	StartThread(RestoreStealth)
end

local function FireMegaLaser()
	firingMegaLaser = true
	Signal(SIG_MegaLaser)
	SetSignalMask(SIG_MegaLaser)
	--open nose
	Move(noseLeft, x_axis, 20, 20)
	Move(noseRight, x_axis, -20, 20)
	WaitForMove(noseLeft, x_axis)
	WaitForMove(noseRight, x_axis)
	Sleep(500)
	--charge
	for i=0,megaLaserChargeTime do
		SetUnitValue(COB.CEG_DAMAGE,i/2)
		EmitSfx(megaLaser, 1024 + 8)
		Sleep(30)
	end
	--fire
	for i=0,megaLaserFireTime do
		Sleep(30)
		EmitSfx(megaLaser, 2048 + 20)
	end
	--close nose
	Sleep(500)
	Move(noseLeft, x_axis, 0, 20)
	Move(noseRight, x_axis, 0, 20)
	WaitForMove(noseLeft, x_axis)
	WaitForMove(noseRight, x_axis)
	StartThread(RestoreStealth)
	firingMegaLaser = false
end

local function FireTorpedoes()
	local target = GetUnitValue(COB.TARGET_ID, 18)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp5, -90, 30)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp6, 90, 30)
	Sleep(150)
	target = GetUnitValue(COB.TARGET_ID, 18)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp3, -90, 30)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp4, 90, 30)
	Sleep(150)
	target = GetUnitValue(COB.TARGET_ID, 18)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp1, -90, 30)
	LaunchDroneAsWeapon(unitID, nil, unitTeam, target, TORPEDO, torp2, 90, 30)
end

function script.FireWeapon(weaponNum)
	--spEcho("Firing weapon "..weaponNum)
	if weaponNum == 1 then
		StartThread(FireAMBeam)
	elseif weaponNum == 3 then
		StartThread(FireMegaLaser)
	elseif weaponNum == 18 then
		--local target = GetDroneTarget()
		FireTorpedoes()
		Sleep(1000)
		FireTorpedoes()
	end
end

function script.Shot(weaponNum)
	if weaponNum == 5 then
		if(gun1) then
			EmitSfx(flare1KForeLeft, muzzleFX)
		else
			EmitSfx(flare2KForeLeft, muzzleFX)
		end
		gun1 = not gun1
	elseif weaponNum == 6 then
		if(gun2) then
			EmitSfx(flare1KForeRight, muzzleFX)
		else
			EmitSfx(flare2KForeRight, muzzleFX)
		end
		gun2 = not gun2
	elseif weaponNum == 7 then
		if(gun3) then
			EmitSfx(flare1KMidLeft, muzzleFX)
		else
			EmitSfx(flare2KMidLeft, muzzleFX)
		end
		gun3 = not gun3
	elseif weaponNum == 8 then
		if(gun3) then
			EmitSfx(flare1KMidRight, muzzleFX)
		else
			EmitSfx(flare2KMidRight, muzzleFX)
		end
		gun4 = not gun4
	elseif weaponNum == 9 then
		if(gun5) then
			EmitSfx(flare1KAftLeft, muzzleFX)
		else
			EmitSfx(flare2KAftLeft, muzzleFX)
		end
		gun5 = not gun5
	elseif weaponNum == 10 then
		if(gun6) then
			EmitSfx(flare1KAftRight, muzzleFX)
		else
			EmitSfx(flare2KAftRight, muzzleFX)
		end
		gun6 = not gun6
	elseif weaponNum == 19 then miss1 = not miss1
	elseif weaponNum == 20 then miss2 = not miss2
	end
end

function script.BlockShot(weaponNum, targetID, userTarget)
	if weaponNum ~= 18 then return false end
	if targetID == nil or targetID < 1 or targetID == unitID then return true end
	return false
end

--------------------------------------------------------------------------------
--death
--------------------------------------------------------------------------------
local shatter = SFX.SHATTER

local function ExplodeAftPieces()
	Explode(turretKAftLeft, shatter)
	Explode(turretKAftRight, shatter)
	Explode(sleeveKAftLeft, shatter)
	Explode(sleeveKAftRight, shatter)
	Explode(barrel1KAftLeft, shatter)
	Explode(barrel2KAftLeft, shatter)
	Explode(barrel1AftRight, shatter)
	Explode(barrel2KAftRight, shatter)
end

local function ExplodeNosePieces()
end

local function ExplodeSidePieces()
end

function script.Killed(recentDamage, maxHealth)
	dead = true
	local mrad = math.rad

	EmitSfx(head, deathLarge)
	--Turn(hullMain,x_axis,10,mr(1))
	Turn(hullMain,z_axis,math.random(-5,5),mrad(1))
	Sleep(700)
	
	Move(hullAft,z_axis,-90,12)
	Move(plateLeft,x_axis,90,15)
	Move(plateRight,x_axis,-90,15)
	Spin(plateLeft,z_axis,mrad(10))
	Spin(plateRight,z_axis,mrad(-16))
	EmitSfx(hullAft, deathMultiMed)
	EmitSfx(grav, deathMed)
	Sleep(1000)
			
	Move(hullLeft,x_axis,90,12)
	Move(hullRight,x_axis,-90,12)
	Spin(hullLeft,z_axis,mrad(8))
	Spin(hullRight,z_axis,mrad(-5))
	Sleep(1400)
	EmitSfx(turretAM, deathLarge)
	Sleep(200)
	EmitSfx(plateLeft, deathMed)
	EmitSfx(plateRight, deathMed)
	Hide(plateLeft)
	Hide(plateRight)
	--Hide(hullAft)
	--ExplodeAftPieces()
	--Explode(plateLeft)
	--Explode(plateRight)
	
	EmitSfx(hullMain, deathMultiMed)
	Sleep(200)
	EmitSfx(hullLeft, deathLarge)
	EmitSfx(hullRight, deathLarge)
	Sleep(250)
	EmitSfx(noseLeft, deathMed)
	EmitSfx(noseRight, deathMed)
	Sleep(1000)	

	Hide(noseLeft)
	Hide(noseRight)
	--ExplodeNosePieces()
	EmitSfx(hullMain, deathMed)
	EmitSfx(hullLeft, deathLarge)
	Sleep(250)
	EmitSfx(hullRight, deathLarge)
	Sleep(1100)	
	--Hide(hullLeft)
	--Hide(hullRight)
	--ExplodeSidePieces()
	EmitSfx(hullMain, deathMultiMed)
	Sleep(600)
	EmitSfx(head, deathMed)
	Sleep(1500)	
	EmitSfx(hullMain, 1033)
	EmitSfx(hullLeft, 1033)
	EmitSfx(hullRight, 1033)
	EmitSfx(hullAft, 1033)
	Sleep(300)
end
