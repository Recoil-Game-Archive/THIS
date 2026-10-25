local unitName = "gunstar_torpedo"
local unitDef = {
	Name = "Torpedo Gunstar",
	Description = "Heavy anti-ship defense",

	-- Required Tags
	power = 150,
	mass = 90,
	icontype = "defenseheavy",
	Category = "SMALL GUNSTAR WEAK TARGET ANY",
	FootprintX = 2,
	FootprintZ = 2,
	MaxDamage = 1250,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "gunstar_torpedo.s3o",
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "16 6 22",
	collisionVolumeTest = true,
	script = "ship.lua",

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
	MaxVelocity = 0.4,
	TurnRate = 400,
	collide = false,

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
	noChaseCategory = "NOSHIP",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "tgunstar",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 60,
			badTargetCategory = "TINY SMALL",
		},
		{
			def = "LPointDefenseS",
			onlyTargetCategory = "TINY",
		},
	},

	weaponDefs = {
		tgunstar = {
			name = "Torpedo Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 900,
			reloadtime = 4,
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
				torpedotype = 3, -- FTORPEDO
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
	},

	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:death_small",
			"custom:teleport_small",
			"custom:damage_fire",
		},
	},

	customParams = {
		type = "gunstar",
		cost = 750,
		buildtime = 9,
		--nobuild=true;
		moreguns = 2,
		headingaim2 = 160,
		pitchaim2 = 120,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
