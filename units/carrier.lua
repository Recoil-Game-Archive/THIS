local unitName = "carrier"
local unitDef = {
	Name = "Fleet Carrier",
	Description = "Field production and maintenance ship",

	-- Required Tags
	power = 1500,
	mass = 10000,
	icontype = "carrier",
	category = "LARGE CARRIER WEAK TARGET COMMANDER ANY",
	footprintX = 6,
	footprintZ = 6,
	maxDamage = 25000,
	idleTime = 0,
	idleAutoHeal = 0,
	objectName = "carrier.s3o",
	collisionVolumeType = "Box",
	collisionVolumeScales = "92 40 180",
	collisionVolumeTest = true,
	collide = 0,
	script = "ship.lua",

	-- Movement
	canFly = true,
	hoverAttack = true,
	airHoverFactor = 0,
	airStrafe = false,
	cruiseAlt = 80,
	brakeRate = .5,
	acceleration = .01,
	canMove = true,
	maxVelocity = 1,
	turnRate = 220,

	-- Construction
	LevelGround = false,

	-- Sight/Radar
	RadarDistance = 1350,
	SightDistance = 900,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 1",
			MaxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
	
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 -1",
			maxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 1",
			maxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
	
		{
			def = "GStandard",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "GFlak",
			badTargetCategory = "LARGE",
		},
		{
			def = "tstandard",
			onlyTargetCategory = "LARGE",
			--badTargetCategory = "SMALL",
		},
	},

	weaponDefs = {
		KLight = {
			name = "Light Kinetic Weapon",
			RGBcolor = ".85 .7 .2",
			weaponType = "LaserCannon",
			thickness = .5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "klightfire",
			soundhit = "klighthit",

			turret = true,
			range = 500,
			weaponvelocity = 600,
			FallOffRate = .05,

			reloadtime = .25,
			sprayangle = 600,

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

			explosiongenerator = "custom:kinetic",

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 15,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 16,
			},
		},

		GStandard = {
			name = "Gravitrics",
			RGBcolor = "0 0 0",
			weaponType = "BeamLaser",
			thickness = 8,
			intensity = 1,
			noselfdamage = true,
			burstrate = .06,
			burst = 10,
			beamttl = 2,
			beamburst = true,

			soundstart = "grav",
			soundhit = "",

			turret = true,
			range = 350,

			reloadtime = 3,

			areaofeffect = 50,
			collidefriendly = false,
			avoidfriendly = true,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 9000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:grav",
			explosionSpeed = 600,

			interceptedbyshieldtype = 8, --gravitric
			damage = {
				default = 600,
			},
		},

		GFlak = {
			name = "Grav Flak",
			RGBcolor = "1 1 1",
			weaponType = "BeamLaser", --Cannon;
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			beamburst = true,
			minintensity = 1,
			thickness = 1,

			soundhit = "grav",

			turret = true,
			range = 450,
			weaponvelocity = 900,

			reloadtime = 1.30,
			burst = 4,
			burstrate = .06,

			areaofeffect = 150,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:grav",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 8, --plasma
			damage = {
				default = 40,
			},
		},

		tstandard = {
			name = "Torpedo Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 900,
			reloadtime = 8,
			projectiles = 0,

			areaofeffect = 8,

			tolerance = 3000,

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
	},
	
	explodeAs = "RetroDeathBig",
	selfDestructAs = "RetroDeathBig",
	
	-- Misc
	smoothAnim = false,
	selfDestructCountdown = 6,
	
	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
		},
	},
	
	customParams = {
		builds = 1.0,
		type = "large",
		cost = 3000,
		buildtime = 40,
		occupationStrength = 2,
		headingaim1 = 160,
		pitchaim1 = 120,
		firestealthtime = 3000,
		moreguns = 3,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
