local unitName = "wraith"
local unitDef = {
	name = "Wraith",
	description = "Point defense, intercepts torpedoes and drones",

	-- Required Tags
	power = 80,
	mass = 50,
	icontype = "wraith",
	category = "SMALL WEAK TARGET ANY",
	footprintX = 1,
	footprintZ = 1,
	maxDamage = 500,
	idleTime = 0,
	idleAutoHeal = 0,
	objectName = "wraith.s3o",
	SoundCategory = "FIGHTER",
	collisionVolumeType = "Box",
	collisionVolumeScales = "16 6 24",
	collisionVolumeTest = true,
	script = "ship.lua",

	-- Movement
	canFly = true,
	hoverAttack = true,
	airHoverFactor = 0,
	airStrafe = false,
	cruiseAlt = 130,
	brakeRate = 1.5,
	acceleration = .09,
	canMove = true,
	maxVelocity = 2.2,
	turnRate = 1620,
	collide = false,

	-- Construction
	levelGround = false,

	-- Sight/Radar
	radarDistance = 975,
	sightDistance = 650,
	noChaseCategory = "ANY",
	stealth = true,

	-- Weapons
	weapons = {
		{
			name = "LPointDefense",
			onlyTargetCategory = "TINY",
			weaponMainDir = "-1 0 0",
			maxAngleDif = 210,
		},
	
		{
			name = "LPointDefense",
			onlyTargetCategory = "TINY",
			weaponMainDir = "1 0 0",
			maxAngleDif = 210,
		},
		{
			name = "LLightS",
			onlyTargetCategory = "TARGET",
		}
		
	},

	explodeAs = "RetroDeathSmall",
	selfDestructAs = "RetroDeathSmall",

	-- Misc
	smoothAnim = false,
	selfDestructCountdown = 6,

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_small",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
		},
	},
	customParams  =  {
		type = "small",
		role = "support",
		cost = 800,
		buildtime = 8,
		trailtex = "bitmaps/trails/1m2sw.png",
		trailr = .5,
		trailg = 1,
		trailb = .5,
		trailalpha = 1,
		trailwidth = 7,
		trailttl = 128,
		trailrate = 16,
		moreguns = 3,
		headingaim1 = 800,
		pitchaim1 = 800,
		headingaim3 = 90,
		pitchaim3 = 90,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
