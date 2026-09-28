--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spDestroyUnit          = Spring.DestroyUnit
local spGetGameFrame         = Spring.GetGameFrame
local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitCommands      = Spring.GetUnitCommands
local spGetUnitDirection     = Spring.GetUnitDirection
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitVelocity      = Spring.GetUnitVelocity
local spSetUnitNoSelect      = Spring.SetUnitNoSelect
local spValidUnitID          = Spring.ValidUnitID

local pairs					 = pairs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Torpedos",
		desc = "torpedo special stuff",
		author = "KDR_11k (David Becker)",
		date = "2008-08-10",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local torp={
	[UnitDefNames.torpedo.id]={launchspeed=12, friction=.98, acceleration=.4},
	[UnitDefNames.ftorpedo.id]={launchspeed=8, friction=.97, acceleration=.2},
}

local torpMoveList = {}
local newTorps={}

local sqrt = math.sqrt
local SetVelocity=Spring.MoveCtrl.SetVelocity
local SetRotation=Spring.MoveCtrl.SetRotation
local GetUnitPosition=spGetUnitPosition
local GetUnitVelocity=spGetUnitVelocity
local GetUnitDirection=spGetUnitDirection
local ValidUnitID=spValidUnitID
local GetUnitCommands=spGetUnitCommands
local SetUnitNoSelect=spSetUnitNoSelect
local MCEnable = Spring.MoveCtrl.Enable
local GetHeadingFromVector=spGetHeadingFromVector

function gadget:UnitCreated(u, ud, team)
	if torp[ud] then
		spSetUnitNoSelect(u, true)
		newTorps[u]=ud
	end
end

local function MoveTorps(f)
	for u,t in pairs(torpMoveList) do
		if t.activeFrame < f then
			if ValidUnitID(u) then
				local command=GetUnitCommands(u,1)[1]
				if command then
					local vx,vy,vz=GetUnitVelocity(u)
					local x,y,z=GetUnitPosition(u)
					local target,tx,ty,tz
					if command.params[2] then
						tx=command.params[1]
						ty=command.params[2]
						tz=command.params[3]
					else
						target = command.params[1]
						tx,ty,tz=GetUnitPosition(target)
					end
					if tx then
						local dirx = tx-x -vx*10
						local diry = ty-y -vy*10
						local dirz = tz-z -vz*10
						local dirlen=sqrt(dirx*dirx + diry*diry + dirz*dirz)
						local acceleration=torp[t.type].acceleration
						local friction=torp[t.type].friction
						vx = vx*friction + (dirx/dirlen)*acceleration
						vy = vy*friction + (diry/dirlen)*acceleration
						vz = vz*friction + (dirz/dirlen)*acceleration
						SetVelocity(u,vx,vy,vz)
						--SetRotation(u,0,GetHeadingFromVector(vx,vz)/32756*math.pi,0)
						Spring.MoveCtrl.SetHeading(u, GetHeadingFromVector(vx,vz))
						if sqrt((tx-x)*(tx-x) + (ty-y)*(ty-y) + (tz-z)*(tz-z)) < 40 then
							spDestroyUnit(u,true)
						end
					end
				end
			else
				torpMoveList[u]=nil
			end
		end
	end
end

function gadget:GameFrame(f)
	pcall(MoveTorps, f)
	for u,t in pairs(newTorps) do
		MCEnable(u)
		local dx,dy,dz=GetUnitDirection(u)
		SetVelocity(u, torp[t].launchspeed *dx, torp[t].launchspeed *dy, torp[t].launchspeed *dz)
		torpMoveList[u]={activeFrame = spGetGameFrame(), type = t}
	end
	newTorps={}
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt, tag, synced)
	if torp[ud] then
		return synced
	end
	return true
end

function gadget:UnitDestroyed(u, ud, team)
	torpMoveList[u]=nil
end

else

--UNSYNCED

return false

end
