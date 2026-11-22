--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Selection rings.
--
--  Replaces the engine's green selection squares. Every selected ship gets a
--  ring the size of its hit sphere, in its team's colour, always facing the
--  camera:
--    - a thin circle on the sphere's edge,
--    - three brighter arcs turning slowly around it, with a glint running
--      along them,
--    - four short brackets just outside, turning the other way.
--  A newly selected ship's ring closes in from a little further out.
--
--  Far away, a ring never gets smaller than MIN_PIXELS, so small ships stay
--  easy to find in a large selection.
--
--  All rings go out in one instanced call. If the engine cannot do that, this
--  widget switches itself off and the engine's squares stay.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Selection Rings",
		desc = "Animated rings the size of the hit sphere around selected ships, instead of the engine's squares",
		author = "THIS contributors",
		date = "2026-11-22",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local MAX_RINGS = 2048
local MIN_PIXELS = 11          -- smallest ring radius on screen
local EXTENT = 1.32            -- the quad reaches this many radii out (room for the brackets and the glow)
local POP_SECONDS = 0.35       -- how long a new ring takes to close in
local WHITEN = 0.25            -- team colour mixed towards white, so dark team colours still read
local SIZE_FACTOR = 1.0        -- ring radius in hit sphere radii

local shader, vao, quadVBO, instances
local uniforms = {}
local ready = false
local boxesHidden = false
local startTimer

local selectedAt = {}    -- unitID -> time it was selected (seconds since the widget started)
local teamColour = {}    -- teamID -> {r, g, b}

local VERTEX = [[
#version 330 compatibility
layout (location = 0) in vec2 corner;     // x: 0..1, y: -1..1
layout (location = 1) in vec4 place;      // centre of the hit sphere, and its radius
layout (location = 2) in vec4 colour;     // rgb, and the time the ship was selected
uniform vec2 viewport;
uniform float time;
uniform float minPixels;
uniform float extent;
uniform float popSeconds;
out vec2 uv;             // in radii: the hit sphere's edge is at length 1
flat out vec3 vColour;
flat out float vPixels;  // the radius in pixels
flat out float vAge;     // 0 just selected .. 1 settled
void main() {
	vec2 q = vec2(corner.x * 2.0 - 1.0, corner.y);
	vec4 centre = gl_ModelViewProjectionMatrix * vec4(place.xyz, 1.0);
	// the radius on screen: a point one radius to the camera's right of the centre
	vec3 right = vec3(gl_ModelViewMatrix[0][0], gl_ModelViewMatrix[1][0], gl_ModelViewMatrix[2][0]);
	vec4 edge = gl_ModelViewProjectionMatrix * vec4(place.xyz + right * place.w, 1.0);
	float pixels = length((edge.xy / edge.w - centre.xy / centre.w) * viewport * 0.5);
	pixels = max(pixels, minPixels);

	float age = clamp((time - colour.a) / popSeconds, 0.0, 1.0);
	float pop = 1.0 + 0.45 * pow(1.0 - age, 3.0);   // closes in from further out

	uv = q * extent;
	centre.xy += q * extent * pop * pixels * 2.0 / viewport * centre.w;
	gl_Position = centre;
	vColour = colour.rgb;
	vPixels = pixels * pop;
	vAge = age;
}
]]

local FRAGMENT = [[
#version 330 compatibility
in vec2 uv;
flat in vec3 vColour;
flat in float vPixels;
flat in float vAge;
uniform float time;
out vec4 fragColor;

// 1 inside a band of the given half width (in pixels) around radius r0, soft at the edges
float band(float r, float r0, float halfWidth, float px) {
	return 1.0 - smoothstep(halfWidth * px, (halfWidth + 1.0) * px, abs(r - r0));
}

void main() {
	float r = length(uv);
	float px = 1.0 / max(vPixels, 1.0);         // one pixel, in radii
	float angle = atan(uv.y, uv.x);

	// the sphere's edge: a thin, quiet circle
	float circle = band(r, 1.0, 0.5, px) * 0.42;

	// three arcs on it, turning slowly; each fades towards its ends
	float turn = angle - time * 0.55;
	float arcMask = smoothstep(0.10, 0.75, cos(turn * 3.0));
	float arcs = band(r, 1.0, 1.1, px) * arcMask;

	// a glint running along the arcs, a little faster
	float glintAngle = mod(angle - time * 1.7, 6.2831853);
	float glint = exp(-glintAngle * 2.2) * band(r, 1.0, 1.4, px) * arcMask;

	// four short brackets just outside, turning the other way
	float back = angle + time * 0.30;
	float bracketMask = smoothstep(0.90, 0.96, cos(back * 4.0));
	float bracketRadius = 1.0 + max(7.0 * px, 0.11);
	float brackets = band(r, bracketRadius, 0.9, px) * bracketMask * 0.85;

	// a soft glow hugging the circle, mostly on the inside
	float glow = exp(-abs(r - 1.0) / max(5.0 * px, 0.04)) * 0.16 * (r < 1.0 ? 1.0 : 0.6);

	float light = circle + arcs + brackets + glow;
	float white = glint * 0.9 + arcs * 0.12;
	float fade = vAge * (0.75 + 0.25 * vAge);   // fades in while it closes in
	vec3 rgb = (vColour * light + vec3(white)) * fade;
	// premultiplied: light adds, with a little cover so it stays visible over bright hulls
	fragColor = vec4(rgb, clamp(light + white, 0.0, 1.0) * 0.35 * fade);
}
]]

