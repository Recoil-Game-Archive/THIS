local unitName = "eclipse"
local unitDef = {
	Name = "Eclipse",
	Description = "Advanced command-and-control cruiser",

	-- Required Tags
	power = 3000,
	mass = 20000,
	icontype = "carrier",
	category = "LARGE CARRIER Strong TARGET COMMANDER ANY",
	footprintX = 8,
	footprintZ = 8,
	maxDamage = 36000,
	autoheal = 10,
	idleTime = 0,
	idleAutoHeal = 0,
	objectName = "eclipse.s3o",
	soundCategory = "CARRIER",
	collisionVolumeType = "Box",
	collisionVolumeScales = "110 50 220",
	collisionVolumeTest = true,
	collide = 0,

	-- Movement
	canFly = true,
	hoverAttack = true,
	airHoverFactor = 0,
	airStrafe = false,
	cruiseAlt = 50,
	brakeRate = .6,
	acceleration = .045,
	canMove = true,
	maxVelocity = 1.72,
	turnRate = 360,

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
			def = "KHeavyEden",
			onlyTargetCategory = "LARGE",
			mainDir = "0 0 1",
			MaxAngleDif = 10,
		},
		{
			def = "MMedium6Eden",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "TORPEDO",
			mainDir = "0 1 1",
			maxAngleDif = 180,
		},
		{
			def = "SGraserEdenPrimer",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 20,
		},
		{
			def = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0.5 0.5",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0.5 0.5",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0.5 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0.5 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "LARGE",
			mainDir = "0 1 0.2",
			maxAngleDif = 240,
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "LARGE",
			mainDir = "0 1 -0.2",
			maxAngleDif = 240,
		},				
		{
			def = "tstandard",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "SGraserEden",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		KHeavyEden = { --Shadow of Eden hull-mounted cannon
			name = "Heavy Kinetic Weapon",
			RGBcolor = "1 .3 .1",
			weaponType = "LaserCannon",
			thickness = 4,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "weapons\\kheavyfire",
			soundhit = "weapons\\kheavyhit",

			turret = true,
			range = 700,
			weaponvelocity = 1800,
			--FallOffRate=.05;

			reloadtime = 6,
			--burst=2;
			--burstrate=.1;
			projectiles = 2,
			sprayangle = 600,

			areaofeffect = 24,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:missile",

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 1200,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 16,
			},
		},

		MMedium6Eden = { -- Shadow of Eden missiles
			name = "Medium Missile x6",
			weaponType = "MissileLauncher",
			--myGravity=0.0001;
			burnblow = true,
			noselfdamage = true,
			model = "missile_small.s3o",
			--smoketrail=1;

			soundstart = "weapons\\mlightfire",
			soundhit = "weapons\\mlighthit",

			turret = true,
			range = 550,
			weaponvelocity = 450,
			startvelocity = 200,
			weaponacceleration = 200,
			flighttime = 2,
			projectiles = 2,
			burst = 6,
			burstrate = .3,
			sprayangle = 1200,

			reloadtime = 15,
			tracks = true,
			turnrate = 18000,

			fixedLauncher = true,

			areaofeffect = 64,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:missile",
			cegTag = "trail_missile_nodir",

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 360,
			},
		},

		SGraserEdenPrimer = {
			name = "Shadow of Eden Graser",
			RGBcolor = "0.3 1 0.3",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 0.1,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 1.3,
			projectiles = 0,

			commandfire = true,

			soundstart = "",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 800,

			reloadtime = 30,

			areaofeffect = 24,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:antimatter",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 0.001,
			},
		},

		KDualG = { --gunstar cannon
			name = "Light-Medium Kinetic Weapon",
			RGBcolor = "1 .7 .2",
			weaponType = "LaserCannon",
			thickness = .5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "weapons\\klightfire",
			soundhit = "weapons\\klighthit",

			turret = true,
			range = 600,
			weaponvelocity = 600,
			FallOffRate = .1,

			reloadtime = .12,
			sprayangle = 700,

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

		LMediumH = { -- Quasar lasers
			name = "Medium-Heavy Laser",
			RGBcolor = "1 0 1",
			weaponType = "BeamLaser",
			thickness = 3,
			intensity = 1,
			noselfdamage = true,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "weapons\\lmediumfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 700,

			reloadtime = 1,

			areaofeffect = 8,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:laser",

			laserFlareSize = 10,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 165,
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

		SGraserEden = {
			name = "Shadow of Eden Graser",
			RGBcolor = "0.3 0.3 1",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 10,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 4,

			canAttackGround = false,

			soundstart = "graserfire",
			soundhit = "",
			minIntensity = 1,

			turret = false,
			range = 800,

			reloadtime = 30,

			areaofeffect = 24,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:graser_blue",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 40,
			},
		},
	},
	
	explodeAs = "RetroDeathBig",
	selfDestructAs = "RetroDeathBig",
	canManualFire = true,
	
	-- Misc
	selfDestructCountdown = 6,
	script = "eclipse.lua",

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
			"custom:muzzlekineticlarge",
			"custom:muzzlemassdriverlarge",
			"custom:charge_graser_blue",
		}
	},
	
	customParams = {
		builds = 1.0,
		type = "large",
		cost = 7200,
		buildtime = 75,
		occupationStrength = 2,
		nobuild = 1,
		childflighttime = 30,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
