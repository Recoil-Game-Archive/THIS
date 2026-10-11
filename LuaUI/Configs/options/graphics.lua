--------------------------------------------------------------------------------
-- Settings: Graphics tab. See LuaUI/widgets/gui_settings.lua for the fields.
--------------------------------------------------------------------------------

-- common sizes plus whatever the engine listed in infolog.txt
local function BuildResolutionList()
	local list = {"1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1080", "2560 x 1440", "3440 x 1440", "3840 x 2160"}
	local seen = {}
	for i = 1, #list do
		seen[list[i]] = true
	end
	local infolog = VFS.LoadFile("infolog.txt")
	if infolog then
		local collecting = false
		for line in infolog:gmatch("[^\r\n]+") do
			if collecting then
				local w, h = line:match("(%d+)x(%d+)")
				if w and h and tonumber(w) >= 640 and tonumber(h) >= 480 then
					local res = w .. " x " .. h
					if not seen[res] then
						list[#list + 1] = res
						seen[res] = true
					end
				else
					break
				end
			elseif line:find("\tdisplay=", 1, true) then
				collecting = true
			end
		end
	end
	local vsx, vsy = Spring.GetViewGeometry()
	local current = vsx .. " x " .. vsy
	if not seen[current] then
		list[#list + 1] = current
	end
	return list
end
local resolutions = BuildResolutionList()

local function CurrentResolutionIndex()
	local vsx, vsy = Spring.GetViewGeometry()
	local current = vsx .. " x " .. vsy
	for i = 1, #resolutions do
		if resolutions[i] == current then
			return i
		end
	end
	return 1
end

local function ApplyResolution(index)
	local w, h = resolutions[index]:match("(%d+) x (%d+)")
	w, h = tonumber(w), tonumber(h)
	if not (w and h) then
		return
	end
	if Spring.GetConfigInt("Fullscreen", 1) == 1 then
		Spring.SendCommands("fullscreen 0")
		Spring.SetConfigInt("XResolution", w)
		Spring.SetConfigInt("YResolution", h)
		Spring.SendCommands("fullscreen 1")
	else
		Spring.SendCommands("fullscreen 1")
		Spring.SetConfigInt("XResolutionWindowed", w)
		Spring.SetConfigInt("YResolutionWindowed", h)
		Spring.SendCommands("fullscreen 0")
	end
end

return {
	id = "gfx", name = "Graphics", order = 10,
	options = {
		{ type = "separator", name = "Display" },
		{ id = "resolution", name = "Resolution", type = "select", options = resolutions,
		  get = CurrentResolutionIndex, set = ApplyResolution,
		  desc = "Changing resolution in windowed mode can occasionally freeze the engine." },
		{ id = "fullscreen", name = "Fullscreen", type = "bool", config = "Fullscreen", cmd = "fullscreen %d",
		  onSet = function(v) if v then Spring.SetConfigInt("WindowBorderless", 0) end end },
		{ id = "borderless", name = "Borderless window", type = "bool", config = "WindowBorderless", restart = true,
		  desc = "Takes effect next game. Turn fullscreen off for this to apply.",
		  onSet = function(v)
			if v then
				Spring.SetConfigInt("Fullscreen", 0)
				Spring.SetConfigInt("WindowPosX", 0)
				Spring.SetConfigInt("WindowPosY", 0)
				Spring.SetConfigInt("WindowState", 0)
			else
				Spring.SetConfigInt("WindowState", 1)
			end
		  end },
		{ id = "vsync", name = "V-sync", type = "bool", config = "VSync", cmd = "vsync %d" },
		{ id = "msaa", name = "Anti-aliasing (MSAA)", type = "slider", steps = {0, 2, 4, 8, 16}, config = "MSAALevel", restart = true, format = "%dx" },

		{ type = "separator", name = "Effects" },
		{ id = "particles", name = "Particle limit", type = "slider", min = 2000, max = 30000, step = 1000, config = "MaxParticles", cmd = "maxparticles %d",
		  desc = "Lower this if big battles slow the game down." },
	},
}
