function widget:GetInfo() return { name = "Music Probe", layer = 99998, enabled = true } end
-- Logs what the music player is playing at frames 30 and 150 ([MUSICPROBE] in the infolog): the track must be the one
-- the loading screen started (intro=...), and its play time at frame 30 must already be several seconds.
local intro = Spring.GetConfigString("THISIntroTrack", "")
function widget:GameFrame(f)
  if f ~= 30 and f ~= 150 then return end
  local state = WG.thisMusic and WG.thisMusic.GetState() or {}
  local played, total = Spring.GetSoundStreamTime()
  Spring.Echo(("[MUSICPROBE] f=%d intro=%s playing=%s paused=%s time=%.1f/%.1f"):format(f, intro, tostring(state.name),
    tostring(state.paused), played or -1, total or -1))
end
