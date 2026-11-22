function widget:GetInfo()
	return {
		name    = "Cursor Size",
		desc    = "Picks the HD cursor set (Anims/hd/<size>) that suits the screen height",
		author  = "THIS contributors",
		date    = "2026-11-21",
		license = "GNU GPL, v2 or later",
		layer   = -1000,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- The cursors (tools/cursors/cursors.py) come in 32, 48, 64 and 96 px sets;
-- Anims/<cursor>.txt loads the 48 px set by default. This widget swaps every
-- cursor for the set nearest 48 px per 1080 lines of screen (1080p 48, 1440p
-- 64, 4K 96, small windows 32), or the size in the config value
-- "THISCursorSize" if that is set.
--
-- It also gives the game's own commands their cursors: a command description
-- names its cursor (cursor = "Turn"), and that name has to be assigned to a
-- file from the unsynced side.
--
-- Spring.ReplaceMouseCursor keys on the original file name, so the set can be
-- swapped again when the window is resized.
--------------------------------------------------------------------------------

local SIZES = { 32, 48, 64, 96 }

-- cursors the engine loads by itself
local CURSORS = {
	"cursornormal", "cursormove", "cursorattack", "cursorattackbad", "cursorfight",
	"cursormanfire", "cursorpatrol", "cursordefend", "cursorwait",
}

-- cursors of the game's own commands: name used in the command description -> file
local CUSTOM = {
	Turn  = "cursorturn",  -- LuaRules/Gadgets/unit_turn.lua
	Rally = "cursorrally", -- LuaRules/Gadgets/build.locals.lua
}

local current

local function WantedSize()
	local forced = Spring.GetConfigInt("THISCursorSize", 0)
	local want = forced > 0 and forced or select(2, Spring.GetViewGeometry()) / 1080 * 48
	local best, bestDistance = 48, math.huge
	for _, size in ipairs(SIZES) do
		local distance = math.abs(size - want)
		if distance < bestDistance then
			best, bestDistance = size, distance
		end
	end
	return best
end

local function Apply()
	local size = WantedSize()
	if size == current then
		return
	end
	current = size
	for _, name in ipairs(CURSORS) do
		Spring.ReplaceMouseCursor(name, "hd/" .. size .. "/" .. name, name == "cursornormal")
	end
	for cursorName, file in pairs(CUSTOM) do
		Spring.AssignMouseCursor(cursorName, "hd/" .. size .. "/" .. file, true, false)
	end
end

function widget:Initialize()
	Apply()
end

function widget:ViewResize()
	Apply()
end
