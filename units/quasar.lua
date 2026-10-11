local unitName = "quasar"
local unitDef = {
	Name = "Quasar",
	Description = "Heavy assault battlecruiser",

	-- Required Tags
	power = 6000,
	mass = 30000,
	icontype = "quasar",
	Category = "LARGE STRONG TARGET ANY",
	FootprintX = 8,
	FootprintZ = 8,
	MaxDamage = 52000,
	--autoheal=20;
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "quasar.s3o",
	Side = "ALL",
	collisionVolumeScales = "160 72 400",
	collisionVolumeOffset = "0 0 0",
	collisionVolumeType = "Box",
	collide = false,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 75,
	BrakeRate = .5,
	Acceleration = .04,
	CanMove = true,
	MaxVelocity = 1.2,
	TurnRate = 85,
	MaxBank = 0,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	CanDgun = true,
	SelfDestructCountdown = 10,

	-- Sight/Radar
	RadarDistance = 1350,
	SightDistance = 900,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "SGraserPrimer",
			--onlyTargetCategory = "TARGET", --(overridden by a later line)
			mainDir = "0 0 1",
			maxAngleDif = 120,
			onlyTargetCategory = "SMALL LARGE",
			badTargetCategory = "SMALL WEAK",
		},
		{
			def = "SGraser",
			onlyTargetCategory = "VOID",
		},
		{
			def = "MegaLaserPrimer",
			mainDir = "0 0 1",
			maxAngleDif = 10,
			--onlyTargetCategory = "TARGET",
			--badTargetCategory = "SMALL WEAK",
		},
		{
			def = "GQuasar",
			onlyTargetCategory = "LARGE",
			badTargetCategory = "WEAK",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "-0.5 0 0.7",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "0.5 0 0.7",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 0",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 0",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "-0.2 0 -1",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "KDualH",
			onlyTargetCategory = "TARGET",
			mainDir = "0.2 0 -1",
			maxAngleDif = 180,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			mainDir = "-1 0 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			mainDir = "1 0 0",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "LMediumH",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 -1",
			maxAngleDif = 210,
			badTargetCategory = "LARGE",
		},
		{
			def = "GFlakQuasar",
			badTargetCategory = "LARGE",
		},
		{
			def = "PHeavy",
			onlyTargetCategory = "TARGET",
			mainDir = "-0.2 0 -0.8",
			maxAngleDif = 160,
			badTargetCategory = "SMALL TINY",
		},
		{
			def = "PHeavy",
			onlyTargetCategory = "TARGET",
			mainDir = "0.2 0 -0.8",
			maxAngleDif = 160,
			badTargetCategory = "SMALL TINY",
		},
		{
			def = "tQuasar",
			onlyTargetCategory = "LARGE",
		},
		{
			def = "MQuasar",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "MQuasar",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "MegaLaser",
			onlyTargetCategory = "VOID",
		},
	},

	weaponDefs = {
		SGraserPrimer = {
			name = "Quasar Graser",
			RGBcolor = "0.3 1 0.3",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 0.1,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 1.3,
			projectiles = 0,

			soundstart = "",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 800,

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
				default = 0.001,
			},
		},

		SGraser = {
			name = "Quasar Graser",
			RGBcolor = "0.3 1 0.3",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 9,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 4,

			canAttackGround = false,

			soundstart = "graserfire",
			soundhit = "",
			minIntensity = 1,

			turret = false,
			range = 800,

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

			explosiongenerator = "custom:graser",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 30,
			},
		},

		MegaLaserPrimer = {
			name = "Megalaser",
			RGBcolor = "0 0 0",
			weaponType = "DGun",
			largeBeamLaser = true,
			thickness = 0.1,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 1,
			beamdecay = .7,
			laserflaresize = 5,
			projectiles = 0,

			commandfire = true,

			soundstart = "",
			soundhit = "",
			minIntensity = 0.5,

			turret = false,
			range = 1250,

			reloadtime = 60,

			areaofeffect = 30,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,
			--noExplode = true;

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:antimatter",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 0.001,
			},
		},

		GQuasar = {
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
			range = 575,

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

		KDualH = { --Quasar cannons
			name = "Medium-Light Kinetic Weapon",
			RGBcolor = "1 .5 .3",
			weaponType = "LaserCannon",
			thickness = 1.5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .01,

			soundstart = "klightfire",
			soundhit = "klighthit",

			turret = true,
			range = 700,
			weaponvelocity = 600,
			--FallOffRate=.05;

			reloadtime = .16,
			--burst=2;
			--burstrate=.1;
			sprayangle = 500,

			areaofeffect = 8,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:kinetic",

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 40,
			},
			customParams = {
				spray_boost = 10,
				rof_boost = 96,
			},
		},

		LMediumH = { -- Quasar lasers
			name = "Medium-Heavy Laser",
			RGBcolor = "1 0 1",
			weaponType = "BeamLaser",
			thickness = 3,
			intensity = 1,
			noselfdamage = true,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "lmediumfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 700,

			reloadtime = 1,

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

			laserFlareSize = 10,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 165,
			},
		},

		GFlakQuasar = {
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
			range = 700,
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

		PHeavy = {
			name = "Heavy Plasma Cannon",
			RGBcolor = "1 1 1",
			weaponType = "LaserCannon",
			thickness = 10,
			intensity = 1,
			noselfdamage = true,
			duration = .2,
			texture1 = "plasma",
			texture2 = "null",
			corethickness = 0,

			soundstart = "pmediumfire",
			soundhit = "pmediumhit",

			turret = true,
			range = 750,
			weaponvelocity = 300,

			reloadtime = 2,
			sprayangle = 450,

			areaofeffect = 120,
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

			interceptedbyshieldtype = 16, --plasma
			damage = {
				default = 375,
				large = 750,
				magsmall = 93.75,
				maglarge = 187.5,
			},
		},

		tQuasar = {
			name = "Torpedo Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 1200,
			reloadtime = 8,
			projectiles = 0,

			areaofeffect = 8,

			tolerance = 3000,
			canattackground = false,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			--explosiongenerator=custom:corruption_shot1;

			interceptedbyshieldtype = 0, --imaginary
			damage = {
				default = .0001,
			},
			customParams = {
				torpedotype = 2, -- TORPEDO
			},
		},

		MQuasar = {
			name = "Light Missile Pack",
			weaponType = "MissileLauncher",
			noselfdamage = true,
			model = "missile_small.s3o",
			smoketrail = true,

			soundstart = "mlightfire2",
			soundhit = "mlighthit",
			burnblow = true,

			turret = true,
			range = 475,
			weaponvelocity = 400,
			startvelocity = 400,
			weaponacceleration = 100,
			flighttime = 1,
			projectiles = 2,
			--dance=60;
			targetBorder = true,

			reloadtime = 2,
			tracks = true,
			turnrate = 22000,

			fixedLauncher = false,

			areaofeffect = 64,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,

			tolerance = 3000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:missile",
			cegTag = "trail_missile",

			interceptedbyshieldtype = 2, --missile
			damage = {
				default = 125,
			},
		},

		MegaLaser = {
			name = "Megalaser",
			RGBcolor = "0.4 0.7 1",
			weaponType = "BeamLaser",
			largeBeamLaser = true,
			thickness = 24,
			intensity = 1,
			noselfdamage = true,
			beamburst = true,
			beamttl = 4,
			beamdecay = .7,
			laserflaresize = 4,

			--commandfire=1;
			canAttackGround = false,

			soundstart = "ambeamfire",
			soundhit = "",
			minIntensity = 1,

			turret = false,
			range = 1250,

			reloadtime = 60,

			areaofeffect = 30,
			collidefriendly = false,
			avoidfriendly = false,
			collidefeature = false,
			avoidfeature = false,
			--noExplode = true;

			tolerance = 1000,

			impulsefactor = 0,
			impulseBoost = 0,
			craterMult = 0,
			craterBoost = 0,

			explosiongenerator = "custom:antimatter",

			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 250,
			},
		},
	},

	ExplodeAs = "RetroDeathHuge",
	SelfDestructAs = "RetroDeathHuge",

	-- Misc
	SmoothAnim = false,
	Script = "quasar.lua",
	--damageModifier=0.25;

	sfxTypes = {
		explosionGenerators = {
			"custom:death_med",
			"custom:death_large",
			"custom:death_multimed",
			"custom:teleport",
			"custom:muzzlekinetic",
			"custom:muzzlemassdriver",
			"custom:charge_graser",
			"custom:sparks",
			"custom:charge_antimatter",
			"custom:death_huge",
			"custom:damage_fire",
		},
	},

	customParams = {
		type = "large",
		death_sounds = "huge",
		cost = 10500,
		buildtime = 105,
		nobuild = "true",
		luascript = "true",
		occupationStrength = 2,
		minelayer = 1.0,
		limit = 3,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
