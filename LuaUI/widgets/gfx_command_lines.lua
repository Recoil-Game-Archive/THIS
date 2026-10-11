--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Command lines.
--
--  Replaces the engine's thin lines for the orders of selected ships with
--  glowing ones: arrowheads of light run along each line towards the target,
--  in the colour of the order (move green, fight violet, patrol blue, attack
--  red, ...), and every waypoint gets a small turning marker. The last
--  waypoint's marker is larger.
--
--  Lines are drawn at the height the ship flies at, so a waypoint is shown
--  where the ship will be seen once it gets there.
--
--  Everything goes out in two instanced calls (one for the line pieces, one
--  for the markers). If the engine cannot do that, this widget switches
--  itself off and the engine's own lines come back.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Command Lines",
		desc = "Animated lines and waypoint markers for the orders of selected ships",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local MAX_UNITS = 300            -- with more ships selected, only this many get lines
local MAX_ORDERS = 12            -- orders shown per ship
local MAX_SEGMENTS = 4096
local MAX_MARKERS = 4096
local QUEUE_REFRESH = 0.12       -- seconds between reading the ships' order queues
local LINE_HALF_WIDTH = 9        -- pixels, including the glow
local MARKER_SIZE = 11           -- pixels (half the side of a waypoint marker)
local LAST_MARKER_SIZE = 17

-- colour and speed of the running lights, by order
local STYLES = {
	[CMD.MOVE]      = {0.35, 1.00, 0.45, 1.0},
	[CMD.FIGHT]     = {0.62, 0.45, 1.00, 1.2},
	[CMD.PATROL]    = {0.30, 0.62, 1.00, 0.7},
	[CMD.ATTACK]    = {1.00, 0.26, 0.20, 1.8},
	[CMD.AREA_ATTACK] = {1.00, 0.26, 0.20, 1.8},
	[CMD.GUARD]     = {0.35, 0.80, 1.00, 0.7},
	[CMD.REPAIR]    = {0.30, 1.00, 0.95, 0.9},
	[CMD.RECLAIM]   = {1.00, 0.30, 1.00, 0.9},
	[CMD.LOAD_UNITS]   = {0.30, 1.00, 0.95, 0.9},
	[CMD.UNLOAD_UNITS] = {1.00, 0.95, 0.25, 0.9},
	[CMD.UNLOAD_UNIT]  = {1.00, 0.95, 0.25, 0.9},
	[CMD.CAPTURE]   = {1.00, 0.95, 0.35, 0.9},
	[CMD.RESURRECT] = {0.30, 0.65, 1.00, 0.9},
}
local OTHER_STYLE = {0.85, 0.88, 0.95, 1.0}   -- any other order that names a place

-- The engine's own lines and waypoint icons are made invisible while this
-- widget runs (this is not saved anywhere), and given back on shutdown.
local ENGINE_ORDERS = {
	start = {1.0, 1.0, 1.0}, restart = {0.4, 0.4, 0.4}, wait = {0.5, 0.5, 0.5}, build = {0.0, 1.0, 0.0},
	move = {0.5, 1.0, 0.5}, attack = {1.0, 0.2, 0.2}, fight = {0.5, 0.5, 1.0}, guard = {0.3, 0.3, 1.0},
	patrol = {0.3, 0.3, 1.0}, capture = {1.0, 1.0, 0.3}, repair = {0.3, 1.0, 1.0}, reclaim = {1.0, 0.2, 1.0},
	restore = {0.0, 1.0, 0.0}, resurrect = {0.2, 0.6, 1.0}, load = {0.3, 1.0, 1.0}, unload = {1.0, 1.0, 0.0},
	deathWatch = {0.5, 0.5, 0.5},
}
local ENGINE_LINE_ALPHA = 0.4
local ENGINE_ICON_ALPHA = 0.5

local lineShader, lineVAO, lineInstances
local markerShader, markerVAO, markerInstances
local quadVBO
local lineUniforms, markerUniforms = {}, {}
local ready = false
local engineHidden = false

local queues = {}        -- unitID -> list of {x, z, target unitID, style}
local sinceRefresh = QUEUE_REFRESH
local lastUpdate
local startTimer

--------------------------------------------------------------------------------
-- shaders

