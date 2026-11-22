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
--  Orders get the same line. An order is given on the ground under the mouse,
--  but the ship ends up high above that spot and is judged by the plane far
--  below it, so neither the click nor the waypoint shows where the ship will
--  be for a capture ring. So:
--    - every waypoint of the selected ships (and every rally point of a
--      selected carrier) has a line down to the plane, in the colour of the
--      order, from the height the ship flies at;
--    - while ships are selected and the mouse would give them an order that
--      names a place, the spot under the mouse has one too, before you click.
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

-- order lines
local MAX_ORDER_UNITS = 300     -- with more ships selected, only this many get order lines
local MAX_ORDERS = 12           -- orders shown per ship
local QUEUE_REFRESH = 0.12      -- seconds between reading the ships' order queues
local ORDER_ALPHA = 0.8         -- against a ship's own line (1)
local QUEUED_ALPHA = 0.5        -- orders after the first
local PREVIEW_ALPHA = 1.0       -- the spot under the mouse
-- colours as in gfx_command_lines.lua
local ORDER_COLOUR = {
	[CMD.MOVE]   = {0.35, 1.00, 0.45},
	[CMD.FIGHT]  = {0.62, 0.45, 1.00},
	[CMD.PATROL] = {0.30, 0.62, 1.00},
	[CMD.ATTACK] = {1.00, 0.26, 0.20},
	[CMD.AREA_ATTACK] = {1.00, 0.26, 0.20},
}
local OTHER_ORDER_COLOUR = {0.85, 0.88, 0.95}
local RALLY_COLOUR = {1.00, 0.84, 0.30}
-- the mouse gets a preview line for these orders (and for the default order, when that is one of them)
local PREVIEW_ORDERS = {
	[CMD.MOVE] = true, [CMD.FIGHT] = true, [CMD.PATROL] = true,
	[31416] = true,  -- CMD_TURN, LuaRules/Gadgets/unit_turn.lua
	[32667] = true,  -- CMD_RALLY, LuaRules/Gadgets/build.locals.lua
	[32333] = true,  -- CMD_PLACE (bringing in a large ship), LuaRules/Gadgets/build.locals.lua
}

local planeY = DEFAULT_PLANE_Y
local marked = {}        -- unitDefID -> circle radius, or false for things that get no line
local teamColour = {}    -- teamID -> {r, g, b}

local shader, vao, shapeVBO, instanceVBO
local shapeVertices = 0
local useInstancing = true
local planeUniform

local orderPoints = {}   -- list of {x, y, z, radius, r, g, b, alpha}, from the selected ships' queues
local sinceRefresh = QUEUE_REFRESH
local lastUpdate

