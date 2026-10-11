local unitName = "imperator_turret_plasma"
local unitDef = {
	Name = "Plasma Cannon",
	Description = "Artillery plasma weapon",

	-- Required Tags
	power = 7000,
	mass = 9000,
	icontype = "imperator",
	Category = "LARGE STRONG TARGET ANY CHASE",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 15000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_turret_plasma2.s3o",
	Side = "ALL",
	--SoundCategory = "CRUISER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "Box",
	collisionVolumeScales = "96 56 96",
	collisionVolumeOffset = "0 30 0",
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
			def = "PArtilleryQF",
			onlyTargetCategory = "TARGET",
			mainDir = "0 0 1",
			maxAngleDif = 80,
		},
	},

	weaponDefs = {
		PArtilleryQF = {
			name = "Plasma Artillery Quad Fast",
			RGBcolor = "1 .7 .2",
			weaponType = "Cannon",
			noselfdamage = true,
			burnblow = true,
			myGravity = .001,
			texture1 = "null",

			soundstart = "weapons\\partyfire",
			soundhit = "weapons\\partyhit",

			turret = true,
			range = 2100,
			weaponvelocity = 500,

			reloadtime = 6,
			accuracy = 200,
			sprayangle = 400,
			burst = 4,
			burstrate = .3,
			--projectiles=2;

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
		cost = 3000,
		buildtime = 60,
		arc = 80,
		headingaim1 = 30,
		pitchaim1 = 20,
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
