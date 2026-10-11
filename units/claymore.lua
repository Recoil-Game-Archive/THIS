local unitName = "claymore"
local unitDef = {
	Name = "Claymore",
	Description = "Medium plasma cannon ship",

	-- Required Tags
	power = 90,
	mass = 110,
	icontype = "claymore",
	Category = "SMALL STRONG TARGET ANY",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 800,
	ObjectName = "claymore.s3o",
	Side = "ALL",
	idleTime = 0,
	idleAutoHeal = 0,
	collisionVolumeType = "Box",
	collisionVolumeScales = "15 10 28",
	collisionVolumeTest = true,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .05,
	CanMove = true,
	MaxVelocity = 2.1,
	TurnRate = 890,
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
	stealth = true,

	noChaseCategory = "NOSHIP",

	-- Weapons
	weapons = {
		{
			def = "PMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			--maxAngleDif = 30,
		},
		{
			def = "KDual",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
	},

	weaponDefs = {
		PMedium = {
			name = "Medium Plasma Cannon",
			RGBcolor = "1 1 1",
			weaponType = "LaserCannon",
			thickness = 6,
			intensity = 1,
			noselfdamage = true,
			duration = .1,
			texture1 = "plasma",
			texture2 = "null",
			corethickness = 0,

			soundstart = "pmediumfire",
			soundhit = "pmediumhit",

			turret = true,
			range = 700,
			weaponvelocity = 400,

			reloadtime = 2,
			sprayangle = 100,

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
				default = 250,
				large = 500,
				magsmall = 72.5,
				maglarge = 125,
			},
		},

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

		KDual = {
			name = "Light Kinetic Weapon",
			RGBcolor = "0.7 .7 .2",
			weaponType = "LaserCannon",
			thickness = .4,
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
		role = "sniper",
		cost = 600,
		buildtime = 12,
		trailtex = "bitmaps/trails/2mw.png",
		trailr = .1,
		trailg = .9,
		trailb = 1,
		trailalpha = 1,
		trailwidth = 5,
		trailttl = 128,
		trailrate = 16,
		moreguns = 3,
		firestealthtime = 2000,
		barrelrecoildist = 1.5,
		barrelrecoilspeed = 1000,
		barrelreturnspeed = 2,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
