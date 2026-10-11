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
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
			weaponMainDir = "-1 0 0",
			maxAngleDif = 210,
		},
	
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
			weaponMainDir = "1 0 0",
			maxAngleDif = 210,
		},
		{
			def = "LLightS",
			onlyTargetCategory = "TARGET",
		}
		
	},

	weaponDefs = {
		LPointDefense = {
			name = "Point Defense",
			RGBcolor = "0 1 0",
			weaponType = "BeamLaser",
			thickness = 2.5,
			intensity = 1,
			noselfdamage = true,
			minIntensity = 1,
			beamburst = true,
			beamttl = 16,
			beamdecay = .9,
			size = 2,

			soundstart = "llightfire2",
			soundhit = "",

			turret = true,
			range = 600,
			weaponvelocity = 1200,
			FallOffRate = .05,

			reloadtime = .5,

			areaofeffect = 8,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 30000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:laser",

			laserFlareSize = 0,

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 1,
				drone = 30,
				torpedo = 30,
			},
		},

		LLightS = { --Mace extra laser
			name = "Light Laser",
			RGBcolor = "1 0 0",
			weaponType = "BeamLaser",
			thickness = 1,
			intensity = 1,
			noselfdamage = true,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "llightfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 450,

			reloadtime = 2,

			areaofeffect = 8,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:laser",

			laserFlareSize = 0,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 60,
			},
		},
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