local LINE_VERTEX = [[
#version 330 compatibility
layout (location = 0) in vec2 corner;     // x: 0 at the start of the piece, 1 at its end; y: -1 or 1 across it
layout (location = 1) in vec4 from;       // start, and the distance along the whole path up to here
layout (location = 2) in vec4 to;         // end, and the speed of the lights
layout (location = 3) in vec4 colour;     // rgb, and brightness
uniform vec2 viewport;
uniform float halfWidth;                   // pixels
out float vAlong;      // distance along the path, in world units
out float vAcross;     // -1..1 across the line
out float vPixels;     // pixels per world unit on this piece
flat out vec4 vColour;
flat out float vSpeed;
void main() {
	vec4 a = gl_ModelViewProjectionMatrix * vec4(from.xyz, 1.0);
	vec4 b = gl_ModelViewProjectionMatrix * vec4(to.xyz, 1.0);
	// keep both ends in front of the camera
	float near = 1.0;
	if (a.w < near && b.w > near) a = mix(a, b, (near - a.w) / (b.w - a.w));
	if (b.w < near && a.w > near) b = mix(b, a, (near - b.w) / (a.w - b.w));
	vec2 sa = a.xy / a.w * viewport * 0.5;
	vec2 sb = b.xy / b.w * viewport * 0.5;
	vec2 along = sb - sa;
	float screenLength = max(length(along), 1.0e-4);
	vec2 normal = vec2(-along.y, along.x) / screenLength;
	float worldLength = max(distance(from.xyz, to.xyz), 1.0e-4);

	vec4 p = mix(a, b, corner.x);
	p.xy += normal * corner.y * halfWidth * 2.0 / viewport * p.w;
	gl_Position = p;

	vAlong = from.w + corner.x * worldLength;
	vAcross = corner.y;
	vPixels = screenLength / worldLength;
	vColour = colour;
	vSpeed = to.w;
}
]]

--FRAGMENT:line
local LINE_FRAGMENT = [[
in float vAlong;
in float vAcross;
in float vPixels;
flat in vec4 vColour;
flat in float vSpeed;
uniform float time;
uniform float halfWidth;
out vec4 fragColor;
void main() {
	float d = abs(vAcross);
	// a thin bright line with a soft glow around it
	float core = 1.0 - smoothstep(0.14, 0.32, d);
	float glow = pow(1.0 - d, 2.2);

	// arrowheads of light running towards the target: the middle of the line
	// leads, the edges trail behind by as much as the line is wide on screen
	float slant = halfWidth * 1.1 / max(vPixels, 1.0e-4);
	float period = max(90.0, 34.0 / max(vPixels, 1.0e-4));
	float phase = fract((vAlong + d * slant) / period - time * vSpeed * 0.9);
	float arrow = smoothstep(0.0, 0.10, phase) * (1.0 - smoothstep(0.30, 0.55, phase));
	float tip = smoothstep(0.30, 0.42, phase) * (1.0 - smoothstep(0.42, 0.55, phase));

	float light = core * (0.40 + 0.85 * arrow) + glow * (0.10 + 0.55 * arrow) * (1.0 - smoothstep(0.55, 1.0, d));
	float white = core * tip * 0.7;

	// nothing right on top of the ship the line starts at
	float fade = smoothstep(18.0, 70.0, vAlong);
	float strength = vColour.a * fade;
	// premultiplied: mostly added to what is behind
	fragColor = vec4((vColour.rgb * light + vec3(white)) * strength, light * 0.22 * strength);
}
]]
--END

local MARKER_VERTEX = [[
#version 330 compatibility
layout (location = 0) in vec2 corner;     // 0..1 and -1..1, as for the lines
layout (location = 1) in vec4 place;      // position, and size in pixels
layout (location = 2) in vec4 colour;     // rgb, and brightness
uniform vec2 viewport;
out vec2 uv;
flat out vec4 vColour;
flat out float vSize;
void main() {
	uv = vec2(corner.x * 2.0 - 1.0, corner.y);
	vec4 p = gl_ModelViewProjectionMatrix * vec4(place.xyz, 1.0);
	p.xy += uv * place.w * 2.0 / viewport * p.w;
	gl_Position = p;
	vColour = colour;
	vSize = place.w;
}
]]

--FRAGMENT:marker
local MARKER_FRAGMENT = [[
in vec2 uv;
flat in vec4 vColour;
flat in float vSize;
uniform float time;
out vec4 fragColor;
void main() {
	float r = length(uv);
	float px = 1.0 / max(vSize, 1.0);

	// a ring, pulsing a little
	float radius = 0.62 + 0.04 * sin(time * 3.0);
	float ring = 1.0 - smoothstep(px * 1.2, px * 2.6, abs(r - radius));
	// a diamond in the middle, turning
	float angle = time * 1.4;
	vec2 q = vec2(uv.x * cos(angle) - uv.y * sin(angle), uv.x * sin(angle) + uv.y * cos(angle));
	float diamond = 1.0 - smoothstep(0.30 - px, 0.30 + px, abs(q.x) + abs(q.y));
	// four ticks outside the ring, turning the other way
	float a = atan(uv.y, uv.x) + time * 0.9;
	float tick = smoothstep(0.80, 0.95, cos(a * 4.0)) * (1.0 - smoothstep(px, px * 2.5, abs(r - 0.86) - 0.08));
	// a ripple running outwards
	float wave = fract(time * 0.8);
	float ripple = (1.0 - smoothstep(px, px * 3.0, abs(r - wave))) * (1.0 - wave) * 0.6;
	float glow = exp(-abs(r - radius) * 7.0) * 0.35;

	float light = ring + diamond * 0.95 + tick * 0.8 + ripple + glow;
	light *= 1.0 - smoothstep(0.94, 1.0, r);
	float white = diamond * 0.45;
	float strength = vColour.a;
	fragColor = vec4((vColour.rgb * light + vec3(white)) * strength, clamp(light, 0.0, 1.0) * 0.30 * strength);
}
]]
--END

