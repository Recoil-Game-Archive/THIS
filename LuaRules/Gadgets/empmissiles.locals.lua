--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAddUnitDamage    = Spring.AddUnitDamage
local spGetUnitAllyTeam  = Spring.GetUnitAllyTeam
local spGetUnitTeam      = Spring.GetUnitTeam
local spGetUnitsInSphere = Spring.GetUnitsInSphere

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "EMP missiles",
		desc = "the EMP Missiles perk",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end

local missile = {
	[WeaponDefNames.mlight6.id] = 80,
	[WeaponDefNames.mlight12.id] = 80,
	[WeaponDefNames.mmedium12.id] = 80,
	[WeaponDefNames.mtiny.id] = 50,
	[WeaponDefNames.mquasar.id] = 95,
}

local empMult = 2

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local GetUnitTeam= spGetUnitTeam
local GetUnitsInSphere = spGetUnitsInSphere
local AddUnitDamage = spAddUnitDamage
local GetUnitAllyTeam = spGetUnitAllyTeam

local hasEMP = {}
local empList = {}

--[[
function gadget:Explosion(weapon, x,y,z, u)
	if u and missile[weapon] and hasEMP[GetUnitTeam(u)] then
		table.insert(empList, {
			x=x, y=y, z=z,
			radius = missile[weapon],
			damage = (WeaponDefs[weapon].damages[1] * empMult),
			weapon = weapon,
			attacker=u,
		})
	end
	return false
end

function gadget:GameFrame(f)
	for i,e in pairs(empList) do
		local allyteam=GetUnitAllyTeam(e.attacker)
		for _,u in ipairs(GetUnitsInSphere(e.x, e.y, e.z, e.radius)) do
			if allyteam ~= GetUnitAllyTeam(u) then
				AddUnitDamage(u, e.damage, 15, e.attacker, e.weapon)
			end
		end
		empList[i]=nil
	end
end
]]--

local function GetEMP(team)
	hasEMP[team] = true
end

function gadget:Initialize()
	for w,_ in pairs(missile) do
		Script.SetWatchWeapon(w, true)
	end
	GG.GetEMP = GetEMP
end

else

--UNSYNCED

return false

end
