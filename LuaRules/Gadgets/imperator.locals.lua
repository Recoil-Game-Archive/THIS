--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMDTYPE_ICON           = CMDTYPE.ICON
local spCreateUnit           = Spring.CreateUnit
local spTransferUnit         = Spring.TransferUnit
local spDestroyUnit          = Spring.DestroyUnit
local spGetGameFrame         = Spring.GetGameFrame
local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetLocalAllyTeamID   = Spring.GetLocalAllyTeamID
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetPositionLosState  = Spring.GetPositionLosState
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetSpectatingState   = Spring.GetSpectatingState
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitLosState      = Spring.GetUnitLosState
local spGetUnitPieceMap      = Spring.GetUnitPieceMap
local spGetUnitPiecePosDir   = Spring.GetUnitPiecePosDir
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitTeam          = Spring.GetUnitTeam
local spGiveOrderToUnit		 = Spring.GiveOrderToUnit 
local spInsertUnitCmdDesc    = Spring.InsertUnitCmdDesc
local spSetUnitNeutral       = Spring.SetUnitNeutral
local spSetUnitNoSelect      = Spring.SetUnitNoSelect
local spGetTeamUnitDefCount  = Spring.GetTeamUnitDefCount

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
-------POINT POSITIONS (piece names)-------
-- "hp" .. num
starboard first, then port 
(remember to add 1 to get the array index)
0, 1: forwardmost
2, 3: second forwardmost
4, 7: forward middle
5, 8: forward side middle
6: central
9, 13: tower front
10, 14: tower side
11, 15: tower rear
12, 16: side edge

-------HARDPOINT SUBTABLES (per hardpoint)-------
index = hardpoint ID
[1] = parent imperator (unitID)
[2] = imperator piece attached to (piece name string)
[3] = attached turret (unitID)
[4] = turret under construction (unitDefID)
[5] = gameframe for turret completion

-------IMPERATOR SUBTABLES (per imp)-------
index = imp ID
[hardpoints] = {
	[1-17] = hardpoint ID
}
--]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Imperator",
		desc = "all the extras for the Imperator battleship",
		author = "KDR_11k (David Becker)",
		date = "2008-10-11",
		license = "Public Domain",
		layer = 128,
		enabled = true
	}
end

local imperator=UnitDefNames.imperator.id
local hardpoint=UnitDefNames.imperator_hardpoint.id
local pointCount=17
local CMD_BUILD = 31000

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local imperators={}
local hardpoints={}
local attachments={}

local turrets={}

local newImpList={}

GG.imperators = imperators
GG.hardpoints = hardpoints

local function GetHeading(dx,dz)
	return spGetHeadingFromVector(dx,dz)/32756*3.1415
end

local udCannon
local udPlasma
local udAMBeam
local udPointDef
local udHive

function gadget:UnitCreated(u, ud, team)
	if ud == imperator then
		newImpList[u]=true
	elseif ud == hardpoint then
		for ud,d in pairs(turrets) do
			spInsertUnitCmdDesc(u,{
				id=CMD_BUILD+ud,	--CMD_BUILD+ud,
				name=d.name,
				tooltip="Install "..d.name.."\n"..d.tooltip.."\nCost: "..d.cost.."\nBuildtime: "..d.buildtime,
				type=CMDTYPE_ICON,
				texture="#"..ud,
				onlyTexture=true,
			})				
		end
	end
end

local destroyList={}
local transferList={}

function gadget:UnitDestroyed(u,ud,team)
	if imperators[u] then
		for i,h in pairs(imperators[u].hardpoints) do
			destroyList[h]=true
		end
		imperators[u]=nil
	end
	if hardpoints[u] then
		if hardpoints[u][3] then
			destroyList[hardpoints[u][3]]=true
			attachments[hardpoints[u][3]]=nil
		end
		hardpoints[u]=nil
	end
	if attachments[u] then
		hardpoints[attachments[u]][3]=nil
		spSetUnitNoSelect(attachments[u],false)
		attachments[u]=nil
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt, tag, synced)
	if turrets[cmd - CMD_BUILD] then
		local td = turrets[cmd - CMD_BUILD]
		if ud == hardpoint and hardpoints[u] and not (hardpoints[u][3] or hardpoints[u][4]) then
			if GG.money[team] >= td.cost then
				hardpoints[u][4]=cmd - CMD_BUILD
				hardpoints[u][5]=spGetGameFrame()+30*td.buildtime
				GG.money[team]=GG.money[team]-td.cost
			else
				local m = GG.message[team]
				m.text="Not enough money to install turret!"
				m.hint="Capture more planets to increase your income."
				m.timeout=spGetGameFrame()+120
			end
		end
		return false
	elseif ud == hardpoint then
		if cmd == CMD.STOP then
			if hardpoints[u][4] ~= nil then
				GG.money[team]=GG.money[team]+turrets[hardpoints[u][4]].cost
				hardpoints[u][4]=nil
				hardpoints[u][5]=nil
			end
		end
		return false
	end
	return true
