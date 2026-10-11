--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- swarm arrays
-- these are not strictly required they just help with inputting the units


local shortRangeSwarmieeArray = { 
	"claymore",
}

local medRangeSwarmieeArray = { 
	"claymore",
}

local longRangeSwarmieeArray = { 

}

-- skirm arrays
-- these are not strictly required they just help with inputting the units

local longRangeSkirmieeArray = {
	"comet",
	"meteor",
	"quasar",
	"imperator_hardpoint",
}

local medRangeSkirmieeArray = {
	
}

local shortRangeSkirmieeArray = {
	
}

local fleeables = {
	"meteor",
	"comet",
	"starbase",
	"quasar",
	"imperator",
	"imperator_turret_cannon",
	"imperator_turret_am",
	"imperator_hive",
}


-- searchRange(defaults to 800): max range of GetNearestEnemy for the unit.
-- defaultAIState (defaults to 1): (1 or 0) state of AI when unit is initialised

--*** skirms(defaults to empty): the table of units that this unit will attempt to keep at max range
-- skirmEverything (defaults to false): Skirms everything (does not skirm radar with this enabled only)
-- skirmLeeway: (Weapon range - skirmLeeway) = distance that the unit will try to keep from units while skirming
-- stoppingDistance (defaults to 0): (skirmLeeway - stoppingDistance) = max distance from target unit that move commands can be given while skirming
-- skirmRadar (defaults to false): Skirms radar dots
-- skirmOrderDis (defaults to 120): max distance the move order is from the unit when skirming


--*** swarms(defaults to empty): the table of units that this unit will jink towards and strafe
-- maxSwarmLeeway (defaults to Weapon range): (Weapon range - maxSwarmLeeway) = Max range that the unit will begin strafing targets while swarming
-- minSwarmLeeway (defaults to Weapon range): (Weapon range - minSwarmLeeway) = Range that the unit will attempt to move further away from the target while swarming
-- jinkTangentLength (default in config): component of jink vector tangent to direction to enemy
-- jinkParallelLength (default in config): component of jink vector parallel to direction to enemy
-- circleStrafe (defaults to false): when set to true the unit will run all around the target unit, false will cause the unit to jink back and forth
-- minCircleStrafeDistance (default in config): (weapon range - minCircleStrafeDistance) = distance at which the circle strafer will attempt to move away from target
-- strafeOrderLength (default in config): length of move order while strafing
-- swarmLeeway (defaults to 50): adds to enemy range when swarming
-- swarmEnemyDefaultRange (defaults to 800): range of the enemy used if it cannot be seen.
-- alwaysJinkFight (defaults to false): If enabled the unit with jink whenever it has a fight command


--*** flees(defaults to empty): the table of units that this unit will flee like the coward it is!!!
-- fleeCombat (defaults to false): if true will flee everything without catergory UNARMED
-- fleeLeeway (defaults to 100): adds to enemy range when fleeing
-- fleeDistance (defaults to 100): unit will flee to enemy range + fleeDistance away from enemy
-- fleeRadar (defaults to false): does the unit flee radar dots?
-- minFleeRange (defaults to 0): minumun range at which the unit will flee, will flee at higher range if the attacking unit outranges it
-- fleeOrderDis (defaults to 120): max distance the move order is from the unit when fleeing


--- Array loaded into gadget 
local behaviourConfig = { 
	
	defaultJinkTangentLength = 80,
	defaultJinkParallelLength = 150,
	defaultStrafeOrderLength = 100,
	defaultMinCircleStrafeDistance = 40,
	
	-- skirms
	["dronelauncherm"] = {
		skirms = longRangeSkirmieeArray, 
		flees = {},
		skirmLeeway = -50, 
	},
	-- cowardly support units
	["wraith"] = {
		skirms = {}, 
		swarms = {}, 
		flees = fleeables,
		--fleeCombat = true,
		fleeLeeway = 100,
		fleeDistance = 100,
		minFleeRange = 300,
	},
}

return behaviourConfig

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
