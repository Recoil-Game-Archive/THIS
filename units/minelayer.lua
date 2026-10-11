local unitName = "minelayer"
local unitDef = {
	Name = "Ring",
	Description = "Minelayer frigate (deploys defenses)",

	-- Required Tags
	power = 500,
	mass = 2400,
	icontype = "meteor",
	Category = "LARGE WEAK TARGET ANY",
	FootprintX = 3,
	FootprintZ = 3,
	MaxDamage = 6500,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "minelayer.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "48 24 72",
	collisionVolumeOffset = "0 0 12",
	collide = false,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 120,
	BrakeRate = .5,
	Acceleration = .06,
	CanMove = true,
	MaxVelocity = 1.95,
	TurnRate = 625,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 6,

	-- Transport
	transportCapacity = 4,
	transportMass = 2000,
	transportSize = 2,
	transportUnloadMethod = 1,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 700,
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
	},

	weaponDefs = {
		MLight12 = {
			name = "Light Missile x12",
			weaponType = "MissileLauncher",
			noselfdamage = true,
			model = "missile_small.s3o",
			smoketrail = true,

			soundstart = "mlightfire2",
			soundhit = "mlighthit",
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
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,
	script = "ship.lua",

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:teleport",
			"custom:damage_fire",
		},
	},

	customParams = {
		type = "large",
		cost = 1450,
		buildtime = 18,
		minelayer = 1.0,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
