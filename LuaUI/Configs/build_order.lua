--this is used by synced code too, it's just placed here so LuaUI can access it as well

local orderSmall = {"dagger", "sword", "mace", "claymore", "wraith", "longbow", "warhammer", "dronelauncherm", "gunstar_cannon", "gunstar_torpedo", "probe"}
local orderLarge = {"carrier", "supportcarrier", "stealthcarrier", "starbase", "minelayer", "meteor", "comet", "starslayer", "quasar", "imperator",}

local order_small = {}
local order_large = {}

for index, name in pairs(orderSmall) do
	udef = (UnitDefNames[name])
	if udef then
		order_small[index] = udef.id
	end
end

for index, name in pairs(orderLarge) do
	order_large[name] = index
end


return order_small, order_large