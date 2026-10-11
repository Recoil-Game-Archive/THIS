local weaponDefs = {
	RetroDeathSmall = {
		name = "Small Unit Explosion",
		weaponType = "Melee",

		burnblow = true,

		reloadtime = 2,
		areaofeffect = 120,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 53000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		explosionSpeed = 60,

		--explosiongenerator=custom:death_huge;

		interceptedbyshieldtype = 2, --missile
		customParams = {
			impact_sounds = "none", -- the death sound covers it
		},
		damage = {
			default = 100,
		},
	},

	RetroDeathBig = {
		name = "Big Unit Explosion",
		weaponType = "Melee",

		burnblow = true,

		reloadtime = 2,
		areaofeffect = 250,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 53000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		explosionSpeed = 60,

		--explosiongenerator=custom:death_huge;

		interceptedbyshieldtype = 2, --missile
		customParams = {
			impact_sounds = "none", -- the death sound covers it
		},
		damage = {
			default = 2500,
		},
	},

	RetroDeathHuge = {
		name = "Big Unit Explosion",
		weaponType = "Melee",

		burnblow = true,

		reloadtime = 2,
		areaofeffect = 375,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 53000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		explosionSpeed = 60,

		--explosiongenerator=custom:death_huge;

		interceptedbyshieldtype = 2, --missile
		customParams = {
			impact_sounds = "none", -- the death sound covers it
		},
		damage = {
			default = 10000,
		},
	},

	ImperatorDeath = {
		name = "Imperator Explosion",
		weaponType = "Melee",

		--soundstart=mlightfire;
		burnblow = true,

		targetBorder = true,
		reloadtime = 2,
		areaofeffect = 600,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 53000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		explosionSpeed = 60,

		explosiongenerator = "custom:death_huge",
		--cegTag=trail_missile;

		interceptedbyshieldtype = 2, --missile
		customParams = {
			impact_sounds = "none", -- the death sound covers it
		},
		damage = {
			default = 50000,
		},
	},
}

return lowerkeys(weaponDefs)
