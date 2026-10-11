local unitName = "imperator_hardpoint"
local unitDef = {
	Name = "Hardpoint",
	Description = "Installation site for heavy turrets",

	-- Required Tags
	--power=0; (overridden by a later line)
	mass = 20000,
	icontype = "imperator",
	Category = "ANY NOCHASE NOSHIP",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 100000000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_hardpoint.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "64 64 64",
	collisionVolumeOffsets = "0 -70 0",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",
	power = 1,

	-- Movement
	--canFly=1;
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 50,
	BrakeRate = 0.06,
	Acceleration = 0.01,
	CanMove = true,
	MaxVelocity = 0.5,
	TurnRate = 20,
	MovementClass = "HOVER6",

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
	SightDistance = 700,
	noChaseCategory = "TARGET",
	stealth = true,

	-- Weapons
	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,

	sfxTypes = {
		explosionGenerators = {
			"custom:death_large_shock",
		},
	},

	customParams = {
		type = "hardpoint",
		cost = 0,
		buildtime = 1,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
