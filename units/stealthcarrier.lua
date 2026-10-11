local unitName = "stealthcarrier"
local unitDef = {
	Name = "Stealth Carrier",
	Description = "Cloaked production vessel",

	-- Required Tags
	power = 2400,
	mass = 10000,
	icontype = "supportcarrier",
	Category = "LARGE CARRIER WEAK TARGET COMMANDER ANY",
	commander = true,
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 16000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "stealthcarrier.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "64 48 136",
	collisionVolumeTest = true,
	collide = false,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .6,
	Acceleration = .025,
	CanMove = true,
	MaxVelocity = 1.65,
	TurnRate = 220,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	canCloak = true,
	minCloakDistance = 250,
	initCloaked = true,

	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 6,

	-- Sight/Radar
	RadarDistance = 1600,
	SightDistance = 900,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "PFlak",
			onlyTargetCategory = "TARGET",
			--mainDir = "-1 0 0", --(overridden by a later line)
			--maxAngleDif = 210, --(overridden by a later line)
			mainDir = "1 0 0",
			maxAngleDif = 210,
		},
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
		},
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
		},
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
		},
	},

	weaponDefs = {
		PFlak = {
			name = "Plasme Flak", -- TODO: stupid hack to avoid detection as plasma causing stealth loss
			RGBcolor = ".2 .2 1",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,

			soundstart = "pmediumfire",
			soundhit = "pmediumhit",

			turret = true,
			range = 550,
			weaponvelocity = 900,

			reloadtime = .5,
			burst = 2,
			burstrate = .1,
			accuracy = 1500,

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

			explosiongenerator = "custom:plasma",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 60,
				magsmall = 15,
				large = 120,
				maglarge = 30,
			},
		},

		LPointDefense = {
			name = "Point Defense",
			RGBcolor = "0 1 0",
			weaponType = "BeamLaser",
			thickness = 2.5,
			intensity = 1,
			noselfdamage = true,
			minIntensity = 1,
			beamburst = true,
			beamttl = 16,
			beamdecay = .9,
			size = 2,

			soundstart = "llightfire2",
			soundhit = "",

			turret = true,
			range = 600,
			weaponvelocity = 1200,
			FallOffRate = .05,

			reloadtime = .5,

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
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,
	script = "stealthcarrier.lua",

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
		},
	},

	customParams = {
		builds = 2.0,
		type = "large",
		cost = 2400,
		buildtime = 35,
		needPerk = 7,
		occupationStrength = 2,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
