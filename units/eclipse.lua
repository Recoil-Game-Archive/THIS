local unitName = "eclipse"
local unitDef = {
	Name = "Eclipse",
	Description = "Advanced command-and-control cruiser",

	-- Required Tags
	power = 3000,
	mass = 20000,
	icontype = "carrier",
	category = "LARGE CARRIER Strong TARGET COMMANDER ANY",
	footprintX = 8,
	footprintZ = 8,
	maxDamage = 36000,
	autoheal = 10,
	idleTime = 0,
	idleAutoHeal = 0,
	objectName = "eclipse.s3o",
	soundCategory = "CARRIER",
	collisionVolumeType = "Box",
	collisionVolumeScales = "110 50 220",
	collisionVolumeTest = true,
	collide = 0,

	-- Movement
	canFly = true,
	hoverAttack = true,
	airHoverFactor = 0,
	airStrafe = false,
	cruiseAlt = 50,
	brakeRate = .6,
	acceleration = .045,
	canMove = true,
	maxVelocity = 1.72,
	turnRate = 360,

	-- Construction
	LevelGround = false,

	-- Sight/Radar
	RadarDistance = 1350,
	SightDistance = 900,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			name = "KHeavyEden",
			onlyTargetCategory = "LARGE",
			mainDir = "0 0 1",
			MaxAngleDif = 10,
		},
		{
			name = "MMedium6Eden",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "TORPEDO",
			mainDir = "0 1 1",
			maxAngleDif = 180,
		},
		{
			name = "SGraserEdenPrimer",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 20,
		},
		{
			name = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0.5 0.5",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			name = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0.5 0.5",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			name = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0.5 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			name = "KDualG",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0.5 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			name = "LMediumH",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "LARGE",
			mainDir = "0 1 0.2",
			maxAngleDif = 240,
		},
		{
			name = "LMediumH",
			onlyTargetCategory = "TARGET",
			badTargetCategory = "LARGE",
			mainDir = "0 1 -0.2",
			maxAngleDif = 240,
		},				
		{
			name = "TStandard",
			onlyTargetCategory = "LARGE",
		},
		{
			name = "SGraserEden",
			onlyTargetCategory = "VOID",
		},
	},
	
	explodeAs = "RetroDeathBig",
	selfDestructAs = "RetroDeathBig",
	canManualFire = true,
	
	-- Misc
	selfDestructCountdown = 6,
	script = "eclipse.lua",

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
			"custom:muzzlekineticlarge",
			"custom:muzzlemassdriverlarge",
			"custom:charge_graser_blue",
		}
	},
	
	customParams = {
		builds = 1.0,
		type = "large",
		cost = 7200,
		buildtime = 75,
		occupationStrength = 2,
		nobuild = 1,
		childflighttime = 30,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
