function gadget:GetInfo()
	return {
		name = "LUS - Helper",
		desc = "Parses UnitDef and Model data for LUS",
		author = "FLOZi (C. Lawrence)",
		date = "Adapted for THIS from MCL 19/09/26",
		license = "GNU GPL v2",
		layer = 2, -- must be after flagManager
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

-- Localisations
local modOptions = Spring.GetModOptions()
-- Synced Read
local GetUnitPieceInfo 		= Spring.GetUnitPieceInfo
local GetUnitPieceMap		= Spring.GetUnitPieceMap

-- Variables
GG.lusHelper = {}

--[[
-- functions for determining weapon placement
local function IsPieceAncestor(unitID, pieceName, ancestor, strict)
	local pieceMap = GetUnitPieceMap(unitID)
	local parent = GetUnitPieceInfo(unitID, pieceMap[pieceName]).parent
	if (strict and parent == ancestor) or (not strict and parent:find(ancestor)) then 
		return true, parent
	elseif parent == "[null]" then
		return false, parent
	else
		return IsPieceAncestor(unitID, parent, ancestor, strict)
	end
end

local function FindPieceProgenitor(unitID, pieceName, extra)
	-- order matters here, we want to return turret even if that turret is then attached to body
	local progenitors = {"lwing", "rwing", "rotory", "turret", "emitter", "trackr", "trackl", "body"}
	if extra then
		table.insert(progenitors, 1, extra) -- put any extra pieces at the start (highest priority)
	end
	for _, progenitor in ipairs(progenitors) do
		if pieceName:find(progenitor) then return pieceName end -- return the piece
		local found, parent = IsPieceAncestor(unitID, pieceName, progenitor, false)
		if found then return parent end 
	end
	return nil
end--]]

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	--env = Spring.UnitScript.GetScriptEnv(unitID)
	--if not env then return end
	local info = GG.lusHelper[unitDefID]
	local ud = UnitDefs[unitDefID]
	--Spring.Echo("UnitCreated!", info, ud.name)
	local cp = ud.customParams
	info.builderID = builderID
	if info.firstTime == nil then
		info.firstTime = true -- only do this step once
		--Spring.Echo("UnitCreated firstTime", info, ud.name)
		-- Parse Model Data
		local pieceMap = GetUnitPieceMap(unitID)

		info.pivotIDs = {} -- whole ship pivots to fire
		info.turretIDs = {} -- weapon housed in turret_<weaponnum>
		info.sleeveIDs = {}
		info.barrelIDs = {}
		
		info.flareIDs = {} -- flare_x for single barrels
		info.gpIDs = {} -- gp_x_y for alternating points
		info.numGPs = {}
		info.gBarrelIDs = {} -- gbarrel_x_y for alternating barrels
		info.numGBarrels = {}
		
		info.torpedoPieces = {} -- tp_wave_y
		info.torpedoLaunchers = {} -- torp_wave_y
		info.dronePieces = {} -- drone_wave_y
		
		info.damages = {}
		info.bays = {}
		
		info.extras = {}
		
       	for pieceName, pieceNum in pairs(pieceMap) do
			local weapNumPos = pieceName:find("_") or 0
			local weapNumEndPos = pieceName:find("_", weapNumPos+1) or 0
			local weaponNum = tonumber(pieceName:sub(weapNumPos+1,weapNumEndPos-1) or -1)
			if pieceName:find("pivot_") then
				info.pivotIDs[weaponNum] = pieceNum
			elseif pieceName:find("turret_") then
				info.turretIDs[weaponNum] = pieceNum
			elseif pieceName:find("sleeve_") then
				info.sleeveIDs[weaponNum] = pieceNum
			elseif pieceName:find("gbarrel_") then
				info.numGBarrels[weaponNum] = (info.numGBarrels[weaponNum] or 0) + 1
				info.gBarrelIDs[weaponNum] = info.gBarrelIDs[weaponNum] or {}
				info.gBarrelIDs[weaponNum][info.numGBarrels[weaponNum]] = pieceNum
			elseif pieceName:find("gp_") then
				info.numGPs[weaponNum] = (info.numGPs[weaponNum] or 0) + 1
				info.gpIDs[weaponNum] = info.gpIDs[weaponNum] or {}
				info.gpIDs[weaponNum][info.numGPs[weaponNum]] = pieceNum
			elseif pieceName:find("barrel_") then
				info.barrelIDs[weaponNum] = pieceNum
			elseif pieceName:find("flare_") then
				info.flareIDs[weaponNum] = pieceNum
			elseif pieceName:find("tp") then
				info.torpedoPieces[weaponNum] = info.torpedoPieces[weaponNum] or {}
				table.insert(info.torpedoPieces[weaponNum], pieceNum)
			elseif pieceName:find("torp") then
				info.torpedoLaunchers[weaponNum] = info.torpedoLaunchers[weaponNum] or {}
				table.insert(info.torpedoLaunchers[weaponNum], pieceNum) -- TODO: Danger will robinson! assumes same order as the flare pieces
			elseif pieceName:find("drone") then
				info.dronePieces[weaponNum] = info.dronePieces[weaponNum] or {}
				table.insert(info.dronePieces[weaponNum], pieceNum)
			elseif pieceName:find("damage") then
				table.insert(info.damages, pieceNum)
			elseif pieceName:find("bay") then
				table.insert(info.bays, pieceNum)
			elseif pieceName:find("extra") then
				table.insert(info.extras, pieceNum)
			end
		end
	end
end

function gadget:GamePreload()
	-- Parse UnitDef Data
	for unitDefID, unitDef in pairs(UnitDefs) do
		local preload = unitDef.model.midx -- access model to force preloading
		local info = {}
		local cp = unitDef.customParams
		local weapons = unitDef.weapons
		
		-- WeaponDef Level Info
		info.burstLengths = {}
		info.reloadTimes = {}
		info.torpedos = {}
		info.plasmas = {}
		info.kinetics = {}
		info.gravitics = {}
		for i = 1, #weapons do
			local weaponInfo = weapons[i]
			local weaponDef = WeaponDefs[weaponInfo.weaponDef]
			local weapCP = weaponDef.customParams
			info.reloadTimes[i] = weaponDef.reload
			info.burstLengths[i] = weaponDef.salvoSize
			info.torpedos[i] = tonumber(weapCP.torpedotype)
			info.plasmas[i] = weaponDef.description:find("Plasma")
			info.gravitics[i] = weaponDef.description:find("Grav")
			local kinetic = weaponDef.description:find("Kinetic")
			if kinetic then
				info.kinetics[i] = {
					sprayBoost = weapCP.spray_boost,
					rofBoost = weapCP.rof_boost,
				}
			end
		end
	
		-- UnitDef Level Info
		info.numWeapons = #weapons
		info.torpedoPitch = math.rad(tonumber(cp.torpedopitch) or 0)
		info.headingAims = {}
		info.pitchAims = {}
		for i = 1, #weapons do
			info.headingAims[i] = math.rad(tonumber(cp["headingaim" .. i]) or math.deg(info.headingAims[i-1] or math.pi/2))
			info.pitchAims[i] = math.rad(tonumber(cp["pitchaim" .. i]) or math.deg(info.pitchAims[i-1] or math.pi/2))
		end
		info.barrelRecoilSpeed = (tonumber(cp.barrelrecoilspeed) or 100)
		info.barrelRecoilDist = {}
		if cp.barrelrecoildist then
			info.barrelRecoilDist[1] = tonumber(cp.barrelrecoildist) --table.unserialize(cp.barrelrecoildist)
		end
		info.moreGuns = tonumber(cp.moreguns) --table.unserialize(cp.moreguns)
		info.fireStealthTime = tonumber(cp.firestealthtime or 1000)
		info.trail = {
			width	= tonumber(cp.trailwidth or 1),
			ttl		= tonumber(cp.trailttl or 1),
			rate	= tonumber(cp.trailrate or 1),
		}
		-- And finally, stick it in GG for the script to access
		GG.lusHelper[unitDefID] = info
	end
end

function gadget:Initialize()
	gadget:GamePreload()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

else
-- UNSYNCED
return false end