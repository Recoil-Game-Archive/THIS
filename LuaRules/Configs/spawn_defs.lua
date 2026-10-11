--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local modoptions = Spring.GetModOptions() or {}

local eggsModifier = 0.8	--unused

--------------------------------------------------------------------------------
-- system

spawnSquare          = 150       -- size of the chicken spawn square centered on the burrow
spawnSquareIncrement = 1         -- square size increase for each unit spawned
burrowName           = "starbase"   -- burrow unit name
maxBurrows           = 50
minBaseDistance      = 700      
maxBaseDistance      = 3500

lagTrigger           = 0.7       -- average cpu usage after which lag prevention mode triggers
triggerTolerance     = 0.05      -- increase if lag prevention mode switches on and off too fast
maxAge               = 10*60      -- chicken die at this age, seconds

alwaysVisible        = false     -- chicken are always visible

alwaysEggs			 = false		--spawn limited-lifespan eggs when not in Eggs mode?
eggDecayTime		 = 180
burrowEggs           = 15       -- number of eggs each burrow spawns

gameMode		= true	--Spring.GetModOption("zkmode")
tooltipMessage	= "Kill chickens and collect their eggs to get metal."

mexes = {
	"starbase",
}
noTarget = {
	probe = true,
	gravdecoy = true,
}

modes = {
    [0] = 0,
	[1] = 'Defenders of the Galaxy: Very Easy',
    [2] = 'Defenders of the Galaxy: Easy',
    [3] = 'Defenders of the Galaxy: Normal',
	[4] = 'Defenders of the Galaxy: Hard',
	[5] = 'Defenders of the Galaxy: Suicidal',
}
defaultDifficulty = modes[2]
testBuilding 	= UnitDefNames["starbase"].id	--testing to place burrow
testBuildingQ 	= UnitDefNames["quasar"].id	--testing to place queen

--------------------------------------------------------------------------------
-- difficulty settings

playerMalus          = 1         -- how much harder it becomes for each additional player, exponential (playercount^playerMalus = malus)	-- used only for burrow spawn rate and queen XP

queenName            = "imperator"
--queenMorphName		 = "quasar"
miniQueenName		 = "quasar"

burrowSpawnRate      = 60        -- higher in games with many players, seconds
chickenSpawnRate     = 59
waveRatio            = 0.6       -- waves are composed by two types of chicken, waveRatio% of one and (1-waveRatio)% of the other
baseWaveSize		 = 1.5		 -- multiplied by malus, 1 = 1 squadSize of chickens
waveSizeMult		 = 1
--forceBurrowRespawn	 = false	-- burrows always respawn even if the modoption is set otherwise        
queenSpawnMult       = 4         -- how many times bigger is a queen hatch than a normal burrow hatch

defensePerWave       = 1	-- number of turrets added to defense pool every wave, multiplied by playercount
defensePerBurrowKill = 1	-- number of turrets added to defense pool for each burrow killed

gracePeriod          = 180       -- no chicken spawn in this period, seconds
gracePenalty		 = 15		-- reduced grace per player over one, seconds
gracePeriodMin		 = 90

queenTime            = 60*60    -- time at which the queen appears, seconds
queenMorphTime		 = {60*30, 120*30}	--lower and upper bounds for delay between morphs, gameframes
queenHealthMod		 = 1
miniQueenTime		= {}		-- times at which miniqueens are spawned (multiplier of queentime)
endMiniQueenWaves	= 7		-- waves per miniqueen in PvP endgame

burrowQueenTime		= 15		-- how much killing a burrow shaves off the queen timer, seconds
burrowWaveSize		= 1.2		-- size of contribution each burrow makes to wave size (1 = 1 squadSize of chickens)
burrowRespawnChance = 0.15
burrowRegressTime	= 40		-- direct tech time regress from killing a burrow, divided by playercount

humanAggroPerBurrow	= 0.5			-- divided by playercount
humanAggroDecay		= 0.25		-- linear rate at which aggro decreases
humanAggroWaveFactor = 0.2
humanAggroWaveMax	= 5
humanAggroDefenseFactor = 0.5	-- turrets issued per point of PAR every wave, multiplied by playercount
humanAggroTechTimeProgress = 20	-- how much to increase chicken tech progress (* aggro), seconds
humanAggroTechTimeRegress = 0	-- how much to reduce chicken tech progress (* aggro), seconds
humanAggroQueenTimeFactor = 1	-- burrow queen time is multiplied by this and aggro (after clamping)
humanAggroQueenTimeMin = 0	-- min value of aggro for queen time calc
humanAggroQueenTimeMax = 8

