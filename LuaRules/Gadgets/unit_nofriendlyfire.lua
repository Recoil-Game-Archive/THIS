-- $Id: unit_nofriendlyfire.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Friendly Fire",
    desc      = "Allows weapons to not damage allies",
    author    = "quantum",
    date      = "June 24, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -999,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitHealth  = Spring.GetUnitHealth
local spSetUnitHealth  = Spring.SetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local weaponNames = {meteoremp = true}
local weaponIDs = {}
-- weapons are defined per unit ("<unitname>_<weaponname>"), customParams.basename
-- holds the unprefixed name; shared weapondefs have no basename
for id, wd in pairs(WeaponDefs) do
	if weaponNames[wd.customParams.basename or wd.name] then weaponIDs[id] = true end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if (attackerDefID and 
      weaponIDs[weaponID] and
      --attackerID ~= unitID and
      spAreTeamsAllied(unitTeam, attackerTeam)) then
	return 0
  end
  return damage
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
