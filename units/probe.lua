local unitName = "probe"
local unitDef = {
	Name = "Iris",
	Description = "Stealth recon/decoy probe",

	-- Required Tags
	power = 60,
	mass = 75,
	icontype = "probe",
	Category = "SMALL WEAK TARGET ANY",
	FootprintX = 1,
	FootprintZ = 1,
	MaxDamage = 550,
	idleTime = 0,
	idleAutoHeal = 0,
	ObjectName = "probe.s3o",
	Side = "ALL",
	--SoundCategory = "FIGHTER", -- no such category in gamedata/SOUND.TDF, never had any effect
	collisionVolumeType = "CylZ",
	collisionVolumeScales = "12 12 20",
	collisionVolumeTest = true,

	-- Movement
	canFly = true,
	HoverAttack = true,
	AirHoverFactor = 0,
	AirStrafe = false,
	cruiseAlt = 130,
	BrakeRate = 1.5,
	Acceleration = .06,
	CanMove = true,
	MaxVelocity = 1.7,
	TurnRate = 1000,
	collide = false,

	-- Airplane Moventment

	-- Buildings

	-- Construction
	ShowNanoFrame = false,
	LevelGround = false,

	-- Abilities
	CanAttack = true,
	CanStop = true,
	SelfDestructCountdown = 0,
	kamikaze = "true",
	kamikazedistance = 80,
	kamikazeUseLOS = true,

	--canCloak=1;
	minCloakDistance = 100,
	--init_cloaked=1;

	-- Sight/Radar
	RadarDistance = 1400,
	SightDistance = 700,
	noChaseCategory = "NOSHIP",
	stealth = true,

	-- Weapons
	ExplodeAs = "RetroDeathSmall",
	SelfDestructAs = "RetroDeathBig",

	-- Misc
	SmoothAnim = false,
	script = "probe.lua",

	sfxTypes = {
		explosionGenerators = {
			"custom:damage_fire",
			"custom:death_small",
		},
	},
	customParams = {
		type = "probe",
		role = "support",
		cost = 120,
		buildtime = 6,
		occupationStrength = 0,
		luascript = "true",
	},
}

unitDef.unitname = unitName
return lowerkeys({ [unitName] = unitDef })
