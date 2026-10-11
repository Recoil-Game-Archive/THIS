--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Pull the weaponDefs out of the unitdefs
--
-- Weapons live in the weaponDefs table of the unit that mounts them. Each one
-- becomes the global weapondef "<unitname>_<weaponname>", and the unit's
-- weapons = { { def = "<weaponname>" } } entries are pointed at it.
-- The unprefixed name is kept in customParams.basename, so gadgets can
-- recognize every unit's copy of e.g. "klight".
--
-- Weapons that no unit mounts (death explosions, gadget-only weapons) are
-- still plain weapondefs in weapons/*.lua and keep their names.

local function ExtractWeaponDefs(udName, ud)
	local wds = ud.weapondefs
	if type(wds) ~= "table" then
		return
	end

	for wdName, wd in pairs(wds) do
		if type(wdName) == "string" and type(wd) == "table" then
			wd.customparams = wd.customparams or {}
			wd.customparams.basename = wdName
			WeaponDefs[udName .. "_" .. wdName] = wd
		end
	end

	local weapons = ud.weapons
	if type(weapons) == "table" then
		for i = 1, 32 do
			local w = weapons[i]
			if type(w) == "table" then
				if type(w.def) == "string" then
					local fullName = udName .. "_" .. string.lower(w.def)
					if WeaponDefs[fullName] then
						w.name = fullName
					end
				end
				w.def = nil
			end
		end
	end

	for _, tag in ipairs({ "explodeas", "selfdestructas" }) do
		if type(ud[tag]) == "string" then
			local fullName = udName .. "_" .. string.lower(ud[tag])
			if WeaponDefs[fullName] then
				ud[tag] = fullName
			end
		end
	end
end

for udName, ud in pairs(DEFS.unitDefs) do
	if type(udName) == "string" and type(ud) == "table" then
		ExtractWeaponDefs(udName, ud)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Impact sound classes (LuaRules/Gadgets/unit_impact_sounds.lua)
--
-- customParams.impact_sounds names a folder in sounds/impacts/. A weapondef
-- that sets it keeps what it says; everything else gets a class from the
-- effect it explodes with. Beam lasers are skipped, they damage their target
-- every frame. Weapons that end up without a class use "generic".

local impactSoundsByEffect = {
	["custom:kinetic"]     = "kinetic",
	["custom:plasma"]      = "plasma",
	["custom:smallplasma"] = "plasma",
	["custom:partillery"]  = "artillery",
	["custom:missile"]     = "missile",
	["custom:torpedo"]     = "torpedo",
	["custom:antimatter"]  = "antimatter",
}

for _, weaponDef in pairs(WeaponDefs) do
	local weaponType = string.lower(tostring(weaponDef.weapontype))
	local effect = weaponDef.explosiongenerator
	if weaponType ~= "beamlaser" and type(effect) == "string" then
		local class = impactSoundsByEffect[string.lower(effect)]
		if class then
			weaponDef.customparams = weaponDef.customparams or {}
			if not weaponDef.customparams.impact_sounds then
				weaponDef.customparams.impact_sounds = class
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Convert all CustomParams to strings

for _, weaponDef in pairs(WeaponDefs) do
	if weaponDef.customparams then
		for tag, v in pairs(weaponDef.customparams) do
			if type(v) ~= "string" then
				weaponDef.customparams[tag] = tostring(v)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- all weapons can shoot through "water"
for _, weaponDef in pairs(WeaponDefs) do
    weaponDef.waterweapon = true
    weaponDef.firesubmersed = true
    weaponDef.canattackground = false
end
