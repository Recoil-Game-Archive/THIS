--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Selection frames.
--
--  Replaces the engine's green selection squares. Every selected ship gets a
--  frame the size of its hitbox (its collision volume: length and beam), lying
--  in the ship's own plane and turning with it, in its team's colour:
--    - a thin outline of the hitbox,
--    - bright brackets on its four corners, breathing slightly,
--    - a glint running round the outline,
--    - a small tick on the bow, so the heading reads at a glance.
--  A newly selected ship's frame closes in from a little further out.
--  Round hitboxes (upright cylinders, spheres) get a round frame.
--
--  Far away, a frame never gets smaller than MIN_PIXELS, so small ships stay
--  easy to find in a large selection. Line widths are in screen pixels at any
--  distance and tilt.
--
--  All frames go out in one instanced call. If the engine cannot do that,
--  this widget switches itself off and the engine's squares stay.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Selection Rings",
		desc = "Animated frames the size of the hitbox around selected ships, instead of the engine's squares",
		author = "THIS contributors",
		date = "2026-11-22",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local MAX_RINGS = 2048
local MIN_PIXELS = 10          -- smallest half-size of a frame on screen
local MARGIN_PIXELS = 14       -- the quad reaches this far beyond the hitbox (bow tick, glow)
local POP_SECONDS = 0.35       -- how long a new frame takes to close in
local WHITEN = 0.25            -- team colour mixed towards white, so dark team colours still read
local CORNER_ROUNDING = 0.12   -- corner radius of a box frame, as a share of its shorter half-side

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
layout (location = 1) in vec4 place;      // centre of the hitbox, and the time the ship was selected
layout (location = 2) in vec4 right;      // the ship's right vector, and half the hitbox's width
layout (location = 3) in vec4 front;      // the ship's front vector, and half the hitbox's length
layout (location = 4) in vec4 colour;     // rgb, and the corner radius as a share of the shorter half-side
uniform vec2 viewport;
uniform float time;
uniform float minPixels;
uniform float marginPixels;
uniform float popSeconds;
out vec2 p;              // position in the ship's plane, in world units from the centre
flat out vec2 vHalf;     // half width, half length of the frame
flat out float vRadius;  // corner radius
flat out vec3 vColour;
flat out float vAge;     // 0 just selected .. 1 settled
void main() {
	vec2 q = vec2(corner.x * 2.0 - 1.0, corner.y);
	vec4 centre = gl_ModelViewProjectionMatrix * vec4(place.xyz, 1.0);
	// pixels per world unit at the ship: a point one unit to the camera's right of the centre
	vec3 camRight = vec3(gl_ModelViewMatrix[0][0], gl_ModelViewMatrix[1][0], gl_ModelViewMatrix[2][0]);
	vec4 edge = gl_ModelViewProjectionMatrix * vec4(place.xyz + camRight, 1.0);
	float pixelsPerUnit = max(length((edge.xy / edge.w - centre.xy / centre.w) * viewport * 0.5), 1.0e-5);

	float age = clamp((time - place.w) / popSeconds, 0.0, 1.0);
	float pop = 1.0 + 0.40 * pow(1.0 - age, 3.0);   // closes in from further out
	vec2 halfSize = vec2(right.w, front.w);
	// never smaller than minPixels on screen
	halfSize *= max(1.0, minPixels / (max(halfSize.x, halfSize.y) * pixelsPerUnit));
	halfSize *= pop;

	vec2 reach = halfSize + vec2(marginPixels / pixelsPerUnit);
	p = q * reach;
	gl_Position = gl_ModelViewProjectionMatrix * vec4(place.xyz + right.xyz * p.x + front.xyz * p.y, 1.0);
	vHalf = halfSize;
	vRadius = colour.a * min(halfSize.x, halfSize.y);
	vColour = colour.rgb;
	vAge = age;
}
]]

