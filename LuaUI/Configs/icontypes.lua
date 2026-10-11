-- $Id: icontypes.lua 4585 2009-05-09 11:15:01Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    icontypes.lua
--  brief:   icontypes definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local icontypes = {
	default = {
		size=1,
		radiusadjust=1,
	},
  	tiny = {
		bitmap="icons/trinver.tga",
		size=".25",
		radiusadjust=0,
		distance=0.5,	-- Multiplier for the distance at which unit turns into icon
	},
	--small ships
	dagger = {
		bitmap="icons/dagger.png",
		size=1.0,
		radiusadjust=0,
		distance=.6,
	},
	sword = {
		bitmap="icons/sword.png",
		size=1.2,
		radiusadjust=0,
		distance=.6,
	},	
	mace = {
		bitmap="icons/mace.png",
		size=1.2,
		radiusadjust=0,
		distance=.6,
	},		
	claymore = {
		bitmap="icons/claymore.png",
		size=1.3,
		radiusadjust=0,
		distance=.6,
	},		
	longbow = {
		bitmap="icons/longbow.png",
		size=1.3,
		radiusadjust=0,
		distance=.6,
	},	
	warhammer = {
		bitmap="icons/warhammer.png",
		size=1.4,
		radiusadjust=0,
		distance=.6,
	},	
	probe = {
		bitmap="icons/probe.png",
		size=1.0,
		radiusadjust=0,
		distance=.6,
	},
	wraith = {
		bitmap="icons/wraith.png",
		size=1.2,
		radiusadjust=0,
		distance=.6,
	},	
	chukenu = {
		bitmap="icons/chukenu.png",
		size=1.3,
		radiusadjust=0,
		distance=.6,
	},
	shuriken = {
		bitmap="icons/shuriken.png",
		size=1.2,
		radiusadjust=0,
		distance=.6,
	},	
	
	--gunstars
	defense = {
		bitmap="icons/defense.png",
		size=1.0,
		radiusadjust=0,
		distance=.6,
	},
	defenseheavy = {
		bitmap="icons/defenseheavy.png",
		size=1.2,
		radiusadjust=0,
		distance=.6,
	},	
	
	--big ships
	carrier = {
		bitmap="icons/carrier.tga",
		size=1,
		radiusadjust=1,
		distance=.8,
	},
	supportcarrier = {
		bitmap="icons/supportcarrier.tga",
		size=1,
		radiusadjust=1,
		distance=.8,
	},
	comet = {
		bitmap="icons/comet.tga",
		size=1,
		radiusadjust=1,
		distance=.8,
	},
	starslayer = {
		bitmap="icons/starslayer.tga",
		size=1,
		radiusadjust=1,
		distance=.8,
	},
	beacon = {
		bitmap="icons/beacon.tga",
		size=4,
		radiusadjust=0,
		distance=0,
	},
	meteor = {
		bitmap="icons/meteor.tga",
		size=1,
		radiusadjust=1,
		distance=0.6,
	},
	quasar =	{
		bitmap="icons/quasar.tga",
		size=1,
		radiusadjust=1,
		distance=1,
	},
	imperator =	{
		bitmap="icons/imperator.tga",
		size=1,
		radiusadjust=1,
		distance=9000,
	},	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return icontypes

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

