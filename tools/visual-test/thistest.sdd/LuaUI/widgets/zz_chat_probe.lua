function widget:GetInfo() return { name = "Chat Probe", layer = -99999, enabled = true } end
-- VISUALOPTS="chatprobe=520-545": pretends the player is typing between those frames (Spring.IsUserWriting; the
-- engine's chat input cannot be driven by commands) and sends "hello there" at the end, to see the chat panel keep
-- its history up after a message is sent.
local range = (Spring.GetModOptions() or {}).chatprobe
if not range then return false end
local from, to = range:match("(%d+)%-(%d+)")
from, to = tonumber(from), tonumber(to)
local real = Spring.IsUserWriting
function widget:Initialize()
  Spring.IsUserWriting = function()
    local f = Spring.GetGameFrame()
    return (f >= from and f < to) or (real and real()) or false
  end
end
function widget:GameFrame(f)
  if f == to then Spring.SendCommands("say hello there") end
end
function widget:Shutdown() Spring.IsUserWriting = real end
