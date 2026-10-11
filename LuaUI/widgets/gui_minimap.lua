--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Minimap placement and planet markers.
--
--  Puts the engine's minimap in the top-left corner at a size that follows
--  the HUD scale, and draws every planet on it: a ring the size of its capture
--  circle, in the colour of the team holding it, or grey when it is free or
--  contested. Planet positions and owners come from the planet_<i>_* game
--  rules params published by hud_state.lua.
--
--  The minimap is placed when the widget starts and when the window is
--  resized; if you move or resize it yourself it is left where you put it.
--  Its previous position is restored when the widget stops.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Minimap",
		desc = "Places the minimap and marks the planets on it",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local MARGIN = 8             -- dp from the screen edge
local SIZE = 240             -- dp, the longer side of the minimap
local ENGINE_BUTTONS = 16    -- px the engine keeps free above the minimap for its buttons
local OCCUPATION_RANGE = 500 -- planets.locals.lua: radius of a planet's capture circle
local SEGMENTS = 24

local hud
local savedGeometry          -- "x y w h" as it was before this widget placed the minimap

local mapX, mapZ = Game.mapSizeX, Game.mapSizeZ
local glColor, glVertex, glBeginEnd = gl.Color, gl.Vertex, gl.BeginEnd

--------------------------------------------------------------------------------

local function Scale()
	if hud then
		return hud.GetScale()
	end
	-- without RmlUi: the same rule as the HUD, resolution relative to 1080p
	local vsx, vsy = Spring.GetViewGeometry()
	return math.max(0.5, math.min(vsx / 1920, vsy / 1080))
end

local function Place()
	local scale = Scale()
	local longSide = SIZE * scale
	local width, height
	if mapX >= mapZ then
		width, height = longSide, longSide * mapZ / mapX
	else
		width, height = longSide * mapX / mapZ, longSide
	end
	local x = math.floor(MARGIN * scale + 0.5)
	local y = math.max(ENGINE_BUTTONS, math.floor(MARGIN * scale + 0.5))
	Spring.SendCommands(string.format("minimap geometry %d %d %d %d", x, y, math.floor(width + 0.5), math.floor(height + 0.5)))
end

--------------------------------------------------------------------------------
-- planet markers

local circle = {}
for i = 0, SEGMENTS - 1 do
	local angle = 2 * math.pi * i / SEGMENTS
	circle[i + 1] = {math.cos(angle), math.sin(angle)}
end

local function Disc(x, z, radius)
	glVertex(x, z)
	for i = 1, SEGMENTS do
		glVertex(x + circle[i][1] * radius, z + circle[i][2] * radius)
	end
	glVertex(x + circle[1][1] * radius, z + circle[1][2] * radius)
end

local function Ring(x, z, radius)
	for i = 1, SEGMENTS do
		glVertex(x + circle[i][1] * radius, z + circle[i][2] * radius)
	end
end

function widget:DrawInMiniMap(sizeX, sizeY)
	local count = Spring.GetGameRulesParam("planet_count") or 0
	if count == 0 then
		return
	end

	-- map coordinates: x to the right, z downwards, as the planets gadget draws
	gl.PushMatrix()
	gl.LoadIdentity()
	gl.Translate(0, 1, 0)
	gl.Scale(1 / mapX, -1 / mapZ, 1)
	gl.Texture(false)
	gl.LineWidth(1.5)

	for i = 1, count do
		local x = Spring.GetGameRulesParam("planet_" .. i .. "_x")
		local z = Spring.GetGameRulesParam("planet_" .. i .. "_z")
		local owner = Spring.GetGameRulesParam("planet_" .. i .. "_owner") or -1
		if x and z then
			local r, g, b = 0.72, 0.76, 0.82 -- free or contested
			local fill = 0.12
			if owner >= 0 then
				local tr, tg, tb = Spring.GetTeamColor(owner)
				if tr then
					r, g, b = tr, tg, tb
					fill = 0.4
				end
			end
			glColor(r, g, b, fill)
			glBeginEnd(GL.TRIANGLE_FAN, Disc, x, z, OCCUPATION_RANGE)
			glColor(r, g, b, 1)
			glBeginEnd(GL.LINE_LOOP, Ring, x, z, OCCUPATION_RANGE)
			glBeginEnd(GL.TRIANGLE_FAN, Disc, x, z, OCCUPATION_RANGE * 0.22)
		end
	end

	gl.LineWidth(1)
	glColor(1, 1, 1, 1)
	gl.PopMatrix()
end

--------------------------------------------------------------------------------

function widget:Initialize()
	if RmlUi then
		hud = include("rml/hud.lua")
	end
	local px, py, sx, sy = Spring.GetMiniMapGeometry()
	if px then
		-- the engine reports the position from the bottom of the window; the
		-- "minimap geometry" command wants it from the top
		local _, vsy = Spring.GetViewGeometry()
		savedGeometry = string.format("%d %d %d %d", px, vsy - sy - py, sx, sy)
	end
	Place()
end

function widget:Shutdown()
	if savedGeometry then
		Spring.SendCommands("minimap geometry " .. savedGeometry)
	end
end

function widget:ViewResize()
	Place()
end