--------------------------------------------------------------------------------

-- The engine's own selection squares: invisible while this widget runs (not
-- saved anywhere), and given back on shutdown.
local function SetEngineBoxes(visible)
	Spring.LoadCmdColorsConfig(string.format("unitBox 0.0 1.0 0.0 %.1f", visible and 1 or 0))
	boxesHidden = not visible
end

local function CreateBuffers()
	if not (gl.GetVBO and gl.GetVAO and gl.CreateShader) then
		return false, "no VBO/VAO support"
	end
	shader = gl.CreateShader({vertex = VERTEX, fragment = FRAGMENT})
	if not shader then
		return false, "the shader did not compile. Log:\n" .. tostring(gl.GetShaderLog())
	end
	for _, name in ipairs({"viewport", "time", "minPixels", "extent", "popSeconds"}) do
		uniforms[name] = gl.GetUniformLocation(shader, name)
	end
	quadVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	instances = gl.GetVBO(GL.ARRAY_BUFFER, true)
	vao = gl.GetVAO()
	if not (quadVBO and instances and vao) then
		return false, "could not create the buffers"
	end
	quadVBO:Define(4, {{id = 0, name = "corner", size = 2}})
	quadVBO:Upload({0, -1, 1, -1, 0, 1, 1, 1})
	instances:Define(MAX_RINGS, {
		{id = 1, name = "place", size = 4},
		{id = 2, name = "colour", size = 4},
	})
	vao:AttachVertexBuffer(quadVBO)
	vao:AttachInstanceBuffer(instances)
	return true
end

local function DeleteBuffers()
	if shader then
		gl.DeleteShader(shader)
	end
	for _, object in ipairs({vao, quadVBO, instances}) do
		pcall(function() object:Delete() end)
	end
	shader, vao, quadVBO, instances = nil, nil, nil, nil
end

local function TeamColour(teamID)
	local colour = teamColour[teamID]
	if not colour then
		local r, g, b = Spring.GetTeamColor(teamID)
		r, g, b = r or 1, g or 1, b or 1
		colour = {r + (1 - r) * WHITEN, g + (1 - g) * WHITEN, b + (1 - b) * WHITEN}
		teamColour[teamID] = colour
	end
	return colour
end

local function Now()
	return Spring.DiffTimers(Spring.GetTimer(), startTimer)
end

-- remembers when each ship was selected, so its ring can close in
local function TrackSelection()
	local now = Now()
	local selected = Spring.GetSelectedUnits() or {}
	local fresh = {}
	for i = 1, #selected do
		local unitID = selected[i]
		fresh[unitID] = selectedAt[unitID] or now
	end
	selectedAt = fresh
end

-- {x, y, z, radius, r, g, b, time selected} for every selected ship
local function Collect()
	local data, n, count = {}, 0, 0
	for unitID, since in pairs(selectedAt) do
		if count >= MAX_RINGS then
			break
		end
		-- the middle of the hit sphere (not the model's base point)
		local _, _, _, x, y, z = Spring.GetUnitPosition(unitID, true)
		local radius = Spring.GetUnitRadius(unitID)
		if x and radius and not Spring.GetUnitNoDraw(unitID) then
			local colour = TeamColour(Spring.GetUnitTeam(unitID))
			data[n + 1], data[n + 2], data[n + 3], data[n + 4] = x, y, z, radius * SIZE_FACTOR
			data[n + 5], data[n + 6], data[n + 7], data[n + 8] = colour[1], colour[2], colour[3], since
			n = n + 8
			count = count + 1
		end
	end
	return data, count
end

--------------------------------------------------------------------------------

function widget:Initialize()
	startTimer = Spring.GetTimer()
	local ok, created, reason = pcall(CreateBuffers)
	if not ok or not created then
		Spring.Echo("[THIS Selection Rings] switched off, the engine's squares stay: " .. tostring(ok and reason or created))
		DeleteBuffers()
		widgetHandler:RemoveWidget()
		return
	end
	ready = true
	SetEngineBoxes(false)
	TrackSelection()
	-- ships that were already selected (after "/luaui reload") do not pop
	for unitID in pairs(selectedAt) do
		selectedAt[unitID] = -POP_SECONDS
	end
end

function widget:Shutdown()
	if boxesHidden then
		SetEngineBoxes(true)
	end
	DeleteBuffers()
end

function widget:SelectionChanged()
	if ready then
		TrackSelection()
	end
end

-- team colours can change (a spectator's colour settings)
function widget:PlayerChanged()
	teamColour = {}
end

function widget:DrawWorld()
	if not ready or Spring.IsGUIHidden() then
		return
	end
	-- SelectionChanged is not sent for every change (a selected ship dying, for one)
	TrackSelection()
	local data, count = Collect()
	if count == 0 then
		return
	end
	local vsx, vsy = Spring.GetViewGeometry()

	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.Culling(false)
	gl.Blending(GL.ONE, GL.ONE_MINUS_SRC_ALPHA) -- the shader's colours are premultiplied

	instances:Upload(data, nil, 0, 1, count * 8)
	gl.UseShader(shader)
	gl.Uniform(uniforms.viewport, vsx, vsy)
	gl.Uniform(uniforms.time, Now())
	gl.Uniform(uniforms.minPixels, MIN_PIXELS)
	gl.Uniform(uniforms.extent, EXTENT)
	gl.Uniform(uniforms.popSeconds, POP_SECONDS)
	vao:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, count, 0)
	gl.UseShader(0)

	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthMask(true)
end
