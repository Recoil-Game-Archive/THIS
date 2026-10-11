--------------------------------------------------------------------------------
-- Settings: Controls tab. See LuaUI/widgets/gui_settings.lua for the fields.
--------------------------------------------------------------------------------

local CAM_MODES = {"First person", "Overhead", "Spring", "Rotating overhead", "Free"}
local CAM_CMDS = {"viewfps", "viewta", "viewspring", "viewrot", "viewfree"}

return {
	id = "control", name = "Controls", order = 40,
	options = {
		{ type = "separator", name = "Camera" },
		{ id = "camera", name = "Camera mode", type = "select", options = CAM_MODES, values = {0, 1, 2, 3, 4}, config = "CamMode",
		  onSet = function(index) Spring.SendCommands(CAM_CMDS[index]) end },
		{ id = "scrollspeed", name = "Zoom speed", type = "slider", min = 1, max = 45, step = 1,
		  get = function() return math.abs(Spring.GetConfigInt("ScrollWheelSpeed", 25)) end,
		  set = function(v)
			local inverted = Spring.GetConfigInt("ScrollWheelSpeed", 25) < 0
			Spring.SetConfigInt("ScrollWheelSpeed", inverted and -v or v)
		  end },
		{ id = "scrollinverse", name = "Invert zoom", type = "bool",
		  get = function() return Spring.GetConfigInt("ScrollWheelSpeed", 25) < 0 end,
		  set = function(v)
			local speed = math.abs(Spring.GetConfigInt("ScrollWheelSpeed", 25))
			Spring.SetConfigInt("ScrollWheelSpeed", v and -speed or speed)
		  end },
		{ id = "screenedgemove", name = "Screen edge moves camera", type = "bool", restart = true,
		  get = function() return Spring.GetConfigInt("FullscreenEdgeMove", 1) == 1 end,
		  set = function(v)
			Spring.SetConfigInt("FullscreenEdgeMove", v and 1 or 0)
			Spring.SetConfigInt("WindowedEdgeMove", v and 1 or 0)
		  end },

		{ type = "separator", name = "Mouse" },
		{ id = "hwcursor", name = "Hardware cursor", type = "bool", config = "HardwareCursor", cmd = "hardwarecursor %d",
		  desc = "When off, the cursor refresh rate is tied to your in-game FPS." },
	},
}