end

function gadget:AllowUnitTransfer(u,ud,team,newteam,capture)
	if ud == hardpoint or turrets[ud] then
		return capture
	elseif imperators[u] then
		if spGetTeamUnitDefCount(newteam,imperator) < 1 and
				GG.globalbuild[newteam].current ~= imperator and
				GG.ready[newteam] ~= imperator then
			for _,h in pairs(imperators[u].hardpoints) do
				transferList[h]=newteam
				if hardpoints[h][3] then
					transferList[hardpoints[h][3]]=newteam
				end
			end
			return true
		else
			return false
		end
	end
	return true
end

function gadget:Initialize()
	for ud,d in pairs(UnitDefs) do
		if d.customParams.type=="turret" then
			local range=0
			if d.canAttack then
				range=WeaponDefs[d.weapons[1].weaponDef].range
			end
			turrets[ud]={
				name=d.humanName,
				tooltip=d.tooltip,
				cost=tonumber(d.customParams.cost),
				buildtime=tonumber(d.customParams.buildtime),
				perk=tonumber(d.customParams.needperk),
				arc=tonumber(d.customParams.arc or 360) / 180 * 3.1415,
				range=range,
			}
		end
	end
		for ud,d in pairs(turrets) do
			if d.name == "Battle Cannon" then
				udCannon = ud
			end
			if d.name == "Plasma Cannon" then
				udPlasma = ud
			end
			if d.name == "Antimatter Beam" then
				udAMBeam = ud
			end
			if d.name == "Drone Hive" then
				udHive = ud
			end
			if d.name == "Point Defense" then
				udPointDef = ud
			end
		end
	_G.hardpoints=hardpoints
	_G.turrets=turrets
end

function gadget:GameFrame(f)
	for u,newteam in pairs(transferList) do
		spTransferUnit(u,newteam,false)
	end
	for u,_ in pairs(newImpList) do
		local x,y,z=spGetUnitPosition(u)
		local team = spGetUnitTeam(u)
		local pm = spGetUnitPieceMap(u)
		local hp={}
		for i = 1,pointCount do
			local nu=spCreateUnit("imperator_hardpoint",x,y,z,0,team)
			if nu then
				Spring.MoveCtrl.Enable(nu)
				--spSetUnitNeutral(nu, true)
				local part = pm["hp"..(i-1)]
				hardpoints[nu]={u,part}
				hp[i]=nu
				SendToUnsynced("newHP",nu)
			end
		end
		imperators[u]= {
			hardpoints=hp,
		}
		SendToUnsynced("newImp",u)
		newImpList[u]=nil
	end
	for u,_ in pairs(destroyList) do
		spDestroyUnit(u)
		destroyList[u]=nil
	end
	for u,d in pairs(hardpoints) do
		local team = spGetUnitTeam(u)
		local px,py,pz,pdx,pdy,pdz=spGetUnitPiecePosDir(d[1],d[2])
		Spring.MoveCtrl.SetPosition(u,px,py,pz)
		Spring.MoveCtrl.SetRotation(u,0,GetHeading(pdx,pdz),0)
		if d[3] then
			Spring.MoveCtrl.SetPosition(d[3],px,py,pz)
			Spring.MoveCtrl.SetRotation(d[3],0,GetHeading(pdx,pdz),0)
		end
		if d[5] and d[5] < f then
			local nu = spCreateUnit(d[4],px,py,pz,0,spGetUnitTeam(u))
			if nu then
				d[4]=nil
				d[5]=nil
				d[3]=nu
				attachments[nu]=u
				Spring.MoveCtrl.Enable(nu)
				spSetUnitNoSelect(u,true)
			end
        end
	end
end

else

--UNSYNCED

local GL_LEQUAL              = GL.LEQUAL
local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_LINE_STRIP          = GL.LINE_STRIP
local glBeginEnd             = gl.BeginEnd
local glBillboard            = gl.Billboard
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
local glLineStipple          = gl.LineStipple
local glLineWidth            = gl.LineWidth
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRect                 = gl.Rect
local glTranslate            = gl.Translate
local glUnit                 = gl.Unit
local glUnitMultMatrix       = gl.UnitMultMatrix
local glVertex               = gl.Vertex

local size=.6

local markerList
local emptyList
local arcLists={}
local turrets

local function Circle()
	for i=0,19 do
		glVertex(math.sin(i/20*6.284)*80*size,4,math.cos(i/20*6.284)*80*size)
	end
end

local function Arrow()
	glVertex(0,4,45*size)
	glVertex(30*size,4,-45*size)
	glVertex(0,4,-15*size)
	glVertex(-30*size,4,-45*size)