--------------------------------------------------------------------------------
-- engine lines on and off

local function SetEngineLines(visible)
	local lines = {}
	for name, c in pairs(ENGINE_ORDERS) do
		lines[#lines + 1] = string.format("%s %.2f %.2f %.2f %.2f", name, c[1], c[2], c[3], visible and ENGINE_LINE_ALPHA or 0)
	end
	lines[#lines + 1] = string.format("queueIconAlpha %.2f", visible and ENGINE_ICON_ALPHA or 0)
	Spring.LoadCmdColorsConfig(table.concat(lines, "\n"))
	engineHidden = not visible
end

--------------------------------------------------------------------------------
-- buffers

local function CreateBuffers()
	if not (gl.GetVBO and gl.GetVAO and gl.CreateShader) then
		return false, "no VBO/VAO support"
	end
	lineShader = gl.CreateShader({vertex = LINE_VERTEX, fragment = "#version 330 compatibility\n" .. LINE_FRAGMENT})
	if not lineShader then
		return false, "the line shader did not compile. Log:\n" .. tostring(gl.GetShaderLog())
	end
	markerShader = gl.CreateShader({vertex = MARKER_VERTEX, fragment = "#version 330 compatibility\n" .. MARKER_FRAGMENT})
	if not markerShader then
		return false, "the marker shader did not compile. Log:\n" .. tostring(gl.GetShaderLog())
	end
	for _, name in ipairs({"viewport", "halfWidth", "time"}) do
		lineUniforms[name] = gl.GetUniformLocation(lineShader, name)
	end
	for _, name in ipairs({"viewport", "time"}) do
		markerUniforms[name] = gl.GetUniformLocation(markerShader, name)
	end

	quadVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	lineInstances = gl.GetVBO(GL.ARRAY_BUFFER, true)
	markerInstances = gl.GetVBO(GL.ARRAY_BUFFER, true)
	lineVAO = gl.GetVAO()
	markerVAO = gl.GetVAO()
	if not (quadVBO and lineInstances and markerInstances and lineVAO and markerVAO) then
		return false, "could not create the buffers"
	end
	quadVBO:Define(4, {{id = 0, name = "corner", size = 2}})
	quadVBO:Upload({0, -1, 1, -1, 0, 1, 1, 1})
	lineInstances:Define(MAX_SEGMENTS, {
		{id = 1, name = "from", size = 4},
		{id = 2, name = "to", size = 4},
		{id = 3, name = "colour", size = 4},
	})
	markerInstances:Define(MAX_MARKERS, {
		{id = 1, name = "place", size = 4},
		{id = 2, name = "colour", size = 4},
	})
	lineVAO:AttachVertexBuffer(quadVBO)
	lineVAO:AttachInstanceBuffer(lineInstances)
	markerVAO:AttachVertexBuffer(quadVBO)
	markerVAO:AttachInstanceBuffer(markerInstances)
	return true
end

local function DeleteBuffers()
	if lineShader then gl.DeleteShader(lineShader) end
	if markerShader then gl.DeleteShader(markerShader) end
	for _, object in ipairs({lineVAO, markerVAO, quadVBO, lineInstances, markerInstances}) do
		pcall(function() object:Delete() end)
	end
	lineShader, markerShader, lineVAO, markerVAO, quadVBO, lineInstances, markerInstances = nil, nil, nil, nil, nil, nil, nil
end

--------------------------------------------------------------------------------
-- orders

-- The orders of one ship that go somewhere: {x, z, target, style} each, where
-- target is a unit to follow instead of a fixed place.
local function ReadQueue(unitID)
	local commands = Spring.GetUnitCommands(unitID, MAX_ORDERS)
	if not commands then
		return nil
	end
	local list = {}
	for i = 1, #commands do
		local command = commands[i]
		local params = command.params or {}
		local style = STYLES[command.id]
		if #params >= 3 then
			if style or command.id >= 0 then
				list[#list + 1] = {params[1], params[3], nil, style or OTHER_STYLE}
			end
		elseif #params == 1 and style then
			list[#list + 1] = {nil, nil, params[1], style}
		end
	end
	return list
end

local function RefreshQueues()
	local selected = Spring.GetSelectedUnits() or {}
	local fresh = {}
	for i = 1, math.min(#selected, MAX_UNITS) do
		local unitID = selected[i]
		local list = ReadQueue(unitID)
		if list and #list > 0 then
			fresh[unitID] = list
		end
	end
	queues = fresh
end

-- Builds the instance data for this frame.
local function Collect()
	local lines, markers = {}, {}
	local nl, nm, segments, count = 0, 0, 0, 0
	for unitID, list in pairs(queues) do
		local x, y, z = Spring.GetUnitPosition(unitID)
		if x then
			local px, pz = x, z
			local travelled = 0
			for i = 1, #list do
				local order = list[i]
				local tx, tz = order[1], order[2]
				if order[3] then
					local ux, _, uz = Spring.GetUnitPosition(order[3])
					tx, tz = ux, uz
				end
				if tx and segments < MAX_SEGMENTS and count < MAX_MARKERS then
					local style = order[4]
					-- orders further down the queue are dimmer
					local brightness = (i == 1) and 1.0 or math.max(0.45, 0.85 - 0.08 * (i - 2))
					lines[nl + 1], lines[nl + 2], lines[nl + 3], lines[nl + 4] = px, y, pz, travelled
					lines[nl + 5], lines[nl + 6], lines[nl + 7], lines[nl + 8] = tx, y, tz, style[4]
					lines[nl + 9], lines[nl + 10], lines[nl + 11], lines[nl + 12] = style[1], style[2], style[3], brightness
					nl = nl + 12
					segments = segments + 1
					markers[nm + 1], markers[nm + 2], markers[nm + 3], markers[nm + 4] = tx, y, tz, (i == #list) and LAST_MARKER_SIZE or MARKER_SIZE
					markers[nm + 5], markers[nm + 6], markers[nm + 7], markers[nm + 8] = style[1], style[2], style[3], brightness
					nm = nm + 8
					count = count + 1
					local dx, dz = tx - px, tz - pz
					travelled = travelled + math.sqrt(dx * dx + dz * dz)
					px, pz = tx, tz
				end
			end
		end
	end
	return lines, segments, markers, count
end

--------------------------------------------------------------------------------
-- call-ins

function widget:Initialize()
	lastUpdate = Spring.GetTimer()
	startTimer = Spring.GetTimer()
	local ok, created, reason = pcall(CreateBuffers)
	if not ok or not created then
		Spring.Echo("[THIS Command Lines] switched off, the engine's lines stay: " .. tostring(ok and reason or created))
		DeleteBuffers()
		widgetHandler:RemoveWidget()
		return
	end
	ready = true
	SetEngineLines(false)
end

function widget:Shutdown()
	if engineHidden then
		SetEngineLines(true)
	end
	DeleteBuffers()
end

function widget:Update()
	local now = Spring.GetTimer()
	sinceRefresh = sinceRefresh + Spring.DiffTimers(now, lastUpdate)
	lastUpdate = now
	if sinceRefresh >= QUEUE_REFRESH then
		sinceRefresh = 0
		RefreshQueues()
	end
end

-- a new selection or a new order shows at once
function widget:SelectionChanged()
	sinceRefresh = QUEUE_REFRESH
end

function widget:UnitCommand()
	sinceRefresh = QUEUE_REFRESH
end

function widget:DrawWorld()
	if not ready or Spring.IsGUIHidden() then
		return
	end
	local lines, segments, markers, count = Collect()
	if segments == 0 then
		return
	end
	local vsx, vsy = Spring.GetViewGeometry()
	local time = Spring.DiffTimers(Spring.GetTimer(), startTimer)

	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.Culling(false)
	gl.Blending(GL.ONE, GL.ONE_MINUS_SRC_ALPHA) -- the shaders' colours are premultiplied

	lineInstances:Upload(lines, nil, 0, 1, segments * 12)
	gl.UseShader(lineShader)
	gl.Uniform(lineUniforms.viewport, vsx, vsy)
	gl.Uniform(lineUniforms.halfWidth, LINE_HALF_WIDTH)
	gl.Uniform(lineUniforms.time, time)
	lineVAO:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, segments, 0)

	markerInstances:Upload(markers, nil, 0, 1, count * 8)
	gl.UseShader(markerShader)
	gl.Uniform(markerUniforms.viewport, vsx, vsy)
	gl.Uniform(markerUniforms.time, time)
	markerVAO:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, count, 0)

	gl.UseShader(0)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthMask(true)
end
