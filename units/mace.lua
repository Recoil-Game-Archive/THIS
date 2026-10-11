local unitName = "mace"
local unitDef = {
	Name = "Mace",
	Description = "Medium ship with mag-shield and lasers",

	-- Required Tags
	power = 100,
	mass = 120,
	icontype = "mace",
	Category = "SMALL STRONG TARGET ANY CHASE",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 2000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "mace.s3o",
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "16 8 16",
	collisionVolumeTest = true,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .04,
	CanMove = true,
	MaxVelocity = 1.7,
	TurnRate = 800,
	collide = false,

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
	SightDistance = 650,
	noChaseCategory = "NOSHIP",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "LLightS2",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
		{
			def = "LLightS",
			onlyTargetCategory = "TARGET",
			--mainDir = "0 0 1",
			--maxAngleDif = 30,
		},
	},

	weaponDefs = {
		LLightS2 = { --Mace double laser
			name = "Light Laser",
			RGBcolor = "1 0 0",
			weaponType = "BeamLaser",
			thickness = 1,
			intensity = 1,
			noselfdamage = true,
			burst = 2,
			burstrate = .2,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "weapons\\llightfire",
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

			soundstart = "weapons\\llightfire",
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


	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

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
		cost = 500,
		buildtime = 9,
		magshield = 1,
		trailtex = "bitmaps/trails/1m2sw.png",
		trailr = 1,
		trailg = .1,
		trailb = .2,
		trailalpha = 1,
		trailwidth = 9,
		trailttl = 128,
		trailrate = 16,
		moreguns = 2,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
