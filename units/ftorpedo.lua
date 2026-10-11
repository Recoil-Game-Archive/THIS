local unitName = "ftorpedo"
local unitDef = {
	Name = "Torpedo", --for forward launches
	Description = "bomb",

	-- Required Tags
	power = 1200,
	mass = 30,
	icontype = "torpedo",
	Category = "TORPEDO SMALL TINY TARGET ANY NOCHASE NOSHIP",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 10,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "torpedo.s3o",
	--BuildPic=dagger.tga;
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "CylZ",
	collisionVolumeScales = "9 9 12",
	collisionVolumeTest = true,
	script = "torpedo.lua",

	-- Movement
	canFly = true,
	cruiseAlt = 80,
	BrakeRate = 1.5,
	Acceleration = .38,
	MaxRudder = .03,
	MaxAileron = .06,
	MaxElevator = .09,
	TurnRadius = 150,
	maxAcc = .28,
	CanMove = true,
	MaxVelocity = 9,
	collide = false,
	canCrash = false,
	--hoverAttack=1;
	turnRate = 1200,

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
	SightDistance = 0,
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "Torpedo",
			onlyTargetCategory = "VOID",
		},
		{
			def = "TorpedoAM",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		Torpedo = {
			name = "Torpedo Warhead",
			weaponType = "Melee",
			noselfdamage = true,
			model = "torpedo.s3o",
			--smoketrail=1;

			--soundstart=mlightfire;
			soundhit = "weapons\\mlighthit",
			burnblow = true,

			turret = false,
			range = 50,
			heightMod = .3,
			weaponvelocity = 100,
			startvelocity = 100,
			weaponacceleration = 100,
			flighttime = 2,
			targetBorder = true,

			reloadtime = 2,
			tracks = true,
			turnrate = 220000,

			--fixedLauncher=1;

			areaofeffect = 0,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 53000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:torpedo",
			--cegTag=trail_missile;

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 500,
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

	--ExplodeAs=RetroDeathSmall;
	SelfDestructAs = "TorpedoBlast",

	NoChaseCategory = "NOCHASE",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_med",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
		},
	},
	customParams = {
		type = "torpedo",
		role = "attacker",
		cost = 0,
		buildtime = 1,
		trailtex = "bitmaps/trails/missile.png",
		trailr = .4,
		trailg = 1,
		trailb = .2,
		trailalpha = 1,
		trailwidth = 1,
		trailttl = 64,
		trailrate = 2,
		occupationStrength = 0,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
