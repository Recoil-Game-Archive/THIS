local unitName = "imperator_hive"
local unitDef = {
	Name = "Drone Hive",
	Description = "Drone production and control facility",

	-- Required Tags
	power = 7000,
	mass = 9000,
	icontype = "imperator",
	Category = "LARGE WEAK TARGET ANY CHASE",
	FootprintX = 6,
	FootprintZ = 6,
	MaxDamage = 8000,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "imperator_hive.s3o",
	Side = "ALL",
	--SoundCategory = "CRUISER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "CylY",
	collisionVolumeScales = "44 44 72",
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
			def = "DroneMarker",
			onlyTargetCategory = "TARGET",
		},
	},

	weaponDefs = {
		DroneMarker = {
			name = "Drone Launch Control",
			weaponType = "Melee",

			turret = true,
			range = 1600,
			reloadtime = 8,
			projectiles = 0,

			areaofeffect = 8,

			tolerance = 3000,

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
				torpedotype = 1, -- DRONE
			},
		},
	},

	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathSmall",

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
		cost = 4500,
		buildtime = 90,
		--arc=80;
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
