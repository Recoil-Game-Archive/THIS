local unitName = "starbase"
local unitDef = {
	Name = "Starbase",
	Description = "Protects and increases production of planets",

	-- Required Tags
	power = 3000,
	mass = 18000,
	icontype = "starbase",
	Category = "LARGE STARBASE WEAK TARGET ANY",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 16000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "starbase.s3o",
	Side = "ALL",
	collisionVolumeType = "CylY",
	collisionVolumeScales = "126 114 126",
	collisionVolumeOffsets = "0 -32 0",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 50,
	BrakeRate = 1000,
	Acceleration = 0.01,
	CanMove = true,
	MaxVelocity = 0.1,
	TurnRate = 0,

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
	RadarDistance = 2000,
	SightDistance = 1000,
	noChaseCategory = "ANY",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KLightL",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KLightL",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KLightL",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "LMedium",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "tstarbase",
			onlyTargetCategory = "LARGE",
		},
	},

	weaponDefs = {
		KLightL = { --starbase cannon
			name = "Medium-Light Kinetic Weapon",
			RGBcolor = "1 .7 .35",
			weaponType = "LaserCannon",
			thickness = .75,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "klightfire",
			soundhit = "klighthit",

			turret = true,
			range = 700,
			weaponvelocity = 800,
			FallOffRate = .1,

			reloadtime = .25,
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
				default = 25,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 16,
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

			soundstart = "lmediumfire",
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

		tstarbase = {
			name = "Torpedo Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 900,
			reloadtime = 5,
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
		type = "large",
		cost = 1800,
		buildtime = 30,
		occupationStrength = 2.5,
		--minelayer=1.5;
		moreguns = 4,
		headingaim1 = 160,
		pitchaim1 = 120,
		torpedopitch = -30,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
