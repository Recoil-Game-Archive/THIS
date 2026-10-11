local unitName = "dronem"
local unitDef = {
	Name = "Drone",
	Description = "Bomber Drone",

	-- Required Tags
	power = 10,
	mass = 30,
	icontype = "fighter",
	Category = "DRONE SMALL WEAK TINY TARGET ANY NOCHASE",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 150,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "dronek.s3o",
	--BuildPic=dagger.tga;
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "20 12 10",
	collisionVolumeTest = true,
	script = "ship.lua",

	-- Movement
	canFly = true,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .08,
	MaxRudder = .03,
	MaxAileron = .01,
	MaxElevator = .01,
	TurnRadius = 500,
	maxAcc = .18,
	CanMove = true,
	MaxVelocity = 2.5,
	TurnRate = 1220,
	collide = false,
	canCrash = false,

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
			def = "MTiny",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
	},

	weaponDefs = {
		MTiny = {
			name = "Tiny Missile",
			weaponType = "MissileLauncher",
			noselfdamage = true,
			model = "missile_small.s3o",
			smoketrail = true,

			soundstart = "mtinyfire",
			soundhit = "weapons\\mlighthit",

			turret = true,
			range = 250,
			weaponvelocity = 600,
			startvelocity = 600,
			weaponacceleration = 100,
			flighttime = 1,
			dance = 30,
			targetBorder = true,
			burnblow = true,

			reloadtime = 5,
			burst = 4,
			burstrate = .25,

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

			explosiongenerator = "custom:missile",
			cegTag = "trail_missile_small",

			impactonly = true,
			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 100,
				large = 100,
			},
		},
	},

	--ExplodeAs=RetroDeathSmall;
	--SelfDestructAs=RetroDeathSmall;
	noChaseCategoy = "NOCHASE",

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
		type = "drone",
		role = "attacker",
		cost = 0,
		buildtime = 1,
		trailtex = "bitmaps/trails/2sw.png",
		trailr = .8,
		trailg = .8,
		trailb = .8,
		trailalpha = 1,
		trailwidth = 4,
		trailttl = 64,
		trailrate = 2,
		occupationStrength = 0,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
