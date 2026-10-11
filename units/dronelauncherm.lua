local unitName = "dronelauncherm"
local unitDef = {
	Name = "Crossbow",
	Description = "Medium ship launching remote controlled bomber drones",

	-- Required Tags
	power = 150,
	mass = 120,
	icontype = "chukenu",
	Category = "SMALL WEAK TARGET ANY",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 900,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "dronelauncherk.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "17 16 20",
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
	CanMove = true,
	MaxVelocity = 1.7,
	TurnRate = 600,
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
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "DroneMarker",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
		},
	},

	weaponDefs = {
		DroneMarker = {
			name = "Drone Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 1600,
			reloadtime = 8,
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
				torpedotype = 1, -- DRONE
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
		role = "support",
		cost = 1600,
		buildtime = 12,
		trailtex = "bitmaps/trails/2sw.png",
		trailr = .4,
		trailg = .4,
		trailb = .4,
		trailalpha = 1,
		trailwidth = 7,
		trailttl = 64,
		trailrate = 2,
		moreguns = 2,
		headingaim2 = 100,
		pitchaim2 = 60,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
