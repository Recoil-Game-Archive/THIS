local unitName = "imperator"
local unitDef = {
	Name = "Imperator",
	Description = "Flagship that serves as a platform for turrets (sold separately)",

	-- Required Tags
	power = 90000,
	mass = 20000,
	icontype = "imperator",
	Category = "LARGE WEAK TARGET ANY",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 80000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator.s3o",
	Side = "ALL",
	sounds = {
		arrived = { "commandgiven" },
		ok = { "commandgiven" },
		select = { "select" },
	},
	collisionVolumeType = "Box",
	collisionVolumeScales = "120 280 230",
	collisionVolumeOffsets = "0 0 0",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 50,
	BrakeRate = 0.06,
	Acceleration = 0.01,
	CanMove = true,
	MaxVelocity = 0.5,
	TurnRate = 20,
	bankingAllowed = false,

	MaxBank = 0,
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
	RadarDistance = 2000,
	SightDistance = 1000,
	noChaseCategory = "ANY",
	stealth = true,

	-- Weapons
	ExplodeAs = "ImperatorDeath",
	SelfDestructAs = "ImperatorDeath",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:death_mega",
			"custom:teleport_huge",
		},
	},

	customParams = {
		type = "large",
		cost = 4500,
		buildtime = 50,
		limit = 1,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
