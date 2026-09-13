--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spEcho                 = Spring.Echo
local spGetGameFrame         = Spring.GetGameFrame
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitsInRectangle  = Spring.GetUnitsInRectangle
local spIsGUIHidden          = Spring.IsGUIHidden

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Gravidar",
		desc = "Shows grav data",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 15,
		enabled = false
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

-- IR sensor extension -- goes here because making a new gadget for it is just silly
function gadget:UnitCreated(unitID, unitDefID, team)
	local hasPerk = GG.perks[team].have[5] --improved gravidar
	local radius = UnitDefs[unitDefID].radarRadius
	if hasPerk and radius then
		Spring.SetUnitSensorRadius(unitID, "radar", radius*1.5)
	end
end

local function CheckRadar(team)
	local units
	if team then units = Spring.GetTeamUnits(team)
	else units = Spring.GetAllUnits() end
	
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		team = team or Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end
GG.CheckRadar = CheckRadar

function gadget:Initialize()
	_G.perks = GG.perks
	_G.planets = GG.planets
	CheckRadar()
end

else

--UNSYNCED

local GL_LEQUAL              = GL.LEQUAL
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_QUADS               = GL.QUADS
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glLoadIdentity         = gl.LoadIdentity
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRect                 = gl.Rect
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex

local gravdata = {}
local gravCL = {}
local lowres = {}
local lowresCL = {}

local resolution = 128
local noPerkPenalty = 8
local minMass = 14
local maxMass = 6400
local planetRadius = 2
local planetMass = 8000
local shipRadius = 1
local maxV = math.sqrt(maxMass)
local lastUpdate = 0
local lastLine = 0
local drawInView=false
local intensity=.4

local lowresSizeX, lowresSizeZ
local gravSizeX, gravSizeZ

local rectSmall
local rectLarge

local GetUnitPosition = spGetUnitPosition
local floor = math.floor
local log = math.log
local sqrt = math.sqrt
local random = math.random
local GetUnitDefID = spGetUnitDefID
local CallList = glCallList
local Color = glColor
local Rect = glRect
local Translate = glTranslate
local PushMatrix = glPushMatrix
local PopMatrix = glPopMatrix

local function DrawGravLine(y)
	local l = gravdata[y]
	PushMatrix()
	for x = 0,gravSizeX do
		--spEcho(x.." "..y)
		local val = intensity * sqrt(l[x]) / maxV
		Color(val,val,val,1)
		CallList(rectSmall)
		Translate(resolution,0,0)
	end
	PopMatrix()
end

local function UpdateLine(y)
	local line = gravdata[y]
	for x,_ in pairs(line) do --zero the line
		line[x] = 0
	end
	local units = spGetUnitsInRectangle(0, (y-shipRadius)*resolution, Game.mapSizeX, (y+1+shipRadius)*resolution)
	for i=1, #units do
		local u = units[i]
		local x = GetUnitPosition(u)
		local m = UnitDefs[GetUnitDefID(u)].mass *.1
		local pos = floor(x/resolution)
		for i = -shipRadius,shipRadius do
			if line[pos + i] then
				line[pos + i] = line[pos + i] + m
			end
		end
	end
	for _,p in pairs(SYNCED.planets) do
		if p.z > (y - planetRadius)*resolution and p.z < (y + 1 + planetRadius)*resolution then
			local pos = floor(p.x/resolution)
			for i = -planetRadius,planetRadius do
				if line[pos + i] then
					line[pos + i] = line[pos + i] + planetMass
				end
			end
		end
	end

	if gravCL[y] then
		glDeleteList(gravCL[y])
	end
	gravCL[y] = glCreateList(DrawGravLine,y)
end

local function UpdateLowres(ly)
	local y = floor(ly / noPerkPenalty)
	line = lowres[y]
	if line then
		for x=0,lowresSizeX do
			local sum = 0
			for gx = 0,noPerkPenalty - 1 do
				for gy = 0,noPerkPenalty - 1 do
					--spEcho(y * noPerkPenalty + gy)
					local v = gravdata[y * noPerkPenalty + gy][x * noPerkPenalty + gx]
					if v > minMass then
						sum = sum + v
					end
				end
			end
			sum = sum / (noPerkPenalty * noPerkPenalty)
			line[x]= sum
		end
	end
end

