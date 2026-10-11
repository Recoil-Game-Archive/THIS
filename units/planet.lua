local unitName = "planet"
local unitDef = {
	Name = "LOLOLOLOLOL",
	Description = "If you see this YOU'RE DOING IT WRONG!",

	-- Required Tags
	power = 1500,
	mass = 20000,
	icontype = "carrier",
	Category = "LARGE CARRIER WEAK TARGET COMMANDER",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 25000,
	ObjectName = "planet.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "92 40 180",
	collide = false,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .01,
	CanMove = true,
	MaxVelocity = 2,
	TurnRate = 220,

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
	SightDistance = 1400,
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 270,
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 -1",
			maxAngleDif = 270,
		},
		{
			def = "KLight",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 270,
		},
		{
			def = "GStandard",
			onlyTargetCategory = "TARGET",
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

		GStandard = {
			name = "Gravitrics",
			RGBcolor = "0 0 0",
			weaponType = "BeamLaser",
			thickness = 8,
			intensity = 1,
			noselfdamage = true,
			burstrate = .06,
			burst = 10,
			beamttl = 2,
			beamburst = true,

			soundstart = "grav",
			soundhit = "",

			turret = true,
			range = 350,

			reloadtime = 3,

			areaofeffect = 50,
			collidefriendly = false,
			avoidfriendly = true,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 9000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:grav",
			explosionSpeed = 600,

			interceptedbyshieldtype = 8, --gravitric
			damage = {
				default = 600,
			},
		},
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
		},
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
