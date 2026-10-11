--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Altitude lines.
--
--  Ships fly well above the plane the planets and their capture rings lie
--  in, and the camera's perspective makes it hard to tell which spot of that
--  plane a ship is over. So every ship you can see gets a thin line in its
--  team's colour, straight down to that plane, ending in a small circle: the
--  circle is where the ship "is" for capturing a planet.
--
--  All lines are drawn in one instanced call (one buffer holds the shape of a
--  line with its circle, a second one a position and colour per ship). If
--  the engine cannot do that, they are drawn one by one instead.
--
--  The height of the plane comes from the game rules param planet_plane_y
--  (LuaRules/Gadgets/planets.locals.lua).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Altitude Lines",
		desc = "Lines from ships down to the plane of the capture rings",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local DEFAULT_PLANE_Y = -300
local MAX_SHIPS = 2048          -- more ships than this on screen are not all marked
local CIRCLE_SEGMENTS = 20
local LINE_ALPHA_TOP = 0.10     -- the line is faint at the ship and clearer at the bottom
local LINE_ALPHA_BOTTOM = 0.75
local CIRCLE_ALPHA = 0.9
-- the circle's radius follows the ship's size, within these limits
local CIRCLE_SCALE = 0.3
local CIRCLE_MIN, CIRCLE_MAX = 7, 42

local planeY = DEFAULT_PLANE_Y
local marked = {}        -- unitDefID -> circle radius, or false for things that get no line
local teamColour = {}    -- teamID -> {r, g, b}

local shader, vao, shapeVBO, instanceVBO
local shapeVertices = 0
local useInstancing = true

local VERTEX_SHADER = [[
#version 330 compatibility
// shape.xy: offset in the plane, in circle radii; shape.z: 1 at the ship, 0 in the plane;
// shape.w: alpha of this vertex
layout (location = 0) in vec4 shape;
layout (location = 1) in vec4 ship;      // ship position, and the circle's radius
layout (location = 2) in vec4 colour;    // team colour; a: height of the plane
out vec4 vColour;
void main() {
	vec4 world = vec4(ship.x + shape.x * ship.w, mix(colour.a, ship.y, shape.z), ship.z + shape.y * ship.w, 1.0);
	vColour = vec4(colour.rgb, shape.w);
	gl_Position = gl_ModelViewProjectionMatrix * world;
}
]]

local FRAGMENT_SHADER = [[
#version 330 compatibility
in vec4 vColour;
out vec4 fragColor;
void main() {
	fragColor = vColour;
}
]]

--------------------------------------------------------------------------------

-- Which things get a line: ships that fly on their own. Not torpedoes, mines,
-- decoys and other pieces flagged NOSHIP, and not turrets mounted on a ship.
local function CircleRadius(unitDefID)
	local radius = marked[unitDefID]
	if radius == nil then
		radius = false
		local def = UnitDefs[unitDefID]
		if def and def.canFly and not (def.modCategories and def.modCategories.noship) then
			radius = math.max(CIRCLE_MIN, math.min(CIRCLE_MAX, (def.radius or 30) * CIRCLE_SCALE))
		end
		marked[unitDefID] = radius
	end
	return radius
end

local function TeamColour(teamID)
	local colour = teamColour[teamID]
	if not colour then
		local r, g, b = Spring.GetTeamColor(teamID)
		colour = {r or 1, g or 1, b or 1}
		teamColour[teamID] = colour
	end
	return colour
end

-- The line and its circle as GL_LINES vertices: {x, z, top, alpha} each.
local function ShapeData()
	local data = {
		0, 0, 1, LINE_ALPHA_TOP,
		0, 0, 0, LINE_ALPHA_BOTTOM,
	}
	for i = 0, CIRCLE_SEGMENTS - 1 do
		local a1 = i / CIRCLE_SEGMENTS * 2 * math.pi
		local a2 = (i + 1) / CIRCLE_SEGMENTS * 2 * math.pi
		local n = #data
		data[n + 1], data[n + 2], data[n + 3], data[n + 4] = math.cos(a1), math.sin(a1), 0, CIRCLE_ALPHA
		data[n + 5], data[n + 6], data[n + 7], data[n + 8] = math.cos(a2), math.sin(a2), 0, CIRCLE_ALPHA
	end
	return data
end

