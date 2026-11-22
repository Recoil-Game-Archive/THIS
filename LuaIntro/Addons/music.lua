-- Replaces the engine base content's Music addon (which fades its own track out as loading ends).
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "Starts the music on the loading screen; the in-game player (THIS Music) carries on with the same track",
		author  = "jK; THIS contributors",
		date    = "2012; 2026",
		license = "GPL2",
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- Plays one random track of music/ at the player's music volume (the Music
-- slider in Settings, snd_volmusic; 50% when never set) and leaves it playing
-- when loading ends. Its path goes into the engine config value
-- THISIntroTrack, so the in-game player (LuaUI/widgets/snd_music.lua) knows
-- which track is running: it lets it play on and continues with its playlist
-- afterwards.
--
-- Silent when the player left the music paused last time (THISMusicPaused) or
-- switched the music player off in Settings (THISMusicOff); snd_music.lua and
-- the Sound settings keep those two values up to date.
--------------------------------------------------------------------------------

local TRACK_KEY = "THISIntroTrack"

function addon.Initialize()
	Spring.SetConfigString(TRACK_KEY, "")
	if Spring.GetConfigInt("THISMusicPaused", 0) == 1 or Spring.GetConfigInt("THISMusicOff", 0) == 1 then
		return
	end
	local tracks = VFS.DirList("music/", "*.ogg") or {}
	for _, directory in ipairs(VFS.SubDirs("music/", "*") or {}) do
		for _, path in ipairs(VFS.DirList(directory, "*.ogg") or {}) do
			tracks[#tracks + 1] = path
		end
	end
	if #tracks == 0 then
		return
	end
	math.randomseed(os.time())
	local pick = tracks[math.random(#tracks)]
	local volume = math.max(0, math.min(100, Spring.GetConfigInt("snd_volmusic", 50))) / 100
	Spring.PlaySoundStream(pick, volume)
	Spring.SetSoundStreamVolume(volume)
	Spring.SetConfigString(TRACK_KEY, pick)
end
