local unitName = "comet"
local unitDef = {
	Name = "Comet",
	Description = "Fast attack destroyer",

	-- Required Tags
	power = 2500,
	mass = 6250,
	icontype = "comet",
	Category = "LARGE STRONG TARGET ANY",
	FootprintX = 4,
	FootprintZ = 4,
	MaxDamage = 16500,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "comet.s3o",
	Side = "ALL",
	sounds = {
		arrived = { "commandgiven" },
		ok = { "commandgiven" },
		select = { "select" },
	},
	collisionVolumeType = "Box",
	collisionVolumeScales = "52 32 136",
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .04,
	CanMove = true,
	MaxVelocity = 1.65,
	TurnRate = 450,

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
	SightDistance = 700,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "PHeavy",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 0",
			maxAngleDif = 210,
			badTargetCategory = "SMALL TORPEDO",
		},
		{
			def = "PHeavy",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 0",
			maxAngleDif = 210,
			badTargetCategory = "SMALL TORPEDO",
		},
		{
			def = "KMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 .5",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 .5",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "GStandard",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "tstandard",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "GFlak",
			badTargetCategory = "LARGE",
		},
	},

	weaponDefs = {
		PHeavy = {
			name = "Heavy Plasma Cannon",
			RGBcolor = "1 1 1",
			weaponType = "LaserCannon",
			thickness = 10,
			intensity = 1,
			noselfdamage = true,
			duration = .2,
			texture1 = "plasma",
			texture2 = "null",
			corethickness = 0,

			soundstart = "weapons\\pmediumfire",
			soundhit = "weapons\\pmediumhit",

			turret = true,
			range = 750,
			weaponvelocity = 300,

			reloadtime = 2,
			sprayangle = 450,

			areaofeffect = 120,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:plasma",

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 375,
				large = 750,
				magsmall = 93.75,
				maglarge = 187.5,
			},
		},

		KMedium = {
			name = "Medium Kinetic Weapon",
			RGBcolor = "1 .3 .1",
			weaponType = "LaserCannon",
			thickness = 1.5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .01,

			soundstart = "weapons\\klightfire",
			soundhit = "weapons\\klighthit",

			turret = true,
			range = 700,
			weaponvelocity = 600,
			--FallOffRate=.05;

			reloadtime = .5,
			--burst=2;
			--burstrate=.1;
			sprayangle = 500,

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
				default = 120,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 48,
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
		type = "large",
		cost = 4000,
		buildtime = 30,
		occupationStrength = 1,
		headingaim1 = 120,
		pitchaim1 = 80,
		headingaim3 = 360,
		pitchaim3 = 240,
		firestealthtime = 3000,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
