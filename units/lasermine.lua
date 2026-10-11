local unitName = "lasermine"
local unitDef = {
	Name = "Flash Mine",
	Description = "Bomb-pumped laser mine",

	-- Required Tags
	power = 1200,
	mass = 30,
	icontype = "torpedo",
	Category = "SMALL TARGET ANY NOCHASE NOSHIP",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 250,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "lasermine.s3o",
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "CylZ",
	collisionVolumeScales = "9 9 12",
	collisionVolumeTest = true,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .03,
	MaxRudder = .06,
	MaxAileron = .06,
	MaxElevator = .06,
	TurnRadius = 600,
	maxAcc = .08,
	CanMove = true,
	MaxVelocity = 0.1,
	TurnRate = 800,
	collide = false,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 0,
	kamikaze = 0,
	kamikazedistance = 40,

	canCloak = true,
	minCloakDistance = 150,
	initCloaked = true,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 150,
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "LMine",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 40,
		},
		{
			def = "TorpedoAM",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		LMine = {
			name = "Bomb-Pumped Laser",
			RGBcolor = "1 0.2 0.4",
			weaponType = "BeamLaser",
			thickness = 4,
			intensity = 1,
			noselfdamage = true,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "weapons\\lmediumfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 350,
			canattackground = false,

			reloadtime = 1,

			areaofeffect = 16,
			edgeeffectiveness = 0.5,

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
				default = 1400,
			},
		},

		TorpedoAM = {
			name = "Antimatter Warhead",
			weaponType = "Melee",
			noselfdamage = true,
			model = "torpedo.s3o",
			--smoketrail=1;

			--soundstart=mlightfire;
			soundhit = "weapons\\mlighthit",
			burnblow = true,

			turret = true,
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

			areaofeffect = 260,
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

			explosiongenerator = "custom:antimatter",
			--cegTag=trail_missile;

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 200,
				large = 400,
				maglarge = 400,
				torpedo = 2,
			},
		},
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	NoChaseCategory = "NOCHASE",

	-- Misc
	SmoothAnim = false,
	Script = "lasermine.lua",

	customParams = {
		type = "gunstar",
		cost = 250,
		buildtime = 1,
		occupationStrength = 0,
		luascript = "true",
		nobuild = "true",
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
