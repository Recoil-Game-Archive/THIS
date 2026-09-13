-- TODO: priorities
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMDTYPE_ICON          = CMDTYPE.ICON
local CMDTYPE_ICON_MODE     = CMDTYPE.ICON_MODE
local CMDTYPE_ICON_MAP      = CMDTYPE.ICON_MAP
local CMD_MOVE              = CMD.MOVE
local spAreTeamsAllied      = Spring.AreTeamsAllied
local spCreateUnit          = Spring.CreateUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetGameFrame        = Spring.GetGameFrame
local spGetLocalTeamID      = Spring.GetLocalTeamID
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetTeamList         = Spring.GetTeamList
local spGetTeamUnitDefCount = Spring.GetTeamUnitDefCount
local spGetTeamUnitsByDefs  = Spring.GetTeamUnitsByDefs
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitDirection    = Spring.GetUnitDirection
local spGetUnitHeading      = Spring.GetUnitHeading
local spGetUnitPieceMap     = Spring.GetUnitPieceMap
local spGetUnitPiecePosDir  = Spring.GetUnitPiecePosDir
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc	= Spring.RemoveUnitCmdDesc
local spSetUnitCOBValue     = Spring.SetUnitCOBValue
local spSetUnitRotation     = Spring.SetUnitRotation

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "build",
		desc = "build system",
		author = "KDR_11k (David Becker)",
		date = "2008-03-03",
		license = "Public Domain",
		layer = 5,
		enabled = true
	}
end

local CMD_BUILD = 31000
local CMD_PLACE = 32333
local CMD_REPEAT_BUILD=32666
local CMD_RALLY=32667
local CMD_STOP_RALLY=32668
local jumpDist = 600

local BUILD_PERIOD = 6	-- gameframes

local perks

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local large = {}
local small = {}
local gunstar = {}
local builder = {}
local minelayer = {}
local allyTeam={}

local money

local buildstate = {}
local globalbuild = {}
local ready = {}
local move = {}
local spawnList = {}

local order_small, order_large = include("LuaUI/Configs/build_order.lua")

local function MakeSmallAvailable(team, ud)
	for b,_ in pairs(builder) do
		for _,u in ipairs(spGetTeamUnitsByDefs(team,b)) do
			local f = spFindUnitCmdDesc(u, CMD_BUILD + ud)
			if f then
				spEditUnitCmdDesc(u, f, {disabled = false})
			end
		end
	end
end

function gadget:Initialize()
	perks = GG.perks
	for id,d in pairs(UnitDefs) do
		local c = d.customParams
		if c.type=="large" and (not c.nobuild) then
			large[id] = {
				cost = tonumber(c.cost),
				buildtime = tonumber(c.buildtime),
				perk = tonumber(c.needperk),
				limit = tonumber(c.limit),
			}
		elseif (c.type=="small" or c.type=="gunstar" or c.type=="probe") and not c.nobuild then
			small[id] = {
				cost = tonumber(c.cost),
				buildtime = tonumber(c.buildtime),
				perk = tonumber(c.needperk),
				limit = tonumber(c.limit),
			}
			if c.type=="gunstar" then gunstar[id] = true end
		end
		if c.builds then
			builder[id] = tonumber(c.builds)
		end
		if c.minelayer then
			minelayer[id] = tonumber(c.minelayer)
		end
	end
	for _,t in ipairs(spGetTeamList()) do
		globalbuild[t] = {
			last = false,
			first = false,
			spent = 0,
			progress = 0
		}
		_,_,_,_,_,allyTeam[t] = spGetTeamInfo(t)
	end
	
	money = GG.money
	_G.buildstate = buildstate
	_G.globalbuild = globalbuild
	GG.globalbuild=globalbuild
	_G.ready = ready
	GG.ready = ready
	GG.MakeSmallAvailable = MakeSmallAvailable
	
	-- luarules reload compatibility
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local ud = Spring.GetUnitDefID(units[i])
		local team = Spring.GetUnitTeam(units[i])
		gadget:UnitCreated(units[i], ud, team)
	end
end

