local weaponDefs = {
	LPointDefenseM = { --formerly used by Quasar
		name = "Point Defense",
		RGBcolor = "0 0.3 1",
		weaponType = "BeamLaser",
		thickness = 3,
		intensity = 1,
		noselfdamage = true,
		minIntensity = 1,
		beamburst = true,
		beamttl = 16,
		beamdecay = .9,
		size = 2,

		soundstart = "lmediumfire",
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

		impactonly = true,
		interceptedbyshieldtype = 1, --kinetic
		damage = {
			default = 1,
			drone = 45,
			torpedo = 45,
		},
	},
}

return lowerkeys(weaponDefs)
