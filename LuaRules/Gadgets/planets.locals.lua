--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied     = Spring.AreTeamsAllied
local spEcho               = Spring.Echo
local spGetGaiaTeamID      = Spring.GetGaiaTeamID
local spGetModOptions      = Spring.GetModOptions
local spGetTeamColor       = Spring.GetTeamColor
local spGetTeamInfo        = Spring.GetTeamInfo
local spGetTeamList        = Spring.GetTeamList
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitTeam        = Spring.GetUnitTeam
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spValidUnitID        = Spring.ValidUnitID
local spGetLocalTeamID     = Spring.GetLocalTeamID
local spGetSpectatingState = Spring.GetSpectatingState

local math				   = math
local pairs				   = pairs
local ipairs			   = ipairs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Planets",
		desc = "Enables planets (duh!)",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 4,
		enabled = true
	}
end

local planet = UnitDefNames.planet.id
local incomePerPlanet = spGetModOptions().income or 10
local occupationRange = 500
local defaultOccupationStrength=.5
local pubSupportMult=1.2

local tutorialmessage = true

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local planets = {}

local occupiers={}

local pattern = spGetModOptions().pattern or "standoff"
local number = spGetModOptions().planetcount or 10

local money
local lastIncome
local allyTeam={}

local patterns={
	orion={
		{.3,.1}, {.8,.15},
		{.37,.42},{.5,.5},{.63,.58},
		{.1,.48},{.9,.52},
		{.2,.85},{.7,.9},
	},
	standoff={
		{.5,.05},
		{.15,.25},{.85,.25},
		{.4,.35},{.6,.35},
		{.4,.65},{.6,.65},
		{.15,.75},{.85,.75},
		{.5,.95},
	},
	lineandside={
		{.51,.1},{.5,.36},{.52,.63},{.48,.9},
		{.05,.4},{.20,.5},{.07,.62},
		{.95,.41},{.78,.5},{.96,.6},
	},
	trail={
		{.05,.05},{.2,.32},{.4,.55},{.6,.45},{.8,.68},{.95,.95},
		{.9,.15},{.1,.85},
	}
}

function gadget:Initialize()
	if patterns[pattern] then
		local mx = Game.mapSizeX
		local mz = Game.mapSizeZ
		for i,data in pairs(patterns[pattern]) do
			planets[i]= {
				x=mx*data[1], z=mz*data[2],
				lastOwner=nil,
			}
		end
	else
		for i = 1,(number*312) do
			math.random(10) --add some randomness
		end
		for i = 1,number/2 do
			local x = math.random(Game.mapSizeX)
			local z = math.random(Game.mapSizeZ)
			planets[i * 2 - 1] = {
				x = x,
				z = z,
				lastOwner = nil,
			}
			if pattern == "randompoint" then
				planets[i * 2] = {
					x = Game.mapSizeX - x,
					z = Game.mapSizeZ - z,
					lastOwner = nil,
				}
			elseif pattern == "randomx" then
				planets[i * 2] = {
					x = Game.mapSizeX - x,
					z = z,
					lastOwner = nil,
				}
			elseif pattern == "randomz" then
				planets[i * 2] = {
					x = x,
					z = Game.mapSizeZ - z,
					lastOwner = nil,
					lastStrength = 0,
					lastOccupier = nil,
				}
			else
				planets[i * 2] = {
					x = math.random(Game.mapSizeX),
					z = math.random(Game.mapSizeZ),
					lastOwner = nil,
					lastStrength = 0,
					lastOccupier = nil,
				}
			end
		end
	end

	for _,t in ipairs(spGetTeamList()) do
		_,_,_,_,_,allyTeam[t] = spGetTeamInfo(t)
		spEcho(t..": "..allyTeam[t])
	end

	for i,ud in pairs(UnitDefs) do
		if ud.customParams.occupationstrength then
			occupiers[i]=tonumber(ud.customParams.occupationstrength)
		end
	end

	GG.planets = planets
	GG.occupationRange = occupationRange
	_G.planets = planets
	money = GG.money
	lastIncome=GG.lastIncome
end

