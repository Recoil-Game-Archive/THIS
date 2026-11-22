if addon.InGetInfo then
	return {
		name    = "THIS Graphics Settings",
		desc    = "Switches on the engine settings the unit shaders and lights need, while the match loads",
		author  = "THIS contributors",
		date    = "2026-11-22",
		license = "GNU GPL, v2 or later",
		layer   = -1000, -- before the other addons
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- The dynamic lights (LuaUI/widgets/gfx_deferred_rendering_gl4.lua) read the
-- engine's deferred buffers, which the engine only fills when these two
-- settings are on. Their engine default is off.
--
-- This runs on the loading screen, before the engine creates those buffers, so
-- the settings work in the very first match. It is done once per VERSION: a
-- player who switches them off again afterwards keeps that choice (the lights
-- widget then stays off).
--------------------------------------------------------------------------------

local VERSION    = 1
local MARKER_KEY = "THISGraphicsSettingsVersion"

local settings = {
	{ "AllowDeferredMapRendering",   1 },
	{ "AllowDeferredModelRendering", 1 },
}

if (Spring.GetConfigInt(MARKER_KEY, 0) or 0) >= VERSION then
	return
end

for _, setting in ipairs(settings) do
	local key, value = setting[1], setting[2]
	if Spring.GetConfigInt(key, 0) ~= value then
		Spring.SetConfigInt(key, value)
		Spring.Echo("[THIS Graphics Settings] " .. key .. " = " .. value)
	end
end
Spring.SetConfigInt(MARKER_KEY, VERSION)
