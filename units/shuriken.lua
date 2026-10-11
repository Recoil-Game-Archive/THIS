local unitName = "shuriken"
local unitDef = {
	Name = "Shuriken",
	Description = "Large smart torpedo",

	-- Required Tags
	power = 100,
	mass = 65,
	icontype = "shuriken",
	Category = "SMALL WEAK TARGET ANY CHASE",
	FootprintX = 2,
	FootprintZ = 2,
	MaxDamage = 650,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "shuriken.s3o",
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "20 6 22",
	collisionVolumeTest = true,
	script = "torpedo.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .11,
	MaxRudder = .06,
	MaxAileron = .06,
	MaxElevator = .06,
	TurnRadius = 600,
	maxAcc = .08,
	CanMove = true,
	MaxVelocity = 3.2,
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
	SelfDestructCountdown = 0,
	kamikaze = 1,
	kamikazedistance = 80,
	kamikazeUseLOS = true,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 600,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons

	weapons = {
		{
			def = "ShurikenFakeWeapon",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 20,
		},
	},

	weaponDefs = {
		ShurikenFakeWeapon = {
			name = "Dummy Weapon",
			weaponType = "Melee",

			turret = true,
			range = 50,
			reloadtime = 1,
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
				default = .00001,
			},
		},
	},

	ExplodeAs = "ShurikenWeapon",
	SelfDestructAs = "ShurikenWeapon",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_small",
		},
	},
	customParams = {
		type = "small",
		role = "attacker",
		cost = 275,
		buildtime = 5,
		nobuild = "true",
		occupationStrength = 0,
		trailtex = "bitmaps/trails/1m2s.png",
		trailr = 1,
		trailg = .2,
		trailb = .2,
		trailalpha = 1,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
