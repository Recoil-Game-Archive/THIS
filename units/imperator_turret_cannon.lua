local unitName = "imperator_turret_cannon"
local unitDef = {
	Name = "Battle Cannon",
	Description = "Heavy kinetic weapon, omni-directional coverage",

	-- Required Tags
	power = 2000,
	mass = 9000,
	icontype = "imperator",
	Category = "LARGE STRONG TARGET ANY CHASE",
	FootprintX = 4,
	FootprintZ = 4,
	MaxDamage = 15000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_turret_cannon.s3o",
	Side = "ALL",
	--SoundCategory = "CRUISER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "48 64 48",
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
	noChaseCategory = "NOCHASE",
	stealth = true,

	-- Weapons
	weapons = {
		{
			def = "KHeavy",
			onlyTargetCategory = "TARGET",
		},
		{
			def = "PMedium",
			onlyTargetCategory = "TARGET",
			--badTargetCategory = "LARGE",
		},
	},

	weaponDefs = {
		KHeavy = { --Imperator cannon
			name = "Heavy Kinetic Weapon Plasma", -- TODO: parameterise breakStealth
			RGBcolor = "1 .3 .1",
			weaponType = "LaserCannon",
			thickness = 4,
			intensity = 1,
			noselfdamage = true,
			impactOnly = true,
			duration = .02,

			soundstart = "weapons\\kheavyfire",
			soundhit = "weapons\\kheavyhit",

			turret = true,
			range = 600,
			weaponvelocity = 1800,
			--FallOffRate=.05;

			reloadtime = 3,
			--burst=2;
			--burstrate=.1;
			sprayangle = 600,

			areaofeffect = 24,
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

			interceptedbyshieldtype = 1, --kinetic
			damage = {
				default = 1200,
			},
			customParams = {
				spray_boost = 10,
				rof_boost = 96,
			},
		},

		PMedium = {
			name = "Medium Plasma Cannon",
			RGBcolor = "1 1 1",
			weaponType = "LaserCannon",
			thickness = 6,
			intensity = 1,
			noselfdamage = true,
			duration = .1,
			texture1 = "plasma",
			texture2 = "null",
			corethickness = 0,

			soundstart = "weapons\\pmediumfire",
			soundhit = "weapons\\pmediumhit",

			turret = true,
			range = 700,
			weaponvelocity = 400,

			reloadtime = 2,
			sprayangle = 100,

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
				default = 250,
				large = 500,
				magsmall = 72.5,
				maglarge = 125,
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
			"custom:muzzlekineticlarge",
			"custom:muzzlemassdriverlarge",
		},
	},

	customParams = {
		type = "turret",
		cost = 600,
		buildtime = 40,
		moreguns = 2,
		headingaim1 = 40,
		pitchaim1 = 20,
		firestealthtime = 1500,
		barrelrecoilsleep = 300,
		barrelrecoildist = 20,
		barrelrecoilspeed = 100,
		barrelreturnspeed = 10,
		headingaim2 = 270,
		pitchaim2 = 200,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
