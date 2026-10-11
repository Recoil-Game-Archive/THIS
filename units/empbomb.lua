local unitName = "empbomb"
local unitDef = {
	Name = "EMP Bomb",
	Description = "Meteor EMP Bomb",

	-- Required Tags
	power = 1,
	mass = 100,
	icontype = "torpedo",
	Category = "ANY NOCHASE NOSHIP",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 1000000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "blank.s3o",
	--BuildPic=dagger.tga;
	Side = "ALL",
	collisionVolumeType = "CylZ",
	collisionVolumeScales = "9 9 12",
	collisionVolumeTest = true,

	-- Movement
	canFly = true,
	cruiseAlt = 130,
	BrakeRate = 1,
	Acceleration = .3,
	TurnRadius = 150,
	maxAcc = .28,
	CanMove = true,
	MaxVelocity = 9,
	collide = false,
	canCrash = false,
	turnRate = 750,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 0,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 0,
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "MeteorEMP",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		MeteorEMP = {
			name = "Meteor EMP Bomb",
			weaponType = "Melee",
			noselfdamage = true,
			model = "torpedo.s3o",
			--smoketrail=1;

			--soundstart=mlightfire;
			soundhit = "deathmed",
			burnblow = true,

			range = 50,
			targetBorder = true,

			paralyzer = true,
			paralyzeTime = 12,

			edgeeffectiveness = 0.4,

			reloadtime = 2,

			areaofeffect = 600,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 53000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosionSpeed = 15,

			explosiongenerator = "custom:powerplant_explosion",
			--cegTag=trail_missile;

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 5000,
				torpedo = -0.001,
			},
		},
	},

	-- Misc
	SmoothAnim = false,
	Script = "empbomb.lua",

	customParams = {
		type = "torpedo",
		role = "support",
		cost = 0,
		buildtime = 1,
		occupationStrength = 0,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