techAccelPerPlayer	= 4		-- how much tech accel increases per player over one per wave, seconds
techTimeFloorFactor	= 0.5	-- tech timer can never be less than this * real time

scoreMult			= 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Copy(original)   -- Warning: circular table references lead to
  local copy = {}               -- an infinite loop.
  for k, v in pairs(original) do
    if (type(v) == "table") then
      copy[k] = Copy(v)
    else
      copy[k] = v
    end
  end
  return copy
end


local function TimeModifier(d, mod)
  for chicken, t in pairs(d) do
    t.time = t.time*mod
    if (t.obsolete) then
      t.obsolete = t.obsolete*mod
    end
  end
end


local function PickRandomPerk(perkList)
	if perkList == nil then return 2 end
	local key = math.random(1, #perkList)
	return perkList[key]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- times in minutes
local chickenTypes = {
  dagger        =  {time =  0,  squadSize =   3.5, obsolete = 10},
  sword =  {time =  4,  squadSize =   2.2, obsolete = 25},
  claymore       =  {time = 6,  squadSize =   1.6},
  mace       =  {time = 8,   squadSize = 2},
  meteor      =  {time = 9,  squadSize =   0.6},
  longbow       =  {time = 11,  squadSize =   1.35},
  comet   =  {time = 14,  squadSize =  0.3},
  dronelauncherm =  {time = 17,  squadSize =  0.6},
  shuriken	=  {time = 17,  squadSize =  3.5},
  supportcarrier       =  {time = 20,  squadSize = 0.4},
  starslayer       =  {time = 24,  squadSize = 0.2},
}


local defenders = {
  --dagger =  {time =  4,  squadSize =   2.5, obsolete = 15},
  --sword =  {time =  6,  squadSize =   2, obsolete = 22},
  gunstar_cannon = {time = 5, squadSize = 2 },
  gunstar_torpedo = {time = 12, squadSize = 1.0 },
  --shuriken	=  {time = 10,  squadSize =  3, quasiAttacker = true, },
  --dagger  =  {time =  16,  squadSize =  2},
}

local supporters = {
  wraith =  {time = 8, squadSize = 1.8, quasiAttacker = true, },
  warhammer =  {time = 16,  squadSize = 1.4, quasiAttacker = true, },
  carrier = {time = 20, squadSize = 0.2 },  
}

-- TODO
-- cooldown is in waves
local specialPowers = {
}

local function SetCustomMiniQueenTime()
	if modoptions.miniqueentime then
		if modoptions.miniqueentime == 0 then return nil
		else return modoptions.miniqueentime end
	else return 0.6 end
end    
    
difficulties = {
  ['Defenders of the Galaxy: Very Easy'] = {
    chickenSpawnRate = 120, 
    burrowSpawnRate  = 120,
    gracePeriod      = 180,
    waveSizeMult     = 0.9,
    timeSpawnBonus   = .02,     -- how much each time level increases spawn size
	queenName        = "quasar",
	miniQueenName	 = "queencarrier",
	--forceBurrowRespawn = true,
	scoreMult		 = 0.25,
	timeModifier	 = 0.875,
  },
  
  
  ['Defenders of the Galaxy: Easy'] = {
    chickenSpawnRate = 60, 
    burrowSpawnRate  = 75,
    gracePeriod      = 120,
    timeSpawnBonus   = .02,
	queenPerks = {2}, -- extra guns
	queenTurrets = {
		[1] = "imperator_turret_cannon",
		[2] = "imperator_turret_cannon",
		[3] = "imperator_turret_pd",
		[4] = "imperator_turret_pd",
		[6] = "imperator_turret_cannon",
		[8] = "imperator_plasma",
		[9] = "imperator_turret_cannon",
		[11] = "imperator_turret_cannon",
		[12] = "imperator_turret_pd",
		[13] = "imperator_turret_cannon",
		[15] = "imperator_turret_cannon",
		[16] = "imperator_turret_pd",
		[17] = "imperator_turret_cannon",
	},
	techAccelPerPlayer = 4,
	scoreMult		 = 0.66,
  },

  ['Defenders of the Galaxy: Normal'] = {
    chickenSpawnRate = 55, 
    burrowSpawnRate  = 65,
    timeSpawnBonus   = .04,
	miniQueenTime		= {0.6},	
	queenPerks = {2}, -- extra guns
	queenTurrets = {
		[1] = "imperator_turret_cannon",
		[2] = "imperator_turret_cannon",
		[3] = "imperator_turret_pd",
		[4] = "imperator_turret_pd",
		[5] = "imperator_turret_plasma",
		[6] = "imperator_turret_cannon",
		[7] = "imperator_turret_plasma",
		[8] = "imperator_hive",
		[9] = "imperator_turret_cannon",
		[10] = "imperator_turret_am",
		[11] = "imperator_turret_cannon",
		[12] = "imperator_turret_pd",
		[13] = "imperator_turret_cannon",
		[14] = "imperator_turret_am",
		[15] = "imperator_turret_cannon",
		[16] = "imperator_turret_pd",
		[17] = "imperator_turret_cannon",
	},
  },

  ['Defenders of the Galaxy: Hard'] = {
    chickenSpawnRate = 50, 
    burrowSpawnRate  = 60,
    waveSizeMult	 = 1.2,
    timeSpawnBonus   = .04,
	burrowQueenTime  = 75,
	burrowWaveBonus  = 0.75,
	defenderChance   = 0.5,
	queenHealthMod	 = 2,
	miniQueenTime	 = {0.5},
	perks = {PickRandomPerk({10,11,12})}, --EMP missiles, AM torps or grav flak
	queenPerks = {2, 11, 12}, -- extra guns, AM torps, grav flak
	queenSpawnMult       = 3,
	endMiniQueenWaves	= 7,
	
	queenTurrets = {
		[1] = "imperator_turret_am",
		[2] = "imperator_turret_am",
		[3] = "imperator_turret_pd",
		[4] = "imperator_turret_pd",
		[5] = "imperator_hive",
		[6] = "imperator_turret_cannon",
		[7] = "imperator_turret_am",
		[8] = "imperator_hive",
		[9] = "imperator_turret_cannon",
		[10] = "imperator_turret_plasma",
		[11] = "imperator_turret_cannon",
		[12] = "imperator_turret_pd",
		[13] = "imperator_turret_cannon",
		[14] = "imperator_turret_plasma",
		[15] = "imperator_turret_cannon",
		[16] = "imperator_turret_pd",
		[17] = "imperator_turret_cannon",
	},
	techAccelPerPlayer	= 5,
	scoreMult		 = 1.5,
	timeModifier	 = 0.875,	
  },
  
   ['Defenders of the Galaxy: Suicidal'] = {
    chickenSpawnRate = 50, 
    burrowSpawnRate  = 55,
	waveSizeMult	 = 1.2,
    timeSpawnBonus   = .045,
	burrowQueenTime  = 90,
	burrowWaveBonus  = 0.9,
	defenderChance   = 0.6,
	miniQueenTime	 = {0.45},
	perks = {PickRandomPerk({10,11,12}), PickRandomPerk({1,2})}, --EMP missiles, AM torps or grav flak; mass drivers or extra guns
	--queenTime		 = 10,
	queenHealthMod	 = 2,
	queenPerks = {1, 2, 6, 11, 12}, -- mass drivers, extra guns, grav range, AM torps, grav flak
	queenSpawnMult   = 4,
	endMiniQueenWaves	= 7,
	
	queenTurrets = {
		[1] = "imperator_turret_plasma",
		[2] = "imperator_turret_plasma",
		[3] = "imperator_turret_pd",
		[4] = "imperator_turret_pd",
		[5] = "imperator_hive",
		[6] = "imperator_turret_am",
		[7] = "imperator_turret_am",
		[8] = "imperator_hive",
		[9] = "imperator_turret_am",
		[10] = "imperator_turret_plasma",
		[11] = "imperator_hive",
		[12] = "imperator_turret_am",
		[13] = "imperator_turret_plasma",
		[14] = "imperator_turret_plasma",
		[15] = "imperator_hive",
		[16] = "imperator_turret_am",
		[17] = "imperator_turret_plasma",
	},
	
	scoreMult		 = 2,
	timeModifier	 = 0.75,	
  },
}

-- minutes to seconds
TimeModifier(chickenTypes, 60)
TimeModifier(defenders, 60)
TimeModifier(supporters, 60)
TimeModifier(specialPowers, 60)

--[[
for chicken, t in pairs(chickenTypes) do
    t.timeBase = t.time
end
for chicken, t in pairs(supporters) do
    t.timeBase = t.time
end
for chicken, t in pairs(defenders) do
    t.timeBase = t.time
end
]]--

for _, d in pairs(difficulties) do
  d.timeSpawnBonus = (d.timeSpawnBonus or 0)/60
  d.chickenTypes = Copy(chickenTypes)
  d.defenders = Copy(defenders)
  d.supporters = Copy(supporters)
  d.specialPowers = d.specialPowers or Copy(specialPowers)
  
  TimeModifier(d.chickenTypes, d.timeModifier or 1)
  TimeModifier(d.defenders, d.timeModifier or 1)
  TimeModifier(d.supporters, d.timeModifier or 1)
end

defaultDifficulty = 'Defenders of the Galaxy: Normal'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
