--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAddUnitDamage    = Spring.AddUnitDamage
local spGetGameFrame     = Spring.GetGameFrame
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetUnitsInSphere = Spring.GetUnitsInSphere
local spGetUnitDef	 = Spring.GetUnitDefID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Mass Drivers",
		desc = "Implements extra damage and bounce for kinetics with Mass Driver perk",
		author = "KDR_11k (David Becker)",
		date = "2008-03-06",
		license = "Public Domain",
		layer = 30,
		enabled = true
	}
end

local kinetic = {
	[WeaponDefNames.klight.id]=2,
	[WeaponDefNames.klights.id]=2,
	[WeaponDefNames.klightl.id]=2,
	[WeaponDefNames.kdual.id]=1,
	[WeaponDefNames.kdualg.id]=2,
	[WeaponDefNames.kdualh.id]=2,
	[WeaponDefNames.kmedium.id]=3,
	[WeaponDefNames.kheavyeden.id]=7,
	[WeaponDefNames.kheavy.id]=7,
}

local radius = 225

local tiny = { }

local massdriver = WeaponDefNames.smassdriver.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local perks

local bounceList = {}
local damageList = {}


function gadget:Initialize()
	perks = GG.perks
	_G.bounceList=bounceList

	for id,d in pairs(UnitDefs) do
		local c = d.customParams
		if c.type=="torpedo" or c.type=="drone" then
			tiny[id] = true
		end
	end
end



function gadget:UnitDamaged(u, ud, team, damage, para, weapon, au, aud, ateam)
	if ateam and kinetic[weapon] and perks[ateam].have[1] then
--		table.insert(damageList, {
--			target = u,
--			damage = damage / 2,
--			attacker = au,
--		})
		local left = kinetic[weapon]
		local x,y,z = spGetUnitPosition(u)
		local f = spGetGameFrame()
		
		for _,tu in ipairs(spGetUnitsInSphere(x,y,z,radius,team)) do
			local tud = spGetUnitDef(tu)
			if tu ~= u and not tiny[tud] then
				local tx,ty,tz = spGetUnitPosition(tu)
				table.insert(bounceList, {
					x=x,y=y,z=z,
					tx=tx, ty=ty, tz=tz,
					ttl=f+4;
				})
				table.insert(damageList, {
					target = tu,
					damage = damage,
					attacker = au,
				})
				left = left -1
				if left == 0 then
					break
				end
			end
		end
		while left > 0 do
			table.insert(bounceList, {
				x=x,y=y,z=z,
				tx=x+math.random(200)-100, ty=y+math.random(200)-100, tz=z+math.random(200)-100,
				ttl=f+4;
			})
			left = left -1
		end
	end
end

function gadget:GameFrame(f)
	for i,b in pairs(bounceList) do
		if b.ttl < f then
			bounceList[i]=nil
		end
	end
	for i,d in pairs(damageList) do
		spAddUnitDamage(d.target, d.damage, 0, d.attacker, massdriver)
		damageList[i]=nil
	end
end

else

--UNSYNCED

local GL_LEQUAL          = GL.LEQUAL
local GL_LINES           = GL.LINES
local glBeginEnd         = gl.BeginEnd
local glColor            = gl.Color
local glDepthTest        = gl.DepthTest
local glLineWidth        = gl.LineWidth
local glVertex           = gl.Vertex

local function DrawLine(x1,y1,z1,x2,y2,z2)
	glVertex(x1,y1,z1)
	glVertex(x2,y2,z2)
end

function gadget:DrawWorld()
	local f = spGetGameFrame()
	glLineWidth(3)
	glDepthTest(GL_LEQUAL)
	for _,b in pairs(SYNCED.bounceList) do
		glColor(1,.9,.2,.2 * (b.ttl - f))
		glBeginEnd(GL_LINES, DrawLine, b.x, b.y, b.z, b.tx, b.ty, b.tz)
	end
	glLineWidth(1)
	glDepthTest(false)
	glColor(1,1,1,1)
end

end
