function gadget:GetInfo()
	return {
		name      = "Unit Damaged Sound",
		desc      = "Plays impact sound whenever unit is damaged, based on the weapon type",
		author    = "ported from SplinterFaction",
		version   = "1",
		date      = "2023",
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Every folder in sounds/impacts/ is a class, every .wav / .ogg in it is one
-- variation. A weapon picks its class with customParams.impact_sounds;
-- gamedata/weapondefs_post.lua fills that in from the weapon's explosion
-- effect when the weapondef does not set it.
--
-- Weapons without a class use "generic", except beam lasers: they damage
-- their target every frame, so they only play an impact when a class is set
-- on them by hand. A class without any sound files falls back to "generic",
-- and the class "none" is always silent.
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return
end

-- Localisations
local random = math.random

-- Synced Read
local GetUnitPosition = Spring.GetUnitPosition

-- Unsynced Ctrl
local PlaySoundFile = Spring.PlaySoundFile

-- constants
local SOUNDS_PATH = "sounds/impacts/"
local SILENT_CLASS = "none"
local FALLBACK_CLASS = "generic"

-- variables
local soundClasses = {}     -- class -> { "cue1", "cue2", ... } (bare names, no extension)
local soundClassSizes = {}  -- class -> n
local wdSoundCache = {}     -- weaponDefID -> class

-- "sounds/impacts/kinetic/Ping1.wav" -> "ping1"; nil for anything that is not a sound
local function buildCueName(path)
	local name, ext = string.lower(path):gsub("\\", "/"):match("([^/]+)%.(%w+)$")
	if name and (ext == "wav" or ext == "ogg") then
		return name
	end
end

function gadget:Initialize()
	local subDirs = VFS.SubDirs(SOUNDS_PATH) or {}
	for i = 1, #subDirs do
		local class = string.lower(subDirs[i]):gsub("\\", "/"):match("([^/]+)/*$")
		if class and class:sub(1, 1) ~= "." then
			local files = VFS.DirList(subDirs[i]) or {}
			table.sort(files)
			local cues = {}
			for j = 1, #files do
				cues[#cues + 1] = buildCueName(files[j])
			end
			soundClasses[class] = cues
			soundClassSizes[class] = #cues
		end
	end

	local unknown = {}
	for weaponDefID, weaponDef in pairs(WeaponDefs) do
		local cp = weaponDef.customParams
		local class
		if cp and cp.impact_sounds then
			class = cp.impact_sounds
		elseif weaponDef.type ~= "BeamLaser" then
			class = FALLBACK_CLASS
		end
		if class and class ~= SILENT_CLASS then
			if not soundClasses[class] or soundClassSizes[class] == 0 then
				unknown[class] = true
				class = FALLBACK_CLASS
			end
			if soundClasses[class] and soundClassSizes[class] > 0 then
				wdSoundCache[weaponDefID] = class
			end
		end
	end
	-- classes that are in use but have no sound files yet
	local list = {}
	for class in pairs(unknown) do
		list[#list + 1] = class
	end
	if #list > 0 then
		table.sort(list)
		Spring.Echo("[Impact Sounds] no sound files in " .. SOUNDS_PATH .. " for: " .. table.concat(list, ", "))
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if attackerID and weaponDefID and projectileID then --Add this so that units who are destroyed via lua (like salvaging) or self destructed, will not play an overlapping sound effect
		local soundClass = wdSoundCache[weaponDefID]
		if soundClass then
			local choice = random(soundClassSizes[soundClass])
			local x, y, z = GetUnitPosition(unitID)
			if x then
				PlaySoundFile(soundClasses[soundClass][choice], 1, x, y, z, 'battle')
			end
		end
	end
end
