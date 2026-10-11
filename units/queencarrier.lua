local unitName = "queencarrier"
local unitDef = {
	Name = "Advanced Battle Carrier",
	Description = "Squadron command ship",

	-- Required Tags
	power = 7500,
	mass = 15000,
	icontype = "quasar",
	Category = "LARGE CARRIER STRONG TARGET COMMANDER ANY",
	commander = true,
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 45000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "supportcarrier.s3o",
	Side = "ALL",
	sounds = {
		arrived = { "commandgiven" },
		ok = { "commandgiven" },
		select = { "select" },
	},
	collisionVolumeType = "Box",
	collisionVolumeScales = "64 48 136",
	collisionVolumeTest = true,
	collide = false,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 80,
	BrakeRate = .5,
	Acceleration = .02,
	CanMove = true,
	MaxVelocity = 1.3,
	TurnRate = 180,

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
	RadarDistance = 2000,
	SightDistance = 1000,
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "PArtillery",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KMedium",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "KMedium",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "LMedium",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 270,
		},
		{
			def = "PArtilleryW",
			onlyTargetCategory = "TARGET",
			--mainDir = "0 0 1",
			--maxAngleDif = 120,
		},
		{
			def = "tQuasar",
			onlyTargetCategory = "LARGE",
			--badTargetCategory = "SMALL",
		},
	},

	weaponDefs = {
		PArtillery = {
			name = "Plasma Artillery",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "weapons\\partyfire",
			soundhit = "weapons\\partyhit",

			turret = true,
			range = 1600,
			weaponvelocity = 500,

			reloadtime = 6,
			accuracy = 500,

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

		KMedium = {
			name = "Medium Kinetic Weapon",
			RGBcolor = "1 .3 .1",
			weaponType = "LaserCannon",
			thickness = 1.5,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .01,

			soundstart = "weapons\\klightfire",
			soundhit = "weapons\\klighthit",

			turret = true,
			range = 700,
			weaponvelocity = 600,
			--FallOffRate=.05;

			reloadtime = .5,
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
				default = 120,
			},
			customParams = {
				spray_boost = 50,
				rof_boost = 48,
			},
		},

		LMedium = { --used by Meteor
			name = "Medium Laser",
			RGBcolor = "1 0 0",
			weaponType = "BeamLaser",
			thickness = 3,
			intensity = 1,
			noselfdamage = true,
			beamttl = 8,
			beamdecay = .8,
			beamburst = true,

			soundstart = "weapons\\lmediumfire",
			soundhit = "",
			minIntensity = 1,

			turret = true,
			range = 550,

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

			laserFlareSize = 8,

			impactonly = true,
			interceptedbyshieldtype = 4, --laser
			damage = {
				default = 120,
			},
		},

		PArtilleryW = {
			name = "Plasma Artillery",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "weapons\\partyfire",
			soundhit = "weapons\\partyhit",

			turret = true,
			range = 1600,
			weaponvelocity = 500,

			reloadtime = 9,
			accuracy = 500,

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
	},

	ExplodeAs = "RetroDeathBig",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,
	Script = "supportcarrier.cob",

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
		--builds=2.0;
		type = "large",
		cost = 8000,
		buildtime = 60,
		occupationStrength = 3,
		nobuild = "true",
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
