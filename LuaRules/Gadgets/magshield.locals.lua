--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spGetLocalAllyTeamID   = Spring.GetLocalAllyTeamID
local spGetPositionLosState  = Spring.GetPositionLosState
local spGetSpectatingState   = Spring.GetSpectatingState
local spGetTeamUnits         = Spring.GetTeamUnits
local spGetUnitHealth        = Spring.GetUnitHealth
local spGetUnitIsCloaked     = Spring.GetUnitIsCloaked
local spGetUnitIsDead        = Spring.GetUnitIsDead
local spGetUnitPosition      = Spring.GetUnitPosition
local spIsUnitVisible        = Spring.IsUnitVisible
local spSetUnitHealth        = Spring.SetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Mag Shield",
		desc = "the mag-shield effect and perk",
		author = "KDR_11k (David Becker)",
		date = "2008-03-08",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local plasma = {
	[WeaponDefNames.partillery.id]=true,
	[WeaponDefNames.partilleryq.id]=true,
	[WeaponDefNames.partilleryw.id]=true,
	[WeaponDefNames.plight.id]=true,
	[WeaponDefNames.pmedium.id]=true,
	[WeaponDefNames.pheavy.id]=true,
	[WeaponDefNames.pflak.id]=true,
	[WeaponDefNames.partilleryqf.id]=true,
	[WeaponDefNames.pdrone.id]=true,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local shielded = {}
local hasPerk = {}

local GetUnitHealth = spGetUnitHealth
local SetUnitHealth = spSetUnitHealth

function gadget:UnitCreated(u,ud,team)
	if UnitDefs[ud].customParams.magshield or GG.perks[team].have[8] then
		shielded[u] = true
	end
end

function gadget:UnitDestroyed(u, ud, team)
	shielded[u]=nil
end

local function MagShieldUser(team)
	hasPerk[team]=true
	for _,u in ipairs(spGetTeamUnits(team)) do
		if not spGetUnitIsDead(u) then
			shielded[u]=true
		end
	end
end

function gadget:Initialize()
	_G.shielded = shielded
	GG.MagShieldUser = MagShieldUser
end

function gadget:UnitDamaged(u, ud, team, damage, para, weapon)
	if plasma[weapon] and hasPerk[team] and not para then
		SetUnitHealth(u, { health = GetUnitHealth(u) + damage *.4 })
	end
end

--[[
function gadget:UnitPreDamaged(u, ud, team, damage, para, weapon)
	if plasma[weapon] and hasPerk[team] and not para then
		return damage*0.6
	end
end
--]]

else

--UNSYNCED
local shielded
local phase=0

local GL_BACK                = GL.BACK
local GL_LEQUAL              = GL.LEQUAL
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBlending             = gl.Blending
local glColor                = gl.Color
local glCulling              = gl.Culling
local glDepthTest            = gl.DepthTest
local glLighting             = gl.Lighting
local glPolygonOffset        = gl.PolygonOffset
local glUnit                 = gl.Unit
local Unit = glUnit
local IsUnitVisible = spIsUnitVisible
local GetUnitPosition = spGetUnitPosition
local GetPositionLosState=spGetPositionLosState
local GetUnitIsCloaked = spGetUnitIsCloaked

function gadget:Initialize()
	shielded=SYNCED.shielded
end

function gadget:DrawWorld()
	local c1=math.sin(phase)*.15 + .2
	local c2=math.sin(phase+ math.pi)*.15 + .2
	glColor(c1,c1,c2,1)
	phase = phase + .03
	local ateam = spGetLocalAllyTeamID()
	local _,specView = spGetSpectatingState()
	glBlending(GL_ONE, GL_ONE)
	glDepthTest(GL_LEQUAL)
	--glLighting(true)
	glPolygonOffset(-10, -10)
	glCulling(GL_BACK)
	for u,_ in pairs(shielded) do
		--if u ~= queenID then
			local x,y,z = GetUnitPosition(u)
			local _,los = GetPositionLosState(x,y,z,ateam)
			los =  specView or (los and not GetUnitIsCloaked(u))
			if IsUnitVisible(u, 1, true) and los then	--FIXME: no idea what the radius arg in IsUnitVisible does
				Unit(u, true)
			end
		--end
	end
	glColor(1,1,1,1)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	glLighting(false)
	glPolygonOffset(false)
	glCulling(false)
	glDepthTest(false)
end

end
