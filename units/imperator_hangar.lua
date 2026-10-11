local unitName = "imperator_hangar"
local unitDef = {
	Name = "Hangar",
	Description = "Production and repair facility",

	-- Required Tags
	power = 2000,
	mass = 16000,
	icontype = "imperator",
	Category = "LARGE WEAK TARGET ANY",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 15000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_hangar.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "80 40 80",
	collisionVolumeOffset = "0 0 0",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	--canFly=0;
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .02,
	CanMove = true,
	MaxVelocity = 1,
	TurnRate = 60,
	MovementClass = "HOVER6",

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = false,
	CanStop = true,
	SelfDestructCountdown = 6,

	-- Sight/Radar
	RadarDistance = 0,
	SightDistance = 0,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

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

	customParams = {
		type = "turret",
		builds = 1.0,
		cost = 1400,
		buildtime = 30,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