function gadget:GameFrame(f)
	if f % 30 < .1 then
		for t,_ in pairs(lastIncome) do
			lastIncome[t]=0
		end
		for i,p in pairs(planets) do
			local owner = nil
			local contested = false
			local strength = 0
			local occupier = nil
			for _,u in ipairs(spGetUnitsInCylinder(p.x, p.z, occupationRange)) do
				local t = spGetUnitTeam(u)
				local oc = occupiers[spGetUnitDefID(u)] or defaultOccupationStrength
				if oc > 0 then --0 marks units that shouldn't occupy
					if not owner then
						owner = t
						occupier=u
					elseif not spAreTeamsAllied(owner, t) then
						if oc > strength then
							owner = t
							contested = false
							occupier=u
						elseif oc == strength then
							contested = true
							occupier=nil
						end
					end
					if oc > strength then
						strength = oc
						occupier=u
					end
				end
			end
			if not contested and owner then
				p.lastOwner = owner
				p.lastStrength = incomePerPlanet * strength
				p.lastOccupier = occupier
				local ao = allyTeam[owner]
				for t, a in pairs(allyTeam) do
					if a == ao then
						if (GG.perks[t].have[3] and strength >= 2.5) then --Public Support
							money[t] = money[t] + incomePerPlanet * strength * pubSupportMult
							lastIncome[t] = lastIncome[t] + incomePerPlanet * strength * pubSupportMult
						else
							money[t] = money[t] + incomePerPlanet * strength
							lastIncome[t] = lastIncome[t] + incomePerPlanet * strength
						end
					end
				end
			else
				p.lastOwner = nil
				p.lastStrength = 0
				p.lastOccupier = nil
			end
		end
	end
	if f == 900 then
		local teams = {}
		for _,t in ipairs(spGetTeamList()) do
			teams[t] = true
		end
		for _,p in pairs(planets) do
			for t,_ in pairs(teams) do
				if allyTeam[t] == allyTeam[p.lastOwner] then
					teams[t]=nil
				end
			end
		end
		for team,_ in pairs(teams) do
			GG.message[team].text = "You do not have any planets!"
			GG.message[team].hint = "Capture planets by moving ships into their circles"
			GG.message[team].timeout = f + 180
		end
	end
end

else

--UNSYNCED

local GL_BACK              = GL.BACK
local GL_LEQUAL            = GL.LEQUAL
local GL_LINES             = GL.LINES
local GL_TRIANGLE_FAN      = GL.TRIANGLE_FAN
local glBeginEnd           = gl.BeginEnd
local glBillboard          = gl.Billboard
local glCallList           = gl.CallList
local glColor              = gl.Color
local glCreateList         = gl.CreateList
local glCulling            = gl.Culling
local glDeleteList         = gl.DeleteList
local glDepthTest          = gl.DepthTest
local glDrawGroundCircle   = gl.DrawGroundCircle
local glLighting           = gl.Lighting
local glLineStipple        = gl.LineStipple
local glLoadIdentity       = gl.LoadIdentity
local glPopMatrix          = gl.PopMatrix
local glPushMatrix         = gl.PushMatrix
local glRotate             = gl.Rotate
local glScale              = gl.Scale
local glText               = gl.Text
local glTranslate          = gl.Translate
local glUnitShape          = gl.UnitShape
local glVertex             = gl.Vertex

local gaia = spGetGaiaTeamID()
local circle

local Vertex = glVertex
local Lighting = glLighting
local PushMatrix = glPushMatrix
local Translate = glTranslate
local UnitShape = glUnitShape
local PopMatrix = glPopMatrix
local Color = glColor
local DrawGroundCircle = glDrawGroundCircle
local GetTeamColor = spGetTeamColor
local CallList = glCallList

local function CircleFunc()
	Vertex(0,0,0)
	for i = 40,0,-1 do
		local angle = math.pi * .05 * i
		Vertex(math.cos(angle)*occupationRange,0,math.sin(angle)*occupationRange)
	end
end

local function Line(sx,sy,sz,tx,ty,tz)
	Vertex(sx,sy,sz)
	Vertex(tx,ty,tz)
end

--------------------------------------------------------------------------------
-- Procedural planets
--
-- Every planet is one camera-facing quad; the shader in Shaders/planet.frag
-- paints a sphere on it (earthlike, water, desert, ice, volcanic, gas giant
-- or barren moon) from noise, so no textures or models are involved. Which
-- kind each planet is, its size and its look are derived from the game's ID,
-- so they differ from game to game but are the same for every player.
-- tools/planets/make_preview.py shows the same shader in a web browser.

local PLANET_Y = -300   -- planets hang below the plane the ships fly in
local SHADER_PATH = "LuaRules/Gadgets/Shaders/planet.frag"
local LIGHT = {-0.52, 0.68, -0.52}   -- direction towards the sun

