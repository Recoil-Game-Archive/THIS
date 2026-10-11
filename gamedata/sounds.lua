--------------------------------------------------------------------------------
-- Sound items
--
-- Every .wav / .ogg below sounds/ becomes a sound item named after the file,
-- lowercase and without folder or extension:
--
--     sounds/weapons/klightfire.wav  ->  "klightfire"
--
-- That bare name is what weapon defs (soundStart / soundHit), the sound
-- gadgets and Spring.PlaySoundFile use. Because the folder is not part of
-- the name, a file name may only be used once in the whole sounds/ tree;
-- duplicates are reported in infolog.txt and the first one found wins.
--
-- The folder decides how the sound is mixed. A folder without an entry in
-- `categories` uses the settings of the closest parent folder that has one,
-- so e.g. a new sounds/deathsounds/<class>/ folder works without touching
-- this file. See sounds/README.md for what goes where.
--
--   gain          loudness, 1 = as recorded
--   gainmod       random loudness variation per play (0..1)
--   pitchmod      random pitch variation per play (0..1)
--   dopplerscale  0 disables doppler
--   maxconcurrent how many copies of this one sound may play at once
--   rolloff       how fast it fades with distance, 0 = same volume everywhere
--   priority      higher survives when the mixer runs out of channels
--------------------------------------------------------------------------------

local SOUND_ROOT = "sounds/"

local categories = {
	-- fallback for files directly in sounds/ or in a folder not listed here
	[""] = {
		gain = 1.0,
		gainmod = 0.06,
		maxconcurrent = 8,
		dopplerscale = 0,
		rolloff = 0.5,
	},

	-- interface clicks, chat, map pings: flat, never positional
	["ui"] = {
		gain = 0.15,
		gainmod = 0,
		dopplerscale = 0,
		maxconcurrent = 8,
		rolloff = 0,
		in3d = false,
	},

	-- order acknowledgements played by gui_soundeffects (cmd_*)
	["commands"] = {
		gain = 0.3,
		gainmod = 0.06,
		dopplerscale = 0,
		maxconcurrent = 32,
		rolloff = 0,
		priority = 1,
	},

	-- the layered unit sounds played by gui_soundeffects (sel_* / mov_* / wpn_*)
	["unitselections"] = {
		gain = 0.1,
		gainmod = 0.06,
		dopplerscale = 0,
		maxconcurrent = 2,
		rolloff = 0,
		priority = 1,
	},

	-- weapon fire and weapon hit sounds (soundStart / soundHit)
	["weapons"] = {
		gain = 0.525,
		gainmod = 0.06,
		pitchmod = 0.02,
		maxconcurrent = 16,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},

	-- same, for the few weapons that have to cut through everything
	["weaponsloud"] = {
		gain = 1.5,
		gainmod = 0.06,
		maxconcurrent = 16,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},

	-- explosions that belong to a weapon rather than to a dying unit
	["explosions"] = {
		gain = 0.9,
		gainmod = 0.06,
		pitchmod = 0.02,
		maxconcurrent = 7,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},

	-- hull hits, one folder per class, played by unit_impact_sounds
	["impacts"] = {
		gain = 0.9,
		gainmod = 0.06,
		pitchmod = 0.03,
		maxconcurrent = 7,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},

	-- unit deaths, one folder per class, played by unit_death_sounds
	["deathsounds"] = {
		gain = 1.2,
		gainmod = 0.06,
		pitchmod = 0.03,
		maxconcurrent = 7,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},
	["deathsounds/small"] = {
		gain = 0.9,
		gainmod = 0.06,
		pitchmod = 0.04,
		maxconcurrent = 7,
		dopplerscale = 1.0,
		rolloff = 0.5,
	},
	["deathsounds/large"] = {
		gain = 1.5,
		gainmod = 0.06,
		pitchmod = 0.03,
		maxconcurrent = 4,
		dopplerscale = 1.0,
		rolloff = 0.4,
		priority = 1,
	},
	["deathsounds/huge"] = {
		gain = 2.0,
		gainmod = 0,
		pitchmod = 0.02,
		maxconcurrent = 2,
		dopplerscale = 0,
		rolloff = 0.2,
		priority = 2,
	},

	-- cloak, repair and other one-off unit effects
	["misc"] = {
		gain = 0.36,
		gainmod = 0.06,
		maxconcurrent = 7,
		dopplerscale = 1.0,
		rolloff = 0.5,
		in3d = true,
	},
}

-- Names the engine itself plays. Each one is only defined once its file
-- exists in sounds/ui/, so a missing file is silence rather than an error.
local engineSounds = {
	IncomingChat = "chat",        -- a chat message arrives
	MultiSelect  = "multiselect", -- several units get selected at once
	MapPoint     = "mappoint",    -- somebody places a map marker
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Sounds = {
	SoundItems = {},
}

local function Warn(msg)
	if Spring and Spring.Echo then
		Spring.Echo("[sounds.lua] " .. msg)
	end
end

local function Normalize(path)
	return (string.lower(path):gsub("\\", "/"))
end

-- settings of the closest listed folder at or above `dir` ("" = sounds/ itself)
local function CategoryFor(dir)
	while true do
		if categories[dir] then
			return categories[dir]
		end
		if dir == "" then
			return {}
		end
		dir = dir:match("^(.*)/[^/]*$") or ""
	end
end

local function AddDirectory(fullDir)
	local dir = Normalize(fullDir)
	local relative = dir:sub(#SOUND_ROOT + 1):gsub("/+$", "")
	local attributes = CategoryFor(relative)

	local files = VFS.DirList(fullDir) or {}
	table.sort(files)
	for i = 1, #files do
		local file = files[i]
		local name, ext = Normalize(file):match("([^/]+)%.(%w+)$")
		if name and (ext == "wav" or ext == "ogg") then
			if Sounds.SoundItems[name] then
				Warn("duplicate sound name '" .. name .. "': " .. file ..
					" is ignored, " .. Sounds.SoundItems[name].file .. " is used")
			else
				local item = { file = file }
				for key, value in pairs(attributes) do
					item[key] = value
				end
				Sounds.SoundItems[name] = item
			end
		end
	end

	local subDirs = VFS.SubDirs(fullDir) or {}
	table.sort(subDirs)
	for i = 1, #subDirs do
		AddDirectory(subDirs[i])
	end
end

AddDirectory(SOUND_ROOT)

for engineName, soundName in pairs(engineSounds) do
	local item = Sounds.SoundItems[soundName]
	if item then
		local copy = {}
		for key, value in pairs(item) do
			copy[key] = value
		end
		Sounds.SoundItems[engineName] = copy
	end
end

return Sounds
