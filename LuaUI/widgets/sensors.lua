function widget:GetInfo()
	return {
		name = "sensors",
		desc = "displays sensors",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 256,
		enabled = true
	}
end

local PushMatrix = gl.PushMatrix
local PopMatrix = gl.PopMatrix
local Vertex = gl.Vertex
local Translate = gl.Translate
local CallList = gl.CallList
local CreateList = gl.CreateList
local BeginEnd = gl.BeginEnd
local Color = gl.Color

local GetTeamColor = Spring.GetTeamColor
local GetUnitTeam = Spring.GetUnitTeam
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitPosition = Spring.GetUnitPosition

local boundary

local drawRanges = false
local drawGrav = false

sensorDrawLists = {}

local function ToggleRanges()
	drawRanges = not drawRanges
	drawGrav = drawRanges
end

local function QueryGravDisplay()
	return drawGrav
end

local function SensorRange(r)
	Vertex(0,0,0)
	for i = 0,40 do
		local angle = math.pi * .05 * i
		Vertex(math.cos(angle)*r,0,math.sin(angle)*r)
	end
end

local function DrawSensor(x,z,r)
	PushMatrix()
	Translate(x,0,z)
	if sensorDrawLists[r] then
		CallList(sensorDrawLists[r])
	else
		sensorDrawLists[r] = CreateList(BeginEnd,GL.TRIANGLE_FAN,SensorRange,r)
	end
	PopMatrix()
end

local function LineToZero(x,y,z)
	Vertex(x,y,z)
	Vertex(x,0,z)
end

local function MapBoundary()
	Vertex(0,0,0)
	Vertex(0,0,Game.mapSizeZ)
	Vertex(Game.mapSizeX,0,Game.mapSizeZ)
	Vertex(Game.mapSizeX,0,0)
	Vertex(0,0,0)
end

function widget:DrawWorldPreUnit()
	if drawRanges then
		--gl.DepthTest(GL.LEQUAL)
		--gl.PolygonOffset(10,10)
		gl.LineWidth(3)
		gl.DepthTest(GL.LEQUAL)
		--gl.DepthMask(true)
		for _,u in ipairs(Spring.GetAllUnits()) do
			local r,g,b = GetTeamColor(GetUnitTeam(u))
			Color(r,g,b,.3)
			local x,y,z = GetUnitPosition(u)
			local ud = UnitDefs[GetUnitDefID(u)]
			local radius = ud and ud.losRadius * 16 or 0
			DrawSensor(x,z,radius)
			Color(r,g,b,.6)
			BeginEnd(GL.LINES, LineToZero,x,y,z)
		end
		gl.DepthTest(false)
		gl.DepthMask(false)
		Color(1,1,1,1)
		gl.PolygonOffset(false)
		gl.LineWidth(1)
	end
	CallList(boundary)
end

function widget:Shutdown()
	for _,l in pairs(sensorDrawLists) do
		gl.DeleteList(l)
	end
	gl.DeleteList(boundary)
	widgetHandler:DeregisterGlobal("QueryGravDisplay")
end

function widget:Initialize()
	widgetHandler:AddAction("togglesensors", ToggleRanges, nil, "p")
	widgetHandler:RegisterGlobal("QueryGravDisplay", QueryGravDisplay)
	boundary = CreateList(BeginEnd, GL.LINE_STRIP, MapBoundary)
	Spring.SendCommands({
		"unbind Any+l togglelos",
		"bind l togglesensors",
	})
end

