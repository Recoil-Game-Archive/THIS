local unitName = "longbow"
local unitDef = {
	Name = "Longbow",
	Description = "Mag-shielded torpedo ship",

	-- Required Tags
	power = 100,
	mass = 190,
	icontype = "longbow",
	Category = "SMALL STRONG TARGET ANY CHASE",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 1000,
	ObjectName = "longbow.s3o",
	Side = "ALL",
	idleTime = 0,
	idleAutoHeal = 0,
	collisionVolumeType = "Box",
	collisionVolumeScales = "16 9 20",
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
	CanMove = true,
	MaxVelocity = 1.3,
	TurnRate = 1320,
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
	stealth = true,

	noChaseCategory = "NOCHASE",

	-- Weapons
	weapons = {
		{
			def = "tlongbow",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 60,
			badTargetCategory = "TINY SMALL",
		},
		{
			def = "KDual",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
	},

	weaponDefs = {
		tlongbow = {
			name = "Torpedo Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 700,
			reloadtime = 3,
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
		cost = 750,
		buildtime = 8,
		trailtex = "bitmaps/trails/2sw.png",
		trailr = .3,
		trailg = .9,
		trailb = .6,
		trailalpha = 1,
		trailwidth = 8,
		trailttl = 128,
		trailrate = 16,
		magshield = 1,
		moreguns = 2,
		toggle1 = 2,
		toggle1on = "Volley Fire",
		toggle1off = "Single Fire",
		toggle1tooltip = "Select between firing torpedoes rapidly or burst-wise",
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