local function CreateBuffers()
	if not (gl.GetVBO and gl.GetVAO and gl.CreateShader) then
		return false, "no VBO/VAO support"
	end
	shader = gl.CreateShader({vertex = VERTEX_SHADER, fragment = FRAGMENT_SHADER})
	if not shader then
		return false, "the shader did not compile. Log:\n" .. tostring(gl.GetShaderLog())
	end
	shapeVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	instanceVBO = gl.GetVBO(GL.ARRAY_BUFFER, true)
	vao = gl.GetVAO()
	if not (shapeVBO and instanceVBO and vao) then
		return false, "could not create the buffers"
	end
	local shape = ShapeData()
	shapeVertices = #shape / 4
	shapeVBO:Define(shapeVertices, {{id = 0, name = "shape", size = 4}})
	shapeVBO:Upload(shape)
	instanceVBO:Define(MAX_SHIPS, {
		{id = 1, name = "ship", size = 4},
		{id = 2, name = "colour", size = 4},
	})
	vao:AttachVertexBuffer(shapeVBO)
	vao:AttachInstanceBuffer(instanceVBO)
	return true
end

local function DeleteBuffers()
	if shader then
		gl.DeleteShader(shader)
	end
	for _, object in ipairs({vao, shapeVBO, instanceVBO}) do
		pcall(function() object:Delete() end)
	end
	shader, vao, shapeVBO, instanceVBO = nil, nil, nil, nil
end

-- {x, y, z, circle radius, r, g, b, plane height} for every ship in view
local function CollectShips()
	local data, n, count = {}, 0, 0
	local units = Spring.GetVisibleUnits(-1, nil, false) or {}
	for i = 1, #units do
		local unitID = units[i]
		local radius = CircleRadius(Spring.GetUnitDefID(unitID))
		if radius and count < MAX_SHIPS and not Spring.GetUnitTransporter(unitID) then
			local x, y, z = Spring.GetUnitPosition(unitID)
			-- nothing to show for a ship that is (nearly) in the plane
			if x and y - planeY > 4 then
				local colour = TeamColour(Spring.GetUnitTeam(unitID))
				data[n + 1], data[n + 2], data[n + 3], data[n + 4] = x, y, z, radius
				data[n + 5], data[n + 6], data[n + 7], data[n + 8] = colour[1], colour[2], colour[3], planeY
				n = n + 8
				count = count + 1
			end
		end
	end
	return data, count
end

-- one by one, for engines without instancing
local function DrawPlain(data, count)
	gl.BeginEnd(GL.LINES, function()
		for i = 0, count - 1 do
			local n = i * 8
			local x, y, z, radius = data[n + 1], data[n + 2], data[n + 3], data[n + 4]
			local r, g, b = data[n + 5], data[n + 6], data[n + 7]
			gl.Color(r, g, b, LINE_ALPHA_TOP)
			gl.Vertex(x, y, z)
			gl.Color(r, g, b, LINE_ALPHA_BOTTOM)
			gl.Vertex(x, planeY, z)
			gl.Color(r, g, b, CIRCLE_ALPHA)
			for s = 0, CIRCLE_SEGMENTS - 1 do
				local a1 = s / CIRCLE_SEGMENTS * 2 * math.pi
				local a2 = (s + 1) / CIRCLE_SEGMENTS * 2 * math.pi
				gl.Vertex(x + math.cos(a1) * radius, planeY, z + math.sin(a1) * radius)
				gl.Vertex(x + math.cos(a2) * radius, planeY, z + math.sin(a2) * radius)
			end
		end
	end)
	gl.Color(1, 1, 1, 1)
end

--------------------------------------------------------------------------------

function widget:Initialize()
	planeY = Spring.GetGameRulesParam("planet_plane_y") or DEFAULT_PLANE_Y
end

function widget:Shutdown()
	DeleteBuffers()
end

-- team colours can change (a spectator's colour settings, a LuaUI reload)
function widget:PlayerChanged()
	teamColour = {}
end

-- Before the ships are drawn, so a ship always covers the top of its own line.
function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then
		return
	end
	planeY = Spring.GetGameRulesParam("planet_plane_y") or planeY

	if useInstancing and not vao then
		local ok, created, reason = pcall(CreateBuffers)
		if not ok or not created then
			Spring.Echo("[THIS Altitude Lines] drawing the lines one by one: " .. tostring(ok and reason or created))
			DeleteBuffers()
			useInstancing = false
		end
	end

	local data, count = CollectShips()
	if count == 0 then
		return
	end

	gl.DepthTest(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.LineWidth(1.5)
	if useInstancing then
		instanceVBO:Upload(data, nil, 0, 1, count * 8)
		gl.UseShader(shader)
		vao:DrawArrays(GL.LINES, shapeVertices, 0, count, 0)
		gl.UseShader(0)
	else
		DrawPlain(data, count)
	end
	gl.LineWidth(1)
end