local FRAGMENT = [[
#version 330 compatibility
in vec2 p;
flat in vec2 vHalf;
flat in float vRadius;
flat in vec3 vColour;
flat in float vAge;
uniform float time;
out vec4 fragColor;

// distance to the outline of a rounded rectangle: negative inside
float roundRect(vec2 pos, vec2 halfSize, float radius) {
	vec2 d = abs(pos) - halfSize + vec2(radius);
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void main() {
	float d = roundRect(p, vHalf, vRadius);
	float px = max(fwidth(d), 1.0e-5);        // one screen pixel, in world units, at this tilt and distance
	float shorter = min(vHalf.x, vHalf.y);

	// the hitbox outline: thin and quiet
	float outline = (1.0 - smoothstep(0.5 * px, 1.5 * px, abs(d))) * 0.40;

	// brackets on the corners: the outline, brighter and thicker, where both sides are near a corner
	float reach = clamp(shorter * (0.50 + 0.05 * sin(time * 2.2)), 4.0 * px, 60.0 * px);
	vec2 fromCorner = vHalf - abs(p);
	float nearCorner = (1.0 - smoothstep(reach - px, reach + px, fromCorner.x))
	                 * (1.0 - smoothstep(reach - px, reach + px, fromCorner.y));
	float brackets = (1.0 - smoothstep(1.1 * px, 2.1 * px, abs(d))) * nearCorner;

	// a glint running round the outline
	float angle = atan(p.y / vHalf.y, p.x / vHalf.x);
	float behind = mod(angle - time * 1.5, 6.2831853);
	float glint = exp(-behind * 2.0) * (1.0 - smoothstep(1.2 * px, 2.4 * px, abs(d)));

	// a tick on the bow, pointing ahead
	float tick = (1.0 - smoothstep(0.6 * px, 1.6 * px, abs(p.x)))
	           * step(0.0, p.y) * smoothstep(-0.5 * px, 0.5 * px, d) * (1.0 - smoothstep(6.0 * px, 7.0 * px, d));

	// a soft glow hugging the outline on the inside
	float glow = (d < 0.0) ? exp(d / (5.0 * px)) * 0.14 : exp(-d / (2.5 * px)) * 0.08;

	float light = outline + brackets + tick * 0.9 + glow;
	float white = glint * 0.85 + brackets * 0.15;
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
	for _, name in ipairs({"viewport", "time", "minPixels", "marginPixels", "popSeconds"}) do
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
		{id = 2, name = "right", size = 4},
		{id = 3, name = "front", size = 4},
		{id = 4, name = "colour", size = 4},
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

-- 16 numbers for every selected ship: the hitbox's centre and the time selected, the ship's right vector and
-- half the hitbox's width, its front vector and half the length, the colour and the corner rounding
local STRIDE = 16
local function Collect()
	local data, n, count = {}, 0, 0
	for unitID, since in pairs(selectedAt) do
		if count >= MAX_RINGS then
			break
		end
		local _, _, _, x, y, z = Spring.GetUnitPosition(unitID, true) -- the middle of the ship, not its base point
		local sx, sy, sz, ox, oy, oz, volumeType, _, primaryAxis = Spring.GetUnitCollisionVolumeData(unitID)
		local front, up, right = Spring.GetUnitVectors(unitID)
		if x and sx and front and not Spring.GetUnitNoDraw(unitID) then
			if ox ~= 0 or oy ~= 0 or oz ~= 0 then -- a hitbox that is off-centre
				x = x + right[1] * ox + up[1] * oy + front[1] * oz
				y = y + right[2] * ox + up[2] * oy + front[2] * oz
				z = z + right[3] * ox + up[3] * oy + front[3] * oz
			end
			-- boxes (2) and lying cylinders get a box frame; upright cylinders (1, axis 1), ellipsoids (0) and
			-- spheres (3) a round one
			local round = (volumeType == 0) or (volumeType == 3) or (volumeType == 1 and primaryAxis == 1)
			local colour = TeamColour(Spring.GetUnitTeam(unitID))
			data[n + 1], data[n + 2], data[n + 3], data[n + 4] = x, y, z, since
			data[n + 5], data[n + 6], data[n + 7], data[n + 8] = right[1], right[2], right[3], sx * 0.5
			data[n + 9], data[n + 10], data[n + 11], data[n + 12] = front[1], front[2], front[3], sz * 0.5
			data[n + 13], data[n + 14], data[n + 15], data[n + 16] = colour[1], colour[2], colour[3], round and 1 or CORNER_ROUNDING
			n = n + STRIDE
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

	instances:Upload(data, nil, 0, 1, count * STRIDE)
	gl.UseShader(shader)
	gl.Uniform(uniforms.viewport, vsx, vsy)
	gl.Uniform(uniforms.time, Now())
	gl.Uniform(uniforms.minPixels, MIN_PIXELS)
	gl.Uniform(uniforms.marginPixels, MARGIN_PIXELS)
	gl.Uniform(uniforms.popSeconds, POP_SECONDS)
	vao:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, count, 0)
	gl.UseShader(0)

	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthMask(true)
end
