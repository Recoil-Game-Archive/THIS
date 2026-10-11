local unitName = "dagger"
local unitDef = {
	Name = "Dagger",
	Description = "Light ship with dual kinetics",

	-- Required Tags
	power = 30,
	mass = 60,
	icontype = "dagger",
	Category = "SMALL WEAK TARGET ANY CHASE",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 650,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "dagger.s3o",
	--BuildPic=dagger.tga;
	Side = "ALL",
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
	Acceleration = .08,
	MaxRudder = .06,
	MaxAileron = .06,
	MaxElevator = .06,
	TurnRadius = 600,
	maxAcc = .08,
	CanMove = true,
	MaxVelocity = 2.4,
	TurnRate = 1220,
	collide = false,
	canCrash = true,

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
	SightDistance = 750,
	noChaseCategory = "NOSHIP",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 11",
			maxAngleDif = 30,
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
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
	},

	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_small",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
		},
	},
	customParams = {
		type = "small",
		role = "attacker",
		cost = 200,
		buildtime = 5,
		trailtex = "bitmaps/trails/1m2s.png",
		trailr = 1,
		trailg = 1,
		trailb = .2,
		trailalpha = 1,
		trailwidth = 6,
		trailttl = 128,
		trailrate = 8,
		moreguns = 3,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