end

local function Marker()
	glBeginEnd(GL_LINE_LOOP,Circle)
	glBeginEnd(GL_LINE_LOOP,Arrow)
end

local function Empty()
end


local function ArcLines(angle,length)
	angle=angle/2
	length=length+20
	glVertex(math.sin(angle)*length,0,math.cos(angle)*length)
	glVertex(0,0,0)
	glVertex(math.sin(-angle)*length,0,math.cos(angle)*length)
end

local function ArcEnd(angle,length)
	angle=angle/2
	for i=-20,20 do
		glVertex(math.sin(i/20*angle)*length,0,math.cos(i/20*angle)*length)
	end
end

local function Arc(angle,length)
	glColor(1,.6,0,1)
	if angle < 6 then
		glBeginEnd(GL_LINE_STRIP,ArcLines,angle,length)
	end
	glLineStipple(4,61680)
	glBeginEnd(GL_LINE_STRIP,ArcEnd,angle,length)
	glLineStipple(false)
	glColor(1,1,1,1)
end

local function DrawArc(angle,length)
	if arcLists[angle] then
		if arcLists[angle][length] then
			glCallList(arcLists[angle][length])
		else
			arcLists[angle][length]=glCreateList(Arc,angle,length)
		end
	else
		arcLists[angle]={}
		arcLists[angle][length]=glCreateList(Arc,angle,length)
	end
end

function gadget:Initialize()
	markerList=glCreateList(Marker)
	emptyList=glCreateList(Empty)
	turrets=SYNCED.turrets
end

function gadget:Shutdown()
	glDeleteList(markerList)
	glDeleteList(emptyList)
	for a,t in pairs(arcLists) do
		for l,i in pairs(t) do
			glDeleteList(i)
		end
	end
end

function gadget:RecvFromSynced(name,u)
	if name=="newImp" then
		Spring.UnitRendering.SetLODCount(u,1)
		Spring.UnitRendering.SetLODLength(u,1,1)
		Spring.UnitRendering.SetMaterial(u,1,"defaults3o",{shader="s3o"})
		Spring.UnitRendering.SetPieceList(u,1,3)
		Spring.UnitRendering.SetPieceList(u,1,2)
	elseif name=="newHP" then
		Spring.UnitRendering.SetLODCount(u,1)
		Spring.UnitRendering.SetLODLength(u,1,100)
		Spring.UnitRendering.SetMaterial(u,1,"defaults3o",{shader="s3o"})
		Spring.UnitRendering.SetPieceList(u,1,2)
	end
end


function gadget:DrawWorldPreUnit()
	local f = spGetGameFrame()
	local drawn={}
	local team=spGetLocalTeamID()
	local allyteam=spGetLocalAllyTeamID()
	local _,spec = spGetSpectatingState()
	glDepthTest(GL_LEQUAL)
	glDepthMask(true)
	glLineWidth(2)

	--draw the body of any Imperators that are partially visible

	for u,h in pairs(SYNCED.hardpoints) do
		--local x,y,z= spGetUnitPosition(u)
		local l=spGetUnitLosState(u,allyteam)
		if l.los or spec then
			glUnit(u)
			local imp = h[1]
			if not drawn[imp] then
				local px,py,pz=spGetUnitPosition(imp) --PiecePosDir(imp,2)
				local _,f=spGetPositionLosState(px,py,pz,allyteam)
				if f or spec then
					Spring.UnitRendering.SetPieceList(imp,1,3) --reset
				else
					Spring.UnitRendering.SetPieceList(imp,1,3,emptyList)
				end
				glUnit(imp)
				drawn[imp]=true
			end
		end
	end

	--draw the markers on selected hardpoints

	for _,u in ipairs(spGetSelectedUnits()) do
		local ud = spGetUnitDefID(u)
		if SYNCED.hardpoints[u] then
			glPushMatrix()
			glUnitMultMatrix(u)
			glCallList(markerList)
			glPopMatrix()
			glPushMatrix()
			local x,y,z=spGetUnitPosition(u)
			glTranslate(x,y,z)
			if SYNCED.hardpoints[u][5] then
				local h = SYNCED.hardpoints[u]
				local prog = (h[5]-f)/turrets[h[4]].buildtime/30
				glTranslate(0,20,0)
				glBillboard()
				glColor(.1,.1,.1,1)
				glRect(-42,-7,40,7)
				glColor(.7,.6,0,1)
				glRect(-40,-5,40-prog*80,5)
				glColor(1,1,1,1)
			end
			glPopMatrix()
		elseif turrets[ud] then
			glPushMatrix()
			glUnitMultMatrix(u)
			DrawArc(turrets[ud].arc,turrets[ud].range)
			glPopMatrix()
		end
	end

	glDepthTest(false)
	glDepthMask(false)
	glLineWidth(1)
end

end
