--VFS.Include("gamedata/buildoptions.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility
--

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

local function disableunits(unitlist)
  for name, ud in pairs(UnitDefs) do
    if (ud.buildoptions) then
      for _, toremovename in ipairs(unitlist) do
        for index, unitname in pairs(ud.buildoptions) do
          if (unitname == toremovename) then
            table.remove(ud.buildoptions, index)
          end
        end
      end
    end
  end
end

--deep not safe with circular tables! defaults To false
function CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Convert all CustomParams to strings
--

for name, ud in pairs(UnitDefs) do
  if (ud.customparams) then
    for tag,v in pairs(ud.customparams) do
      if (type(v) == "table") then
	    local str = "{"
		for i=1,#v do
			str = str .. [["]] .. v[i] .. [[", ]]
		end
		str = str .. "}"
        ud.customparams[tag] = str
      elseif (type(v) ~= "string") then
        ud.customparams[tag] = tostring(v)
      end
    end
  end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Cost multipier

local costMult = Spring.GetModOptions().costmult or 1
if costMult ~= 1 then
	for name, ud in pairs(UnitDefs) do
		if ud.customparams then ud.customparams["cost"] = math.ceil(ud.customparams["cost"] * costMult) end
	end
end	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set reverse velocities, disables turninplace for small units, enables float
-- Also no smoothmesh

for name, ud in pairs(UnitDefs) do
    if (ud.maxvelocity) then ud.maxreversevelocity = ud.maxvelocity * 0.33 end
	if (ud.canfly) then
		ud.floater = false
		ud.cansubmerge = true
		ud.usesmoothmesh = false
		--ud.usepiececollisionvolumes = true
		--ud.airhoverfactor = -1
		--ud.cruisealt = ud.cruisealt + 125	-- fixes super annoying bug with ships refusing to touch water with their colvols
	end
	if (ud.customparams) then
		if (ud.customparams["type"] == "small" or ud.customparams["type"] == "gunstar") then ud.turninplace = false end
    end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Sets metal cost (for tooltip)
for name, ud in pairs(UnitDefs) do
	if ud.customparams then
		ud.buildcostmetal = ud.customparams.cost or 1
		ud.buildtime = tonumber(ud.customparams.buildtime) or 1
	end
end

-- All units stealthed, disable radar
for name, ud in pairs(UnitDefs) do
	--ud.radardistance = 0
	ud.stealth = true
end 

-- Per-piece colvols
for name, ud in pairs(UnitDefs) do
	--ud.usepiececollisionvolumes = true
end 
		

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- enable Quasar
if tobool(Spring.GetModOptions().enablequasar)then
    UnitDefs.quasar.customparams["nobuild"] = nil
	UnitDefs.shadowofeden.customparams["nobuild"] = nil
end