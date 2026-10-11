local unitName = "sword"
local unitDef = {
	Name = "Sword",
	Description = "Medium ship with dual missiles and kinetics",

	-- Required Tags
	power = 80,
	mass = 90,
	icontype = "sword",
	Category = "SMALL STRONG TARGET ANY",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 1200,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "sword.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "16 14 20",
	collisionVolumeTest = true,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .06,
	CanMove = true,
	MaxVelocity = 2,
	TurnRate = 1000,
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
			def = "MLight6",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 60,
		},
		{
			def = "KLightS",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			--maxAngleDif = 60,
		},
		{
			def = "KLightS",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			--maxAngleDif = 60,
		},
	},

	weaponDefs = {
		MLight6 = {
			name = "Light Missile x6",
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
			--projectiles=2;
			burst = 2,
			burstrate = .4,
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

		KLightS = {
			name = "Light Kinetic Weapon",
			RGBcolor = "1 .7 .2",
			weaponType = "LaserCannon",
			thickness = .6,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "klightfire",
			soundhit = "klighthit",

			turret = true,
			range = 350,
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
				default = 20,
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
		role = "brawler",
		cost = 400,
		buildtime = 8,
		trailtex = "bitmaps/trails/2m.png",
		trailr = .8,
		trailg = .8,
		trailb = .8,
		trailalpha = 1,
		trailwidth = 5,
		trailttl = 128,
		trailrate = 16,
		headingaim2 = 100,
		pitchaim2 = 60,
		moreguns = 3,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
