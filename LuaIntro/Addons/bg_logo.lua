-- Shadows the engine base content's spinning engine logo (LuaIntro/Addons/bg_logo.lua): THIS does not show it.
if addon.InGetInfo then
	return { name = "SpringLogo", desc = "disabled", author = "", date = "", license = "GPL2", layer = 1,
		enabled = false }
end