function gadget:UnitCreated(u, ud, team)
	if builder[ud] or minelayer[ud] then
		for index, buildeeDefID in pairs(order_small) do
			local udef = UnitDefs[buildeeDefID]
			local i = buildeeDefID	--index of array "small"
			local d = small[buildeeDefID]	--data
			local block = false
			if d.perk and not perks[team].have[d.perk] then
				block = true
			end
			local unitType = udef.customParams["type"]
			if (not gunstar[i] and not minelayer[ud]) or (gunstar[i] and minelayer[ud]) or (unitType == "probe") then
				spInsertUnitCmdDesc(u, {
					name="Build "..udef.humanName,
					tooltip = "Build "..udef.humanName.."\n"..
						udef.tooltip.."\n"..
						"Cost: "..d.cost.."\n"..
						"Build time: "..d.buildtime*(builder[ud] or minelayer[ud]).." seconds",
					action = "build_"..udef.name,
					type=CMDTYPE_ICON,
					id=CMD_BUILD + i,
					onlyTexture=true,
					texture = "&.1x.1&#"..i.."&bitmaps/frame.tga",
					disabled = block,
				})
			end
		end
		spInsertUnitCmdDesc(u, {
			name="Repeat Queue",
			tooltip="Toggle whether the build queue should be repeated infinitely",
			action="repeat_build",
			type=CMDTYPE_ICON_MODE,
			id=CMD_REPEAT_BUILD,
			params={"0", "Build Once", "Repeat Queue"}
		})
		spInsertUnitCmdDesc(u, {
			name="Rally Point",
			tooltip="Set a rally point for units from this carrier to move to",
			action="rally",
			type=CMDTYPE_ICON_MAP,
			id=CMD_RALLY,
		})
		spInsertUnitCmdDesc(u, {
			name="Stop Rally",
			tooltip="Remove the rally point",
			action="stoprally",
			type=CMDTYPE_ICON,
			id=CMD_STOP_RALLY,
		})
		local b = spGetUnitPieceMap(u)
		buildstate[u] = {
			last = false,	-- unitDefID
			first = false,	-- unitDefID
			Repeat = false,	-- bool
			rally = nil,	-- { {x1, y1}, {x2, y2}, ... }
			bay = { b.bay0, b.bay1 },	-- piecenums the buildee emerges from
			progress = 0,	-- 0 to 1
			spent = 0,	-- cost
			flightTime = tonumber(UnitDefs[ud].customParams.childflighttime)
		}
	end
end

function gadget:UnitDestroyed(u, ud, team)
	buildstate[u]=nil
	move[u]=nil
end

-- first = first in waiting list
-- last = last added?
local function pushBuild(list, entry, alt)
	local current = list.last
	local b = {
		build = entry,
		next = false,
		alt = list.Repeat and alt,
	}
	if alt then
		b.next = list.first
		list.first = b
	else
		if current then
			current.next = b
		end
		list.last = b
		if not list.first then
			list.first = b
		end
	end
	--[[
	for i,v in pairs(list) do
		if type(v) == "table" then
			Spring.Echo(i,v.build)
		else
			Spring.Echo(i,v)
		end
	end
	]]--
end

local function popBuild(list)
	if list.first then
		--if list.last and list.Repeat then
		--	list.last.next = list.first
		--	list.last = list.first
		--end
		list.first = list.first.next
		--if list.last and list.Repeat then
		--	list.last.next=false
		--end
	end
end

local function removeBuild(list,u,n)
	if not n then
		n = 1
	end
	local previous = false
	local current = list.first
	while n > 0 and current do
		if current.build == u then
			if previous then
				previous.next = current.next
			else
				list.first = current.next
			end
			if current == list.last then
				list.last = previous
			end
			n=n-1
		else
			previous = current
		end
		current = current.next
	end
	return n == 0
end

