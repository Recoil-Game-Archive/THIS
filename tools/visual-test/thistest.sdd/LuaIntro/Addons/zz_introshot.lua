-- Test harness: saves a picture of the loading screen to <write dir>/introshot.png (the engine's screenshot command
-- does not run while loading). Lowest layer (drawn last), one second in.
if addon.InGetInfo then
	return { name = "Intro Shot", desc = "", author = "", date = "", license = "GPL2", layer = -2000, enabled = true }
end
local start, done = os.clock(), false
function addon.DrawLoadScreen()
	if not done and os.clock() - start > 1 then
		done = true
		local vsx, vsy = gl.GetViewSizes()
		gl.SaveImage(0, 0, vsx, vsy, "introshot.png")
	end
end
