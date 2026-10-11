local weaponDefs = {
	SMassDriver = {
		name = "Mass Driver Splinters",
		RGBcolor = "1 .7 .2",
		weaponType = "LaserCannon",
		thickness = .5,
		intensity = 1,
		noselfdamage = true,
		duration = .02,

		soundstart = "klightfire",
		soundhit = "klighthit",

		turret = true,
		range = 800,
		weaponvelocity = 600,
		FallOffRate = .05,

		reloadtime = .25,
		accuracy = 500,

		areaofeffect = 8,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 3000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		--explosiongenerator=custom:corruption_shot1;

		interceptedbyshieldtype = 1, --kinetic
		damage = {
			default = 30,
		},
	},

	ShurikenWeapon = {
		name = "Antimatter Warhead",
		weaponType = "Melee",
		noselfdamage = true,
		model = "torpedo.s3o",
		--smoketrail=1;

		--soundstart=mlightfire;
		soundhit = "deathmed",
		burnblow = true,

		range = 50,
		targetBorder = true,

		edgeeffectiveness = 0.3,

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

		explosionSpeed = 4,

		explosiongenerator = "custom:death_large",
		--cegTag=trail_missile;

		interceptedbyshieldtype = 2, --missile
		damage = {
			default = 3500,
			torpedo = 15,
		},
	},
}

return lowerkeys(weaponDefs)