function gadget:AllowCommand(u, ud, team, cmd, param, opts)
	if small[cmd - CMD_BUILD] then
		if buildstate[u] then
			local count = 1
			if opts.shift then
				count = 5
			end
			local b = buildstate[u]
			local p = small[cmd - CMD_BUILD].perk
			if not p or perks[team].have[p] then
				if not opts.right then
					for n = 1,count do
						pushBuild(b,cmd-CMD_BUILD, opts.alt)
					end
					return false
				else
					if not removeBuild(b,cmd - CMD_BUILD, count) and b.current == cmd - CMD_BUILD then
						b.current = nil
						money[team] = money[team] + b.spent
						b.progress = 0
						b.spent = 0
					end
					return false
				end
			else
				return false
			end
		else
			return false
		end
	elseif large[cmd - CMD_BUILD] then
		local b = globalbuild[team]
		local p = large[cmd - CMD_BUILD].perk
		if not p or perks[team].have[p] then
			if not opts.right then
				pushBuild(b,cmd - CMD_BUILD, opts.alt)
				return false
			else
				if not removeBuild(b,cmd-CMD_BUILD,count) and b.current == cmd - CMD_BUILD then
					b.current = nil
					money[team] = money[team] + b.spent
					b.progress = 0
					b.spent = 0
				end
				return false
			end
		end
	elseif cmd == CMD_PLACE then
		--Spawn large ship

		if param[2] and ready[team] then
			local canDo = false
			for _,u in ipairs(spGetUnitsInCylinder(param[1], param[3], jumpDist)) do
				if buildstate[u] and spAreTeamsAllied(spGetUnitTeam(u), team) then
					canDo=true
					break
				end
			end

			if not canDo then
				for _,p in pairs(GG.planets) do
					if allyTeam[p.lastOwner] == allyTeam[team] then
						local dist = math.sqrt((param[1] - p.x)*(param[1] - p.x) + (param[3] - p.z)*(param[3] - p.z))
						if dist < GG.occupationRange then
							canDo = true
							break
						end
					end
				end
			end

			if canDo then
				table.insert(spawnList, {
					type = ready[team],
					x=param[1],
					y=80,
					z=param[3],
					team = team,
				})
			else
				GG.message[team].text="Invalid jump location"
				GG.message[team].hint="Select a location closer to a friendly carrier or planet."
				GG.message[team].timeout = spGetGameFrame() + 100
			end
		end
		return false
	elseif cmd==CMD_REPEAT_BUILD then
		if buildstate[u] then
			buildstate[u].Repeat=param[1]==1
			f = spFindUnitCmdDesc(u, CMD_REPEAT_BUILD)
			if f then
				spEditUnitCmdDesc(u, f, {params = {param[1], "Build Once", "Repeat Queue"} })
			end
		end
		return false
	elseif cmd==CMD_RALLY then
		if buildstate[u] and param[3] then
			if opts.shift then
				local queue = buildstate[u].rally or {}
				queue[#queue + 1] = {param[1],param[3]}
				buildstate[u].rally = queue
			else
				buildstate[u].rally={ {param[1],param[3]} }
			end
		end
		return false
	elseif cmd==CMD_STOP_RALLY then
		if buildstate[u] then
			buildstate[u].rally=nil
		end
		return false
	end
	return true
end

--function gadget:CommandFallback(u, ud, team, cmd, param, opt)
--end

function gadget:GameFrame(f)
	for i,d in pairs(spawnList) do
		nu = spCreateUnit(UnitDefs[d.type].name, d.x, d.y, d.z, 0, d.team)
		Spring.MoveCtrl.Enable(nu)
		Spring.MoveCtrl.SetPosition(nu,d.x,40,d.z)
		spSetUnitRotation(nu,0,math.random(31415)/5000,0)
		Spring.MoveCtrl.SetRelativeVelocity(nu,0,0,2)
		move[nu] = {fr=f + 30}
		spawnList[i]=nil
		ready[d.team]=nil
		globalbuild[d.team].progress = 0
		globalbuild[d.team].spent = 0
	end

	if (f - 6) % BUILD_PERIOD == 0 then
		for u,d in pairs(buildstate) do
			local team = spGetUnitTeam(u)
			if d.current then
				if d.progress >= 1 then
					local bayNum = math.random(1,2)
					local px,py,pz,pdx,pdy,pdz = spGetUnitPiecePosDir(u, d.bay[bayNum])
					local x,y,z = spGetUnitPosition(u)
					--local h = spGetUnitHeading(u)
					local h = spGetHeadingFromVector(pdx,pdz)
					nu = spCreateUnit(UnitDefs[d.current].name,x,y,z,0,spGetUnitTeam(u))
					Spring.MoveCtrl.Enable(nu)
					Spring.MoveCtrl.SetPosition(nu,px,py,pz)
					spSetUnitCOBValue(nu,82,h)
					Spring.MoveCtrl.SetRelativeVelocity(nu,0,0,6)
					local flightTime = d.flightTime or 20
					move[nu] = {fr=f + flightTime,rally=d.rally}
					-- move to back of line if on repeat (but not with alt)
					if d.Repeat and not d.alt then
						pushBuild(d, d.current)
					end
					d.current = nil
					d.progress = 0
					d.spent = 0
				else
					local moneyRequired = small[d.current].cost * BUILD_PERIOD/d.time
					if money[team] >= moneyRequired then
						money[team] = money[team] - moneyRequired
						d.progress = d.progress + moneyRequired/small[d.current].cost
						d.spent = d.spent + moneyRequired
					end
				end
			else
				if d.first then
					--if money[team] >= small[d.first.build].cost then
						local t = d.first.build
						d.current = t
						d.time = small[t].buildtime * 30 * (builder[spGetUnitDefID(u)] or minelayer[spGetUnitDefID(u)])
						if perks[team].have[4] then --advanced automation
							d.time = d.time *.5
						end
						d.alt = d.first.alt
						popBuild(d)
					--elseif GG.message[team].timeout <= f then
					--	GG.message[team].text = "Insufficient funds to continue construction"
					--	GG.message[team].hint = "Capture more planets to increase your income"
					--	GG.message[team].timeout = f + 63
					--end
				end
			end
		end
		for team,d in pairs(globalbuild) do
			if d.current then
				if d.progress >= 1 then
					ready[team] = d.current
					d.current = nil
				else
					local moneyRequired = large[d.current].cost * BUILD_PERIOD/d.time
					if money[team] >= moneyRequired then
						money[team] = money[team] - moneyRequired
						d.progress = d.progress + moneyRequired/large[d.current].cost
						d.spent = d.spent + moneyRequired
					end
				end
			elseif not ready[team] then
				if d.first then
					--if money[team] >= large[d.first.build].cost then
						local t = d.first.build
						if not large[t].limit or spGetTeamUnitDefCount(team,t) < large[t].limit then
							d.current = t
							d.time = large[t].buildtime * 30
							if perks[team].have[4] then  --advanced automation
								d.time = d.time *.85
							end
							--money[team] = money[team] - large[t].cost
						else
							GG.message[team].text = "Unit limit reached"
							GG.message[team].hint = "You can only have "..large[t].limit.." "..UnitDefs[t].humanName.."(s)."
							GG.message[team].timeout = f + 120
						end
						popBuild(d)
					--elseif GG.message[team].timeout <= f then
					--	GG.message[team].text = "Insufficient funds to continue construction"
					--	GG.message[team].hint = "Capture more planets to increase your income"
					--	GG.message[team].timeout = f + 63
					--end
				end
			end
		end
	end
	for u,d in pairs(move) do
		local fr = d.fr
		local rally=d.rally
		if fr <= f then
			Spring.MoveCtrl.Disable(u)
			if small[spGetUnitDefID(u)] then
				local x,y,z
				if rally then
					for i=1,#rally do
						x=rally[i][1]
						y=0
						z=rally[i][2]
						spGiveOrderToUnit(u, CMD_MOVE, {x + math.random(100), y, z + math.random(100)}, {"shift"})
					end
				else
					x,y,z = spGetUnitPosition(u)
					local dx, dy, dz = spGetUnitDirection(u)
					x=x - 50 + 120 * dx
					z=z - 50 + 120 * dz
					spGiveOrderToUnit(u, CMD_MOVE, {x + math.random(100) , y, z + math.random(100)}, {})
				end
			else
				local x,y,z = spGetUnitPosition(u)
				local dx, dy, dz = spGetUnitDirection(u)
				spGiveOrderToUnit(u, CMD_MOVE, {x + 60 * dx, y, z + 60*dz }, {})
			end
			move[u]=nil
		else
		end
	end
end

else

--UNSYNCED
local glColor               = gl.Color
local glRect                = gl.Rect
local glTexRect             = gl.TexRect
local glTexture             = gl.Texture
local GL_TRIANGLE_STRIP      = GL.TRIANGLE_STRIP
local GL_LINES             = GL.LINES
local GL_LEQUAL				 = GL.LEQUAL
local glLineStipple        = gl.LineStipple
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glLineWidth            = gl.LineWidth
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glTexCoord             = gl.TexCoord
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local glDepthTest=gl.DepthTest

local buildstate

local myTeam = Spring.GetMyTeamID()

local cbpWidth=80
local cbpHeight=60
local cbpLeft = 280
local gbpBottom = 100

local qbpWidth=40
local qbpHeight=30
local qbpTop=160
local qbpLeft=330

local qbpRowHeight=70

function gadget:DrawScreen(vsx,vsy)
	local vpos = 1
	local team = spGetLocalTeamID()
	for _,u in ipairs(spGetSelectedUnits()) do
		local b = buildstate[u]
		if b then
			local vert = vsy - qbpTop - qbpRowHeight * vpos
			if b.current and b.progress < 1 then
				glTexture("#"..b.current)
				glTexRect(cbpLeft, vert, cbpLeft + cbpWidth, vert - cbpHeight,false,true)
				glTexture(false)
				glColor(1,1,1,.3)
				glRect(cbpLeft, vert, cbpLeft + (cbpWidth * b.progress), vert - cbpHeight)
				glColor(1,1,1,1)
			end
			local hpos = 1
			local current = b.first
			while current do
				local t = current.build
				glTexture("#"..t)
				glTexRect(qbpLeft + hpos * qbpWidth, vert, qbpLeft + qbpWidth + hpos * qbpWidth, vert - qbpHeight,false,true)
				hpos = hpos + 1
				current = current.next
			end
			vpos = vpos + 1
		end
	end

	local b = globalbuild[team]
	local vert = gbpBottom + cbpHeight
	if b.current then
		glTexture("#"..b.current)
		glTexRect(cbpLeft, vert, cbpLeft + cbpWidth, vert - cbpHeight,false,true)
		glTexture(false)
		if b.progress < 1 then
			glColor(1,1,1,.3)
			glRect(cbpLeft, vert, cbpLeft + (cbpWidth * b.progress), vert - cbpHeight)
			glColor(1,1,1,1)
		end
	end
	local hpos = 1
	local current = b.first
	while current do
		local t = current.build
		glTexture("#"..t)
		glTexRect(qbpLeft + hpos * qbpWidth, vert, qbpLeft + qbpWidth + hpos * qbpWidth, vert - qbpHeight,false,true)
		hpos = hpos + 1
		current = current.next
	end

	glTexture(false)
end

local size=40

local squareList

local function Square()
	glTexCoord(0,0)
	glVertex(-size,0,-size)
	glTexCoord(1,0)
	glVertex(size,0,-size)
	glTexCoord(0,1)
	glVertex(-size,0,size)
	glTexCoord(1,1)
	glVertex(size,0,size)
end

local function Line(sx,sy,sz,tx,ty,tz)
	glVertex(sx,sy,sz)
	glVertex(tx,ty,tz)
end


function gadget:DrawWorld()
	glTexture("bitmaps/rally.tga")
	glDepthTest(GL_LEQUAL)
	glLineStipple("foobar")
	glColor(1,1,.5,1)
	for _,u in ipairs(spGetSelectedUnits()) do
		local b = SYNCED.buildstate[u]
		if b and b.rally then
			local x,y,z = spGetUnitPosition(u)
			for i in ipairs(b.rally) do
				if b.rally and b.rally[i-1] then
					x,z = b.rally[i-1][1], b.rally[i-1][2]
				end
				--Spring.Echo(i, x, y, z)
				glPushMatrix()
				glTranslate(b.rally[i][1],y,b.rally[i][2])
				glCallList(squareList)
				glPopMatrix()
				glTexture(false)
				glBeginEnd(GL_LINES,Line,x,y,z,b.rally[i][1],y,b.rally[i][2])
				gl.Texture(true)
			end
		end
	end
	glTexture(false)
	glDepthTest(false)
	glLineStipple(false)
	glColor(1,1,.5,1)
end

function gadget:Initialize()
	buildstate = SYNCED.buildstate
	globalbuild = SYNCED.globalbuild
	perks = SYNCED.perks
	squareList=glCreateList(glBeginEnd,GL_TRIANGLE_STRIP,Square)
end

function gadget:Shutdown()
	glDeleteList(squareList)
end

function gadget:Update()
	local team = spGetLocalTeamID()
	if Script.LuaUI("ReadyIs") then
		Script.LuaUI.ReadyIs(SYNCED.ready[team])
	end
end


end
