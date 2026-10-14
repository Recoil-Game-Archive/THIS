--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Music player.
--
--  Plays the .ogg files found in the music/ folder (of the game, and of the
--  player's own data directory), one after the other in a shuffled order.
--  It has no window of its own: the game menu shows the track name with
--  previous, pause and next, through WG.thisMusic.
--
--  The volume is the engine's music volume (snd_volmusic), set in Settings;
--  50% when it has never been set. It is applied to every stream as it
--  starts (the engine would otherwise play it at full volume until the
--  slider is moved).
--  If you pause the music, it stays paused the next time you play.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Music",
		desc = "Plays the .ogg files in music/; controls are in the game menu",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local MUSIC_DIR = "music"
local CHECK_INTERVAL = 0.5
-- a track that has not started after this many seconds is skipped
local START_TIMEOUT = 5
-- the next track starts this long before the end of the current one is reported
local END_MARGIN = 0.25

local tracks = {}        -- {path = ..., name = ...}, in playing order
local current = 0        -- index into tracks, 0 = nothing chosen yet
local streaming = false  -- a stream was started for the current track
local started = false    -- the engine has reported a length for it
local paused = false
local startPaused = false
local failures = 0       -- tracks in a row that would not play
local sinceStart = 0
local sinceCheck = 0
local lastUpdate

--------------------------------------------------------------------------------

local function TrackName(path)
	local name = path:match("([^/\\]+)$") or path
	name = name:gsub("%.[oO][gG][gG]$", "")
	name = name:gsub("_", " ")
	name = name:gsub("^%d+%s*[%-%.]?%s*", "") -- leading track number
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = path
	end
	return name
end

local function FindTracks()
	local seen, found = {}, {}
	local function AddDirectory(directory)
		for _, mode in ipairs({VFS.ZIP, VFS.RAW}) do
			for _, path in ipairs(VFS.DirList(directory, "*.ogg", mode) or {}) do
				local key = path:lower():gsub("\\", "/")
				if not seen[key] then
					seen[key] = true
					found[#found + 1] = {path = path, name = TrackName(path)}
				end
			end
		end
	end
	AddDirectory(MUSIC_DIR)
	for _, mode in ipairs({VFS.ZIP, VFS.RAW}) do
		for _, directory in ipairs(VFS.SubDirs(MUSIC_DIR, "*", mode) or {}) do
			AddDirectory(directory)
		end
	end
	table.sort(found, function(a, b) return a.path < b.path end)
	-- shuffle
	for i = #found, 2, -1 do
		local j = math.random(i)
		found[i], found[j] = found[j], found[i]
	end
	return found
end

local DEFAULT_VOLUME = 50 -- percent

local function Volume()
	local percent = Spring.GetConfigInt("snd_volmusic", DEFAULT_VOLUME)
	return math.max(0, math.min(100, percent)) / 100
end

local function SetVolume(fraction)
	if streaming then
		Spring.SetSoundStreamVolume(fraction)
	end
end

local function Play(index)
	if #tracks == 0 then
		return
	end
	current = ((index - 1) % #tracks) + 1
	Spring.StopSoundStream()
	Spring.PlaySoundStream(tracks[current].path, Volume())
	Spring.SetSoundStreamVolume(Volume())
	streaming = true
	started = false
	paused = false
	sinceStart = 0
end

local function Next()
	Play(current + 1)
end

local function Previous()
	Play(current - 1)
end

local function TogglePause()
	if #tracks == 0 then
		return
	end
	if not streaming then
		Play(math.max(current, 1)) -- was paused before anything played
		return
	end
	Spring.PauseSoundStream() -- the engine call toggles
	paused = not paused
end

local function GetState()
	local track = tracks[current]
	return {
		count = #tracks,
		index = current,
		name = track and track.name or nil,
		paused = paused or not streaming,
	}
end

--------------------------------------------------------------------------------

function widget:Initialize()
	-- the slider in Settings reads this value; make sure it exists at 50%
	if Spring.GetConfigInt("snd_volmusic", -1) < 0 then
		Spring.SetConfigInt("snd_volmusic", DEFAULT_VOLUME)
	end
	tracks = FindTracks()
	WG.thisMusic = {
		GetState = GetState,
		Next = Next,
		Previous = Previous,
		TogglePause = TogglePause,
		SetVolume = SetVolume,
	}
	lastUpdate = Spring.GetTimer()
	if #tracks == 0 then
		Spring.Echo("[THIS Music] no .ogg files found in " .. MUSIC_DIR .. "/")
		return
	end
	current = 1
	if not startPaused then
		Play(1)
	end
end

function widget:Shutdown()
	if streaming then
		Spring.StopSoundStream()
	end
	WG.thisMusic = nil
end

function widget:Update()
	local now = Spring.GetTimer()
	local elapsed = Spring.DiffTimers(now, lastUpdate)
	lastUpdate = now
	if not streaming or paused then
		return
	end
	sinceStart = sinceStart + elapsed
	sinceCheck = sinceCheck + elapsed
	if sinceCheck < CHECK_INTERVAL then
		return
	end
	sinceCheck = 0

	local played, total = Spring.GetSoundStreamTime()
	played, total = played or 0, total or 0
	if total > 0 then
		started = true
		failures = 0
		if played >= total - END_MARGIN then
			Next()
		end
	elseif started then
		Next() -- the stream has ended
	elseif sinceStart > START_TIMEOUT then
		-- the file would not play
		failures = failures + 1
		Spring.Echo("[THIS Music] could not play " .. tracks[current].path)
		if failures >= #tracks then
			streaming = false -- nothing plays: give up instead of looping forever
		else
			Next()
		end
	end
end

-- remember only whether the player had the music paused
function widget:GetConfigData()
	return {paused = (#tracks > 0) and (paused or not streaming) or startPaused}
end

function widget:SetConfigData(data)
	startPaused = type(data) == "table" and data.paused == true
end
