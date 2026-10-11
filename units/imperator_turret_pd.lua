local unitName = "imperator_turret_pd"
local unitDef = {
	Name = "Point Defense",
	Description = "Intercepts torpedoes and drones",

	-- Required Tags
	power = 4000,
	mass = 9000,
	icontype = "imperator",
	Category = "LARGE WEAK TARGET ANY CHASE",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 5000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_turret_pd.s3o",
	Side = "ALL",
	collisionVolumeType = "Box",
	collisionVolumeScales = "32 32 64",
	collisionVolumeOffset = "0 0 0",
	collisionVolumeTest = true,
	collide = false,
	script = "ship.lua",

	-- Movement
	canFly = false,
	-- unitdefs_post.lua used to apply these to every unit with a canFly tag, even canFly=0
	floater = false,
	canSubmerge = true,
	useSmoothMesh = false,
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
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 6,

	-- Sight/Radar
	RadarDistance = 1050,
	SightDistance = 0,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "LPointDefenseL",
			onlyTargetCategory = "TINY",
			mainDir = "0 0 1",
			maxAngleDif = 140,
		},
		{
			def = "LPointDefenseL",
			onlyTargetCategory = "TINY",
			mainDir = "0 0 1",
			maxAngleDif = 140,
		},
		{
			def = "LPointDefenseL",
			onlyTargetCategory = "TINY",
			mainDir = "0 0 1",
			maxAngleDif = 140,
		},
	},

	weaponDefs = {
		LPointDefenseL = { --used by Imperator
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
			range = 1400,
			weaponvelocity = 1200,
			FallOffRate = .05,

			reloadtime = .25,

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

			impactonly = true,
			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 1,
				drone = 30,
				torpedo = 30,
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
		type = "turret",
		cost = 1500,
		buildtime = 120,
		arc = 140,
		headingaim1 = 480,
		pitchaim1 = 480,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
