function gadget:GetInfo()
	return {
		name    = "Randomised Death Sounds (refactor)",
		desc    = "Assign and play classes of unit death sounds",
		author  = "FLOZi (C. Lawrence), refactor by Scary le Poo",
		date    = "2025-09-02",
		license = "Public Domain",
		layer   = 1,
		enabled = true
	}
end

--------------------------------------------------------------------------------
-- Every folder in sounds/deathsounds/ is a class, every .wav / .ogg in it is
-- one variation. A unit picks its class with customParams.death_sounds;
-- gamedata/unitdefs_post.lua fills that in from the unit's type when the
-- unitdef does not set it. A class without any sound files falls back to
-- "generic", and the class "none" is always silent.
--
-- Variations are drawn from a shuffle bag, so a class never plays the same
-- file twice in a row and cycles through all of its files before repeating.
--
-- Only units killed by an attacker make a sound; self destruction and units
-- removed by Lua (torpedoes hitting, decoys, the end of the game) stay quiet.
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return
end

local random           = math.random
local GetUnitPosition  = Spring.GetUnitPosition
local PlaySoundFile    = Spring.PlaySoundFile

local SOUNDS_PATH = "sounds/deathsounds/"
local SILENT_CLASS = "none"
local FALLBACK_CLASS = "generic"

-- Built at init:
local classCues   = {}   -- class -> { "cue1", "cue2", ... } (bare names, no extension)
local classSizes  = {}   -- class -> n
local unitClass   = {}   -- unitDefID -> class

-- Shuffle bag state:
local shuffleBags = {}   -- class -> { idx1, idx2, ... } (a stack; we pop from the end)
local lastIdx     = {}   -- class -> last index used (for cross-bag no-repeat)

-- "sounds/deathsounds/small/Boom1.wav" -> "boom1"; nil for anything that is not a sound
local function buildCueName(path)
	local name, ext = string.lower(path):gsub("\\", "/"):match("([^/]+)%.(%w+)$")
	if name and (ext == "wav" or ext == "ogg") then
		return name
	end
end

local function refillBag(class)
	local n = classSizes[class]
	if not n or n == 0 then
		shuffleBags[class] = {}
		return
	end
	local bag = {}
	for i = 1, n do bag[i] = i end
	-- Fisher–Yates
	for i = n, 2, -1 do
		local j = random(i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	-- Ensure first draw after refill won't repeat the last draw from previous bag
	-- We pop from the END, so "first draw" is bag[#bag]
	if n > 1 and lastIdx[class] and bag[#bag] == lastIdx[class] then
		bag[#bag], bag[1] = bag[1], bag[#bag]
	end
	shuffleBags[class] = bag
end

function gadget:Initialize()
	-- Discover classes and cues
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
			classCues[class]  = cues
			classSizes[class] = #cues
		end
	end

	-- Map unitDef -> class (folder), defaulting to "generic" if missing/empty
	local unknown = {}
	for unitDefID, ud in pairs(UnitDefs) do
		local class = (ud.customParams and ud.customParams.death_sounds) or FALLBACK_CLASS
		if class ~= SILENT_CLASS then
			if not classCues[class] or classSizes[class] == 0 then
				if class ~= FALLBACK_CLASS then
					unknown[class] = true
				end
				class = FALLBACK_CLASS
			end
			if classCues[class] and classSizes[class] > 0 then
				unitClass[unitDefID] = class
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
		Spring.Echo("[Death Sounds] no sound files in " .. SOUNDS_PATH .. " for: " .. table.concat(list, ", "))
	end

	-- Make initial bags
	for class, _ in pairs(classCues) do
		refillBag(class)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
	if not attackerID then return end

	local class = unitClass[unitDefID]
	if not class then return end

	local bag = shuffleBags[class]
	if not bag or #bag == 0 then
		refillBag(class)
		bag = shuffleBags[class]
		if #bag == 0 then return end -- still empty? bail safely
	end

	-- Draw: pop last index (O(1))
	local idx = bag[#bag]
	bag[#bag] = nil
	lastIdx[class] = idx

	local cue = classCues[class][idx]
	if not cue then return end

	local x, y, z = GetUnitPosition(unitID)
	if x then
		PlaySoundFile(cue, 1, x, y, z, 'battle')
	end
end
