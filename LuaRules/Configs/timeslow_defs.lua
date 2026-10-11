local array = {}

------------------------
-- Config

local MAX_SLOW_FACTOR = 0.99
-- Max slow damage on a unit = MAX_SLOW_FACTOR * current health
-- Slowdown of unit = slow damage / current health
-- So MAX_SLOW_FACTOR is the limit for how much units can be slowed

local DEGRADE_TIMER = 0.5
-- Time in seconds before the slow damage a unit takes starts to decay

local DEGRADE_FACTOR = 0.04
-- Units will lose DEGRADE_FACTOR*(current health) slow damage per second

local UPDATE_PERIOD = 15 -- I'd prefer if this was not changed


local weapons = {
	mlight6 = {slowDamage = 100, scaleSlow = true},
	mlight12 = {slowDamage = 100, scaleSlow = true},
	mmedium6eden = {slowDamage = 160, scaleSlow = true},
	mmedium12 = {slowDamage = 160, scaleSlow = true},
	mtiny = {slowDamage = 50, scaleSlow = true},
	mquasar = {slowDamage = 100, scaleSlow = true},
	
	meteoremp = {slowDamage = 2000, scaleSlow = true, noPerk = true, onlySlow = true}
}

local presets = {
}

------------------------
-- Send the Config

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

for name,data in pairs(WeaponDefNames) do
	if data.customParams.timeslow_preset then
		weapons[name] = CopyTable(presets[data.customParams.timeslow_preset])
	end
	if weapons[name] then array[data.id] = weapons[name] end
end

return array, MAX_SLOW_FACTOR, DEGRADE_TIMER*30/UPDATE_PERIOD, DEGRADE_FACTOR*UPDATE_PERIOD/30, UPDATE_PERIOD