local function Rect(x,z)
	glVertex(0,0,0)
	glVertex(x,0,0)
	glVertex(x,0,z)
	glVertex(0,0,z)
end

function gadget:Initialize()
	lowresSizeZ = (Game.mapSizeZ-1) / resolution / noPerkPenalty
	lowresSizeX = (Game.mapSizeX-1) / resolution / noPerkPenalty
	gravSizeZ=(Game.mapSizeZ-1) / resolution
	gravSizeX=(Game.mapSizeX-1) / resolution
	for y = 0, gravSizeZ do
		local d = {}
		for x = 0, gravSizeX do
			d[x] = 0
		end
		gravdata[y]=d
	end
	for y = 0, lowresSizeZ do
		local d = {}
		for x = 0, lowresSizeX do
			d[x] = 0
		end
		lowres[y]=d
	end
	rectSmall = glCreateList(glBeginEnd, GL_QUADS, Rect, resolution, resolution)
	rectLarge = glCreateList(glBeginEnd, GL_QUADS, Rect, resolution*noPerkPenalty, resolution*noPerkPenalty)
end

function gadget:Shutdown()
	glDeleteList(rectSmall)
	glDeleteList(rectLarge)
end

function gadget:Update()
	local hasPerk = SYNCED.perks[spGetLocalTeamID()].have[5] --improved gravidar
	if lastUpdate < spGetGameFrame() then
		lastUpdate = spGetGameFrame()
		if gravdata[lastline] then
			UpdateLine(lastline)
			if not hasPerk then
				UpdateLowres(lastline)
			end
			lastline = lastline + 1
		else
			lastline = 0
		end
	end
end

local function DrawGrav()
	local hasPerk = SYNCED.perks[spGetLocalTeamID()].have[5] --improved gravidar
	glBlending(GL_ONE, GL_ONE)
	glDepthTest(GL_LEQUAL)
	PushMatrix()
	if hasPerk then
		for y = 0,gravSizeZ do
			if gravCL[y] then
				CallList(gravCL[y])
			end
			Translate(0,0,resolution)
		end
	else
		glDepthTest(GL_LEQUAL)
		PushMatrix()
		for y=0,lowresSizeZ do
			l=lowres[y]
			PushMatrix()
			for x=0,lowresSizeX do
				local val = intensity * sqrt(l[x]) / maxV
				Color(val,val,val,1)
				CallList(rectLarge)
				Translate(resolution*noPerkPenalty,0,0)
			end
			PopMatrix()
			Translate(0,0,resolution*noPerkPenalty)
		end
		PopMatrix()
	end
	PopMatrix()
	glDepthTest(false)
	glColor(1,1,1,1)
	glBlending(GL_ONE,GL_ONE_MINUS_SRC_ALPHA)
end

function gadget:DrawWorld()
	if Script.LuaUI("QueryGravDisplay") then
		drawInView = Script.LuaUI.QueryGravDisplay()
	end
	if spIsGUIHidden() or not drawInView then
		return
	end
	DrawGrav()
end

function gadget:DrawInMiniMap(mmsx, mmsy)
	PushMatrix()
	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(1/Game.mapSizeX, 1/Game.mapSizeZ, 1)
	glRotate(90,1,0,0)
	DrawGrav()
	glPopMatrix()
	--[[
	local hasPerk = SYNCED.perks[spGetLocalTeamID()].have[5] --improved gravidar
	if hasPerk then
		local stepX = mmsx / gravSizeX
		local stepY = -mmsy / gravSizeZ
		for y = 0,gravSizeZ do
			l = gravdata[y]
			for x = 0,gravSizeX do
				--spEcho(x.." "..y)
				local val = sqrt(l[x]) / maxV
				Color(val,val,val,.4)
				Rect(x*stepX, y*stepY, (x+1)*stepX, (y+1)*stepY)
			end
		end
		glColor(1,1,1,1)
	else
		local stepX = mmsx / lowresSizeX
		local stepY = mmsy / lowresSizeZ
		for y=0,lowresSizeZ do
			l=lowres[y]
			for x=0,lowresSizeX do
				local val = sqrt(l[x]) / maxV
				Color(val,val,val,.4)
				Rect(x*stepX, y*stepY, (x+1)*stepX, (y+1)*stepY)
			end
		end
		Color(1,1,1,1)
	end]]--
end

end
