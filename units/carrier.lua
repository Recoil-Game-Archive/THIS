local unitName = "carrier"
local unitDef = {
	Name = "Fleet Carrier",
	Description = "Field production and maintenance ship",

	-- Required Tags
	power = 1500,
	mass = 10000,
	icontype = "carrier",
	category = "LARGE CARRIER WEAK TARGET COMMANDER ANY",
	footprintX = 6,
	footprintZ = 6,
	maxDamage = 25000,
	idleTime = 0,
	idleAutoHeal = 0,
	objectName = "carrier.s3o",
	soundCategory = "CARRIER",
	collisionVolumeType = "Box",
	collisionVolumeScales = "92 40 180",
	collisionVolumeTest = true,
	collide = 0,
	script = "ship.lua",

	-- Movement
	canFly = true,
	hoverAttack = true,
	airHoverFactor = 0,
	airStrafe = false,
	cruiseAlt = 80,
	brakeRate = .5,
	acceleration = .01,
	canMove = true,
	maxVelocity = 1,
	turnRate = 220,

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
			name = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 1",
			MaxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
	
		{
			name = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 -1",
			maxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
		{
			name = "KLight",
			onlyTargetCategory = "TARGET",
			weaponMainDir = "0 0 1",
			maxAngleDif = 270,
			badTargetCategory = "LARGE",
		},
	
		{
			name = "GStandard",
			onlyTargetCategory = "LARGE",
		},
		{
			name = "GFlak",
			badTargetCategory = "LARGE",
		},
		{
			name = "TStandard",
			onlyTargetCategory = "LARGE",
			--badTargetCategory = "SMALL",
		},
	},
	
	explodeAs = "RetroDeathBig",
	selfDestructAs = "RetroDeathBig",
	
	-- Misc
	smoothAnim = false,
	selfDestructCountdown = 6,
	
	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
		},
	},
	
	customParams = {
		builds = 1.0,
		type = "large",
		cost = 3000,
		buildtime = 40,
		occupationStrength = 2,
		headingaim = 160,
		pitchaim = 120,
		firestealthtime = 3000,
		moreguns = 3,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
