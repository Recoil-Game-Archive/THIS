local weaponDefs = {
	tQuasarShort = {
		name = "Torpedo Launch Control",
		weaponType = "Melee",

		turret = true,
		range = 900,
		reloadtime = 8,
		projectiles = 0,

		areaofeffect = 8,

		tolerance = 3000,
		canattackground = false,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		--explosiongenerator=custom:corruption_shot1;

		interceptedbyshieldtype = 0, --imaginary
		damage = {
			default = .0001,
		},
		customParams = {
			torpedotype = 2, -- TORPEDO
		},
	},

	TorpedoBlast = {
		name = "Torpedo Warhead",
		weaponType = "Melee",
		noselfdamage = true,
		model = "torpedo.s3o",
		--smoketrail=1;

		--soundstart=mlightfire;
		soundhit = "weapons\\mlighthit",
		burnblow = true,

		turret = false,
		range = 50,
		weaponvelocity = 100,
		startvelocity = 100,
		weaponacceleration = 100,
		flighttime = 2,
		targetBorder = true,

		reloadtime = 2,
		tracks = true,
		turnrate = 220000,

		--fixedLauncher=1;

		areaofeffect = 70,
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

		explosiongenerator = "custom:torpedo",
		--cegTag=trail_missile;

		interceptedbyshieldtype = 2, --missile
		damage = {
			default = 800,
			torpedo = 2,
		},
	},
}

return lowerkeys(weaponDefs)
