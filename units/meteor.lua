local unitName = "meteor"
local unitDef = {
	Name = "Meteor",
	Description = "Mobile anti-fighter frigate",

	-- Required Tags
	power = 1100,
	mass = 2000,
	icontype = "meteor",
	Category = "LARGE WEAK TARGET ANY",
	FootprintX = 3,
	FootprintZ = 3,
	MaxDamage = 6750,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "meteor.s3o",
	Side = "ALL",
	sounds = {
		arrived = { "commandgiven" },
		ok = { "commandgiven" },
		select = { "select" },
	},
	collisionVolumeType = "Box",
	collisionVolumeScales = "32 24 72",
	collisionVolumeOffset = "0 0 36",
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 110,
	BrakeRate = .5,
	Acceleration = .07,
	CanMove = true,
	MaxVelocity = 2.1,
	TurnRate = 670,

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
	RadarDistance = 975,
	SightDistance = 650,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "MLight12",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 60,
		},
		{
			def = "LMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 0",
			maxAngleDif = 240,
			badTargetCategory = "LARGE",
		},
		{
			def = "LPointDefenseS",
			onlyTargetCategory = "TINY",
			mainDir = "0 -1 0",
			maxAngleDif = 270,
		},
		{
			def = "KDual",
			onlyTargetCategory = "TARGET",
		},
		--Weapon6 = MeteorEMP
		--OnlyTargetCategory6 = VOID
	},

	weaponDefs = {
		MLight12 = {
			name = "Light Missile x12",
			weaponType = "MissileLauncher",
			noselfdamage = true,
			model = "missile_small.s3o",
			smoketrail = true,

			soundstart = "weapons\\mlightfire2",
			soundhit = "weapons\\mlighthit",
			burnblow = true,

			turret = true,
			range = 350,
			weaponvelocity = 400,
			startvelocity = 400,
			weaponacceleration = 100,
			flighttime = 1,
			burst = 4,
			burstrate = .2,
			--dance=60;
			targetBorder = true,

			reloadtime = 2,
			tracks = true,
			turnrate = 22000,

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
			cegTag = "trail_missile",

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 105,
			},
		},

		LMedium = { --used by Meteor
			name = "Medium Laser",
			RGBcolor = "1 0 0",
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
			range = 550,

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

			laserFlareSize = 8,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 120,
			},
		},

		LPointDefenseS = { --used by Meteor
			name = "Point Defense",
			RGBcolor = "0 1 0",
			weaponType = "BeamLaser",
			thickness = 2,
			intensity = 1,
			noselfdamage = true,
			minIntensity = 1,
			beamburst = true,
			beamttl = 16,
			beamdecay = .9,
			size = 2,

			soundstart = "weapons\\llightfire2",
			soundhit = "",

			turret = true,
			range = 450,
			weaponvelocity = 1200,
			FallOffRate = .05,

			reloadtime = 1,

			areaofeffect = 8,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 30000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:laser",

			laserFlareSize = 0,

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 1,
				drone = 30,
				torpedo = 30,
			},
		},

		KDual = {
			name = "Light Kinetic Weapon",
			RGBcolor = "0.7 .7 .2",
			weaponType = "LaserCannon",
			thickness = .4,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "weapons\\klightfire",
			soundhit = "weapons\\klighthit",

			turret = true,
			range = 500,
			weaponvelocity = 600,
			FallOffRate = .05,

			reloadtime = .12,
			sprayangle = 800,

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
				default = 10,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 12,
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
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
			"custom:damage_fire",
		},
	},

	customParams = {
		type = "large",
		cost = 1750,
		buildtime = 16,
		trailtex = "bitmaps/trails/1m2sw.png",
		trailr = 1,
		trailg = .1,
		trailb = .2,
		trailalpha = 1,
		trailwidth = 18,
		trailttl = 128,
		trailrate = 16,
		headingaim2 = 180,
		pitchaim2 = 90,
		moreguns = 5,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