local VERTEX_SHADER = [[
#version 330 compatibility
// shape.xy: offset in the plane, in circle radii; shape.z: 1 at the ship, 0 in the plane;
// shape.w: alpha of this vertex
layout (location = 0) in vec4 shape;
layout (location = 1) in vec4 ship;      // ship position, and the circle's radius
layout (location = 2) in vec4 colour;    // rgb; a: how visible this line is (1 for ships, less for orders)
uniform float planeHeight;
out vec4 vColour;
void main() {
	vec4 world = vec4(ship.x + shape.x * ship.w, mix(planeHeight, ship.y, shape.z), ship.z + shape.y * ship.w, 1.0);
	vColour = vec4(colour.rgb, shape.w * colour.a);
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
	planeUniform = gl.GetUniformLocation(shader, "planeHeight")
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

--------------------------------------------------------------------------------
-- orders

-- Where the selected ships are going: one point per order that names a place
-- and per rally point. Orders on a unit (attack, guard) are left out: that
-- unit has its own line.
local function RefreshOrders()
	orderPoints = {}
	local selected = Spring.GetSelectedUnits() or {}
	for i = 1, math.min(#selected, MAX_ORDER_UNITS) do
		local unitID = selected[i]
		local radius = CircleRadius(Spring.GetUnitDefID(unitID))
		local _, y = Spring.GetUnitPosition(unitID)
		if radius and y then
			local commands = Spring.GetUnitCommands(unitID, MAX_ORDERS) or {}
			local first = true
			for c = 1, #commands do
				local command = commands[c]
				local params = command.params or {}
				if #params >= 3 and (ORDER_COLOUR[command.id] or command.id >= 0) then
					local colour = ORDER_COLOUR[command.id] or OTHER_ORDER_COLOUR
					orderPoints[#orderPoints + 1] = {params[1], y, params[3], radius, colour[1], colour[2], colour[3],
						first and ORDER_ALPHA or QUEUED_ALPHA}
					first = false
				end
			end
			local rally = Spring.GetUnitRulesParam(unitID, "rally")
			if type(rally) == "string" then
				for x, z in rally:gmatch("(%-?%d+),(%-?%d+)") do
					orderPoints[#orderPoints + 1] = {tonumber(x), y, tonumber(z), CIRCLE_MIN * 1.5,
						RALLY_COLOUR[1], RALLY_COLOUR[2], RALLY_COLOUR[3], ORDER_ALPHA}
				end
			end
		end
	end
end

-- The spot under the mouse, while it would give the selected ships an order
-- that names a place: {x, y, z, radius, r, g, b, alpha}, or nil.
local function PreviewPoint()
	local selected = Spring.GetSelectedUnits() or {}
	if #selected == 0 then
		return nil
	end
	local _, activeID = Spring.GetActiveCommand()
	local commandID = activeID
	if not commandID then
		local _, defaultID = Spring.GetDefaultCommand()
		commandID = defaultID
	end
	if not (commandID and PREVIEW_ORDERS[commandID]) then
		return nil
	end
	local mx, my, _, _, _, offscreen = Spring.GetMouseState()
	if offscreen or Spring.IsAboveMiniMap(mx, my) then
		return nil
	end
	local kind, position = Spring.TraceScreenRay(mx, my, true)
	if kind ~= "ground" or not position then
		return nil
	end
	-- the height and size of the selected ships (the first few are enough)
	local height, radius, count = 0, 0, 0
	for i = 1, math.min(#selected, 20) do
		local shipRadius = CircleRadius(Spring.GetUnitDefID(selected[i]))
		local _, y = Spring.GetUnitPosition(selected[i])
		if shipRadius and y then
			height, radius, count = height + y, math.max(radius, shipRadius), count + 1
		end
	end
	if count == 0 then
		return nil
	end
	local colour = ORDER_COLOUR[commandID] or (commandID == 32667 and RALLY_COLOUR) or OTHER_ORDER_COLOUR
	return {position[1], height / count, position[3], radius, colour[1], colour[2], colour[3], PREVIEW_ALPHA}
end

--------------------------------------------------------------------------------

-- {x, y, z, circle radius, r, g, b, visibility} for every ship in view, then the order points
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
				data[n + 5], data[n + 6], data[n + 7], data[n + 8] = colour[1], colour[2], colour[3], 1
				n = n + 8
				count = count + 1
			end
		end
	end
	local function Add(point)
		if point and count < MAX_SHIPS and point[2] - planeY > 4 then
			for k = 1, 8 do
				data[n + k] = point[k]
			end
			n = n + 8
			count = count + 1
		end
	end
	for i = 1, #orderPoints do
		Add(orderPoints[i])
	end
	Add(PreviewPoint())
	return data, count
end

-- one by one, for engines without instancing
local function DrawPlain(data, count)
	gl.BeginEnd(GL.LINES, function()
		for i = 0, count - 1 do
			local n = i * 8
			local x, y, z, radius = data[n + 1], data[n + 2], data[n + 3], data[n + 4]
			local r, g, b, a = data[n + 5], data[n + 6], data[n + 7], data[n + 8]
			gl.Color(r, g, b, LINE_ALPHA_TOP * a)
			gl.Vertex(x, y, z)
			gl.Color(r, g, b, LINE_ALPHA_BOTTOM * a)
			gl.Vertex(x, planeY, z)
			gl.Color(r, g, b, CIRCLE_ALPHA * a)
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
	lastUpdate = Spring.GetTimer()
end

function widget:Update()
	local now = Spring.GetTimer()
	sinceRefresh = sinceRefresh + Spring.DiffTimers(now, lastUpdate)
	lastUpdate = now
	if sinceRefresh >= QUEUE_REFRESH then
		sinceRefresh = 0
		RefreshOrders()
	end
end

-- a new selection or a new order shows at once
function widget:SelectionChanged()
	sinceRefresh = QUEUE_REFRESH
end

function widget:UnitCommand()
	sinceRefresh = QUEUE_REFRESH
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
		gl.Uniform(planeUniform, planeY)
		vao:DrawArrays(GL.LINES, shapeVertices, 0, count, 0)
		gl.UseShader(0)
	else
		DrawPlain(data, count)
	end
	gl.LineWidth(1)
end
