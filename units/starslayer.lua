local unitName = "starslayer"
local unitDef = {
	Name = "Starslayer",
	Description = "Plasma artillery cruiser",

	-- Required Tags
	power = 9000,
	mass = 10000,
	icontype = "starslayer",
	Category = "LARGE STRONG TARGET ANY",
	FootprintX = 9,
	FootprintZ = 9,
	MaxDamage = 12000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "starslayer.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "136 96 80",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .02,
	CanMove = true,
	MaxVelocity = 1,
	TurnRate = 60,

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
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "PArtilleryQ",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 30,
		},
		{
			def = "PFlak",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 0",
			maxAngleDif = 230,
		},
		{
			def = "PFlak",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 0",
			maxAngleDif = 230,
		},
		{
			def = "PFlak",
			onlyTargetCategory = "TARGET",
		},
	},

	weaponDefs = {
		PArtilleryQ = {
			name = "Plasma Artillery Quad",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "partyfire",
			soundhit = "partyhit",

			turret = true,
			range = 2100,
			weaponvelocity = 500,

			reloadtime = 3,
			accuracy = 200,
			sprayangle = 400,
			projectiles = 2,

			areaofeffect = 350,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:partillery",
			cegTag = "trail_plasma",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 200,
				magsmall = 50,
				large = 400,
				maglarge = 100,
			},
		},

		PFlak = {
			name = "Plasme Flak", -- TODO: stupid hack to avoid detection as plasma causing stealth loss
			RGBcolor = ".2 .2 1",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,

			soundstart = "pmediumfire",
			soundhit = "pmediumhit",

			turret = true,
			range = 550,
			weaponvelocity = 900,

			reloadtime = .5,
			burst = 2,
			burstrate = .1,
			accuracy = 1500,

			areaofeffect = 150,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:plasma",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 60,
				magsmall = 15,
				large = 120,
				maglarge = 30,
			},
		},
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

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
		type = "large",
		cost = 5000,
		buildtime = 50,
		headingaim2 = 160,
		pitchaim2 = 120,
		moreguns = 4,
		barrelrecoildist = 15,
		barrelrecoilspeed = 180,
		barrelreturnspeed = 25,
		firestealthtime = 4500,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
