local unitName = "gunstar_cannon"
local unitDef = {
	Name = "Cannon Gunstar",
	Description = "General purpose defense",

	-- Required Tags
	power = 50,
	mass = 80,
	icontype = "defense",
	Category = "SMALL GUNSTAR WEAK TARGET ANY",
	FootprintX = 2,
	FootprintZ = 2,
	MaxDamage = 1400,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "gunstar_cannon.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeOffsets = "1 0 0",
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
	MaxVelocity = 0.5,
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
	SelfDestructCountdown = 6,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 800,
	noChaseCategory = "NOSHIP",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KDualG",
			onlyTargetCategory = "TARGET",
			--mainDir = "0 0 1", --(overridden by a later line)
			--maxAngleDif = 70, --(overridden by a later line)
			mainDir = "0 0 1",
			maxAngleDif = 40,
		},
		{
			def = "LLight",
			onlyTargetCategory = "TARGET",
		},
	},

	weaponDefs = {
		KDualG = { --gunstar cannon
			name = "Light-Medium Kinetic Weapon",
			RGBcolor = "1 .7 .2",
			weaponType = "LaserCannon",
			thickness = .5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "klightfire",
			soundhit = "klighthit",

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
	},

	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:death_small",
			"custom:teleport_small",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
			"custom:damage_fire",
		},
	},

	customParams = {
		type = "gunstar",
		cost = 175,
		buildtime = 6,
		--nobuild=true;
		moreguns = 2,
		headingaim1 = 80,
		pitchaim1 = 60,
		headingaim2 = 160,
		pitchaim2 = 120,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
