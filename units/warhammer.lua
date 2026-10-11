local unitName = "warhammer"
local unitDef = {
	Name = "Warhammer",
	Description = "Cloaked missile assault ship (requires perk)",

	-- Required Tags
	power = 300,
	mass = 10,
	icontype = "warhammer",
	Category = "SMALL STRONG TARGET ANY",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 800,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "warhammer.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "14 6 14",
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
	MaxVelocity = 1.8,
	TurnRate = 800,
	collide = false,

	canCloak = true,
	minCloakDistance = 150,
	initCloaked = true,

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
			def = "MMedium12",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
	},

	weaponDefs = {
		MMedium12 = {
			name = "Medium Missile x12",
			weaponType = "MissileLauncher",
			--myGravity=0.0001;
			burnblow = true,
			noselfdamage = true,
			model = "missile_small.s3o",
			--smoketrail=1;

			soundstart = "mlightfire",
			soundhit = "mlighthit",

			turret = true,
			range = 400,
			weaponvelocity = 600,
			startvelocity = 300,
			weaponacceleration = 300,
			flighttime = 1,
			projectiles = 2,
			burst = 6,
			burstrate = .3,
			sprayangle = 1200,

			reloadtime = 15,
			--tracks=1;
			--turnrate=9000;

			--fixedLauncher=1;

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
			cegTag = "trail_missile_nodir",

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 360,
			},
		},
	},
	BadTagetCategory1 = "SMALL TINY",

	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

	-- Misc
	SmoothAnim = false,
	--fireState=1;

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_small",
		},
	},
	customParams = {
		type = "small",
		role = "support",
		cost = 950,
		buildtime = 15,
		needPerk = 7,
		occupationStrength = 0,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
