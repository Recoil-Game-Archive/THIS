local unitName = "imperator_turret_am"
local unitDef = {
	Name = "Antimatter Beam",
	Description = "Extremely powerful beam cannon",

	-- Required Tags
	power = 8000,
	mass = 9000,
	icontype = "imperator",
	Category = "LARGE STRONG TARGET ANY CHASE",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 20000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_turret_am.s3o",
	Side = "ALL",
	--SoundCategory = "CRUISER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "96 56 96",
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
	RadarDistance = 0,
	SightDistance = 0,
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "SAntimatterBeamPrimer",
			onlyTargetCategory = "WEAK STRONG",
			mainDir = "0 0 1",
			maxAngleDif = 140,
		},
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
			mainDir = "-1 0 1",
			maxAngleDif = 110,
		},
		{
			def = "LPointDefense",
			onlyTargetCategory = "TINY",
			mainDir = "1 0 1",
			maxAngleDif = 110,
		},
		{
			def = "GStandard",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "GFlak",
		},
		{
			--onlyTargetCategory = "SMALL", --(overridden by a later line)
			def = "SAntimatterBeam",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		SAntimatterBeamPrimer = {
			name = "Antimatter Beam",
			RGBcolor = "1 1 1",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 30,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 4,
			projectiles = 0,

			soundstart = "",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 850,

			reloadtime = 10,

			areaofeffect = 24,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:antimatter",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 200,
			},
		},

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

			soundstart = "weapons\\llightfire2",
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

		GStandard = {
			name = "Gravitrics",
			RGBcolor = "0 0 0",
			weaponType = "BeamLaser",
			thickness = 8,
			intensity = 1,
			noselfdamage = true,
			burstrate = .06,
			burst = 10,
			beamttl = 2,
			beamburst = true,

			soundstart = "grav",
			soundhit = "",

			turret = true,
			range = 350,

			reloadtime = 3,

			areaofeffect = 50,
			collidefriendly = false,
			avoidfriendly = true,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 9000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:grav",
			explosionSpeed = 600,

			interceptedbyshieldtype = 8, --gravitric
			damage = {
				default = 600,
			},
		},

		GFlak = {
			name = "Grav Flak",
			RGBcolor = "1 1 1",
			weaponType = "BeamLaser", --Cannon;
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			beamburst = true,
			minintensity = 1,
			thickness = 1,

			soundhit = "grav",

			turret = true,
			range = 450,
			weaponvelocity = 900,

			reloadtime = 1.30,
			burst = 4,
			burstrate = .06,

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

			explosiongenerator = "custom:grav",
			explosionSpeed = 65536,

			interceptedbyshieldtype = 8, --plasma
			damage = {
				default = 40,
			},
		},

		SAntimatterBeam = {
			name = "Antimatter Beam",
			RGBcolor = "1 1 1",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 30,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 4,

			soundstart = "ambeamfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 700,

			reloadtime = 10,

			areaofeffect = 24,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:antimatter",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 200,
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
			"custom:charge_antimatter",
		},
	},

	customParams = {
		type = "turret",
		cost = 2500,
		buildtime = 80,
		arc = 140,
		moreguns = 4, -- TODO: ideally needs 5, there is a hack using piece name
		specialaim = 1,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
