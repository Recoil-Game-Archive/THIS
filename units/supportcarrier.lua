local unitName = "supportcarrier"
local unitDef = {
	Name = "Battle Carrier",
	Description = "Armed support and production vessel",

	-- Required Tags
	power = 3000,
	mass = 12500,
	icontype = "supportcarrier",
	Category = "LARGE CARRIER STRONG TARGET COMMANDER ANY",
	commander = true,
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 20000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "supportcarrier.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "64 48 136",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .02,
	CanMove = true,
	MaxVelocity = 1.3,
	TurnRate = 180,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 6,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 900,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "PArtillery",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "LLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 270,
		},
		{
			def = "PArtilleryW",
			onlyTargetCategory = "TARGET",
			--mainDir = "0 0 1",
			--maxAngleDif = 120,
		},
		{
			def = "tstandard",
			onlyTargetCategory = "LARGE",
			--badTargetCategory = "SMALL",
		},
	},

	weaponDefs = {
		PArtillery = {
			name = "Plasma Artillery",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "partyfire",
			soundhit = "partyhit",

			turret = true,
			range = 1600,
			weaponvelocity = 500,

			reloadtime = 6,
			accuracy = 500,

			areaofeffect = 350,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:partillery",
			cegTag = "trail_plasma",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 200,
				magsmall = 50,
				large = 400,
				maglarge = 100,
			},
		},

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

		LLight = {
			name = "Light Laser",
			RGBcolor = "1 0 0",
			weaponType = "BeamLaser",
			thickness = 1,
			intensity = 1,
			noselfdamage = true,
			burst = 2,
			burstrate = .2,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "llightfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 600,

			reloadtime = 2,

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

			laserFlareSize = 0,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 60,
			},
		},

		PArtilleryW = {
			name = "Plasma Artillery",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "partyfire",
			soundhit = "partyhit",

			turret = true,
			range = 1600,
			weaponvelocity = 500,

			reloadtime = 9,
			accuracy = 500,

			areaofeffect = 350,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:partillery",
			cegTag = "trail_plasma",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 200,
				magsmall = 50,
				large = 400,
				maglarge = 100,
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

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,

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
		builds = 2.0,
		type = "large",
		cost = 3000,
		buildtime = 35,
		occupationStrength = 2,
		headingaim1 = 160,
		pitchaim1 = 60,
		headingaim2 = 60,
		pitchaim2 = 120,
		pitchaim5 = 60,
		headingaim5 = 60,
		firestealthtime = 3000,
		moreguns = 5,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
