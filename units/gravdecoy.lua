local unitName = "gravdecoy"
local unitDef = {
	Name = "Grav Decoy",
	Description = "Gravidar spoofer for Iris probe",

	-- Required Tags
	power = 1,
	mass = 8000,
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
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
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

	-- Misc
	SmoothAnim = false,
	Script = "gravdecoy.lua",

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