local EARTHLIKE, WATER, DESERT, ICE, VOLCANIC, GAS, BARREN = 0, 1, 2, 3, 4, 5, 6
-- smallest and largest radius of each kind, and its colour on the minimap
local KINDS = {
	[EARTHLIKE] = {min = 225, max = 260, colour = {0.25, 0.50, 0.45}},
	[WATER]     = {min = 225, max = 260, colour = {0.12, 0.32, 0.65}},
	[DESERT]    = {min = 205, max = 240, colour = {0.74, 0.50, 0.30}},
	[ICE]       = {min = 195, max = 230, colour = {0.72, 0.84, 0.95}},
	[VOLCANIC]  = {min = 195, max = 230, colour = {0.55, 0.20, 0.08}},
	[GAS]       = {min = 255, max = 270, colour = {0.78, 0.66, 0.46}},
	[BARREN]    = {min = 165, max = 200, colour = {0.50, 0.48, 0.45}},
}
local RINGED_RADIUS = 215   -- a ringed giant is smaller, so its rings fit the capture circle

local planetShader
local shaderFailed = false
local uniforms = {}
local visuals = {}      -- planet index -> {kind, seed, radius, ring}
local gameSalt
local startTimer

local VERTEX_SHADER = [[
varying vec3 worldPos;
void main() {
	worldPos = gl_Vertex.xyz;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
]]

-- a repeatable number in 0..1 for planet i
local function Rand(i, salt)
	local x = math.sin(i * 127.1 + salt * 311.7 + gameSalt) * 43758.5453
	return x - math.floor(x)
end

local function Visual(i)
	local v = visuals[i]
	if v then
		return v
	end
	if not gameSalt then
		gameSalt = 0
		local id = Game.gameID or ""
		for n = 1, #id do
			gameSalt = (gameSalt * 31 + id:byte(n)) % 9973
		end
	end
	-- deal the kinds out like a shuffled deck, so a game shows all of them
	-- before any kind comes up twice
	local order = {EARTHLIKE, WATER, DESERT, ICE, VOLCANIC, GAS, BARREN}
	for n = #order, 2, -1 do
		local j = 1 + math.floor(Rand(n, 5) * n)
		order[n], order[j] = order[j], order[n]
	end
	local round = math.floor((i - 1) / #order)
	local kind = order[((i - 1 + round * 3) % #order) + 1]
	local limits = KINDS[kind]
	v = {
		kind = kind,
		seed = Rand(i, 1) * 1000,
		radius = limits.min + (limits.max - limits.min) * Rand(i, 2),
		ring = false,
	}
	if kind == GAS and Rand(i, 3) < 0.6 then
		v.ring = true
		v.radius = RINGED_RADIUS
	end
	visuals[i] = v
	return v
end

local function LoadPlanetShader()
	local fragment = VFS.LoadFile(SHADER_PATH, VFS.ZIP)
	if not fragment then
		spEcho("[Planets] " .. SHADER_PATH .. " is missing; planets are drawn as plain discs")
		return nil
	end
	if not gl.CreateShader then
		spEcho("[Planets] shaders are not available; planets are drawn as plain discs")
		return nil
	end
	local shader = gl.CreateShader({vertex = VERTEX_SHADER, fragment = fragment})
	if not shader then
		spEcho("[Planets] the planet shader did not compile; planets are drawn as plain discs. Log:")
		spEcho(gl.GetShaderLog())
		return nil
	end
	for _, name in ipairs({"camPos", "center", "radius", "ptype", "seed", "time", "lightDir", "ring"}) do
		uniforms[name] = gl.GetUniformLocation(shader, name)
		if not uniforms[name] or uniforms[name] < 0 then
			spEcho("[Planets] the planet shader has no uniform '" .. name .. "'")
		end
	end
	return shader
end

local function QuadFunc(x, y, z, rx, ry, rz, ux, uy, uz)
	Vertex(x - rx - ux, y - ry - uy, z - rz - uz)
	Vertex(x + rx - ux, y + ry - uy, z + rz - uz)
	Vertex(x + rx + ux, y + ry + uy, z + rz + uz)
	Vertex(x - rx + ux, y - ry + uy, z - rz + uz)
end

local function DrawPlanets()
	if not planetShader and not shaderFailed then
		planetShader = LoadPlanetShader()
		shaderFailed = planetShader == nil
		startTimer = Spring.GetTimer()
	end

	if not planetShader then
		-- plain discs in each kind's colour
		for i, p in pairs(SYNCED.planets) do
			local v = Visual(i)
			local c = KINDS[v.kind].colour
			PushMatrix()
			Translate(p.x, PLANET_Y, p.z)
			glScale(v.radius / occupationRange, 1, v.radius / occupationRange)
			Color(c[1], c[2], c[3], 1)
			CallList(circle)
			PopMatrix()
		end
		Color(1, 1, 1, 1)
		return
	end

	local cx, cy, cz = Spring.GetCameraPosition()
	local vectors = Spring.GetCameraVectors()
	local right, up = vectors.right, vectors.up

	-- far planets first, so a nearer one's halo or rings lie over them
	local list = {}
	for i, p in pairs(SYNCED.planets) do
		local dx, dy, dz = p.x - cx, PLANET_Y - cy, p.z - cz
		list[#list + 1] = {i = i, x = p.x, z = p.z, distance = math.sqrt(dx * dx + dy * dy + dz * dz)}
	end
	table.sort(list, function(a, b) return a.distance > b.distance end)

	glDepthTest(false)
	gl.DepthMask(false)
	gl.Blending(GL.ONE, GL.ONE_MINUS_SRC_ALPHA) -- the shader's colours are premultiplied
	gl.UseShader(planetShader)
	gl.Uniform(uniforms.camPos, cx, cy, cz)
	gl.Uniform(uniforms.lightDir, LIGHT[1], LIGHT[2], LIGHT[3])
	gl.Uniform(uniforms.time, Spring.DiffTimers(Spring.GetTimer(), startTimer))
	for _, entry in ipairs(list) do
		local v = Visual(entry.i)
		-- the quad has to cover the sphere's outline with its halo (and the
		-- rings), which grows as the camera comes closer
		local reach = v.radius * (v.ring and 2.1 or 1.3)
		local closeness = math.min(0.9, reach / math.max(entry.distance, 1))
		local extent = reach / math.sqrt(1 - closeness * closeness) * (v.ring and 1.25 or 1.0)
		gl.Uniform(uniforms.center, entry.x, PLANET_Y, entry.z)
		gl.Uniform(uniforms.radius, v.radius)
		gl.Uniform(uniforms.ptype, v.kind)
		gl.Uniform(uniforms.seed, v.seed)
		gl.Uniform(uniforms.ring, v.ring and 1 or 0)
		glBeginEnd(GL.QUADS, QuadFunc, entry.x, PLANET_Y, entry.z,
			right[1] * extent, right[2] * extent, right[3] * extent,
			up[1] * extent, up[2] * extent, up[3] * extent)
	end
	gl.UseShader(0)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthMask(true)
end

function gadget:DrawWorldPreUnit()
	glCulling(false)
	DrawPlanets()
	for i,p in pairs(SYNCED.planets) do
		if p.lastOwner then
			PushMatrix()
			local r,g,b = GetTeamColor(p.lastOwner or gaia)
			Color(r,g,b,.2)
			Translate(p.x, 0, p.z)
			CallList(circle)
			PopMatrix()
		end
		Color(1,1,1,1)
	end
end

function gadget:DrawWorld()
	local team=spGetLocalTeamID()
	local _,spec=spGetSpectatingState()
	for i,p in pairs(SYNCED.planets) do
		local r,g,b = GetTeamColor(p.lastOwner or gaia)
		Color(r,g,b,1)
		DrawGroundCircle(p.x, 0, p.z, occupationRange, 30)
		if p.lastOwner and (spec or spAreTeamsAllied(team,p.lastOwner)) then
			PushMatrix()
			Translate(p.x, 100, p.z)
			glBillboard()
			glText("+"..p.lastStrength,0,0,24,"oc")
			PopMatrix()
			if spValidUnitID(p.lastOccupier) then
				local x,y,z=spGetUnitPosition(p.lastOccupier)
				glDepthTest(GL_LEQUAL)
				glLineStipple("bla")
				DrawGroundCircle(x, 0, z, 30, 12)
				glBeginEnd(GL_LINES,Line,x,0,z,p.x,0,p.z)
				glLineStipple(false)
				glDepthTest(false)
			end
		end
	end
	Color(1,1,1,1)
end

-- On the minimap a planet is a disc in the colour of its kind. (The capture
-- rings in team colours are drawn by LuaUI/widgets/gui_minimap.lua.)
function gadget:DrawInMiniMap(mmsx, mmsy)
	glPushMatrix()
	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(1/Game.mapSizeX, -1/Game.mapSizeZ, 1)
	glRotate(270,1,0,0)
	glCulling(false)
	for i,p in pairs(SYNCED.planets) do
		local v = Visual(i)
		local c = KINDS[v.kind].colour
		PushMatrix()
		Translate(p.x, 0, p.z)
		glScale(v.radius / occupationRange, 1, v.radius / occupationRange)
		Color(c[1], c[2], c[3], 0.9)
		CallList(circle)
		PopMatrix()
	end
	Color(1,1,1,1)
	glPopMatrix()
end

function gadget:Initialize()
	circle = glCreateList(glBeginEnd,GL_TRIANGLE_FAN,CircleFunc)
end

function gadget:Shutdown()
	glDeleteList(circle)
	if planetShader then
		gl.DeleteShader(planetShader)
		planetShader = nil
	end
end

end
