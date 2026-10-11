local weaponDefs = {
	PDrone = {
		name = "Plasma Pulser",
		RGBcolor = ".2 .2 1",
		weaponType = "Cannon",
		noselfdamage = true,
		burnblow = true,
		myGravity = .001,
		size = 1,

		soundstart = "weapons\\pmediumfire",
		soundhit = "weapons\\pmediumhit",

		turret = true,
		range = 250,
		weaponvelocity = 900,

		reloadtime = 5,
		burst = 4,
		burstrate = .25,
		accuracy = 1500,

		areaofeffect = 32,
		collidefriendly = false,
		avoidfriendly = false,
		collidefeature = false,
		avoidfeature = false,

		tolerance = 3000,

		impulsefactor = 0,
		impulseBoost = 0,
		craterMult = 0,
		craterBoost = 0,

		explosiongenerator = "custom:smallplasma",
		explosionSpeed = 65536,

		interceptedbyshieldtype = 16, --plasma
		damage = {
			default = 50,
			magsmall = 12.5,
			large = 100,
			maglarge = 25,
		},
	},

	PLight = {
		name = "Light Plasma Cannon",
		RGBcolor = "1 1 1",
		weaponType = "LaserCannon",
		thickness = 1,
		intensity = 1,
		noselfdamage = true,
		duration = .02,
		texture1 = "plasma",
		texture2 = "null",
		corethickness = 0,

		soundstart = "weapons\\pmediumfire",
		soundhit = "weapons\\pmediumhit",

		turret = true,
		range = 400,
		weaponvelocity = 700,

		reloadtime = .3,
		sprayangle = 400,

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
			default = 30,
			large = 60,
			magsmall = 7.5,
			maglarge = 15,
		},
	},
}

return lowerkeys(weaponDefs)
