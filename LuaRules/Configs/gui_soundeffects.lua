--------------------------------------------------------------------------------
-- Config for LuaRules/Gadgets/gui_soundeffects.lua
--
-- Every sound here is the name of a file below sounds/, without folder or
-- extension (gamedata/sounds.lua explains the naming). A sound can also be a
-- list of names, { "sel_light", "sel_light2" }, to pick one at random.
--
-- A name without a file is skipped and listed in infolog.txt when the game
-- loads, so this file doubles as the list of sounds that still have to be
-- made. sounds/README.md describes each of them.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Order sounds: played flat on the interface channel when the selection is
-- given an order. { sound, volume }
--------------------------------------------------------------------------------

CommandSoundEffects = {}

local function Command(cmdID, sound, volume)
	if cmdID then
		CommandSoundEffects[cmdID] = { sound, volume or 0.1 }
	end
end

Command(CMD.MOVE,       'cmd_move')
Command(CMD.ATTACK,     'cmd_attack')
Command(CMD.FIGHT,      'cmd_fight')
Command(CMD.PATROL,     'cmd_patrol')
Command(CMD.GUARD,      'cmd_guard')
Command(CMD.STOP,       'cmd_stop')
Command(CMD.WAIT,       'cmd_wait')
Command(CMD.REPEAT,     'cmd_repeat')
Command(CMD.SELFD,      'cmd_selfd')
Command(CMD.MANUALFIRE, 'cmd_manualfire') -- Quasar: fire the mega laser
Command(31416,          'cmd_turn')       -- CMD_TURN, unit_turn.lua: large ships turn in place
Command(35126,          'cmd_empbomb')    -- CMD_EMPBOMB, wpn_meteoremp.lua: Meteor EMP bomb

--------------------------------------------------------------------------------
-- Unit sounds
--
-- Every unit is described by three sounds that are played on top of each
-- other, so a small set of base sounds gives each unit its own voice:
--
--   BaseSoundSelectType    what kind of hull it is
--   BaseSoundMovementType  what kind of drive it has
--   BaseSoundWeaponType    what it is armed with
--
--   when                      select  movement  weapon
--   selected                   0.35      -       0.7
--   given an order               -      0.8      0.2
--   finished (leaves the yard)  0.8      -       0.2
--
-- Allied units in view play the same layers more quietly.
--
-- Optional, per unit:
--   Move               replaces cmd_move for this unit
--   BaseSoundActivate / BaseSoundDeactivate   played when the unit is switched
--                      on or off (engine on/off state)
--
-- Units without an entry are silent: drones, torpedoes, the EMP bomb, the
-- grav decoy and planets are left out on purpose.
--------------------------------------------------------------------------------

local function Unit(select, movement, weapon)
	return {
		BaseSoundSelectType = select,
		BaseSoundMovementType = movement,
		BaseSoundWeaponType = weapon,
	}
end

GUIUnitSoundEffects = {

	-- Small ships
	dagger         = Unit('sel_light',   'mov_light',   'wpn_kinetic'),      -- Dagger: light ship, dual kinetics
	sword          = Unit('sel_medium',  'mov_medium',  'wpn_missile'),      -- Sword: missiles and kinetics
	mace           = Unit('sel_medium',  'mov_medium',  'wpn_laser'),        -- Mace: mag-shield and lasers
	claymore       = Unit('sel_medium',  'mov_medium',  'wpn_plasma'),       -- Claymore: plasma cannon
	longbow        = Unit('sel_medium',  'mov_medium',  'wpn_torpedo'),      -- Longbow: torpedo ship
	wraith         = Unit('sel_medium',  'mov_medium',  'wpn_pointdefense'), -- Wraith: point defense
	warhammer      = Unit('sel_medium',  'mov_stealth', 'wpn_missile'),      -- Warhammer: cloaked missile ship
	dronelauncherm = Unit('sel_medium',  'mov_medium',  'wpn_drone'),        -- Crossbow: drone launcher
	probe          = Unit('sel_probe',   'mov_stealth', 'wpn_sensor'),       -- Iris: recon/decoy probe
	shuriken       = Unit('sel_torpedo', 'mov_light',   'wpn_torpedo'),      -- Shuriken: large smart torpedo

	-- Defenses
	gunstar_cannon  = Unit('sel_gunstar', 'mov_static', 'wpn_kinetic'),      -- Cannon Gunstar
	gunstar_torpedo = Unit('sel_gunstar', 'mov_static', 'wpn_torpedo'),      -- Torpedo Gunstar
	lasermine       = Unit('sel_gunstar', 'mov_static', 'wpn_laser'),        -- Flash Mine
	starbase        = Unit('sel_station', 'mov_static', 'wpn_kinetic'),      -- Starbase

	-- Frigates and cruisers
	meteor     = Unit('sel_frigate', 'mov_heavy',  'wpn_pointdefense'),      -- Meteor: anti-fighter frigate
	minelayer  = Unit('sel_frigate', 'mov_heavy',  'wpn_support'),           -- Ring: minelayer frigate
	comet      = Unit('sel_cruiser', 'mov_medium', 'wpn_plasma'),            -- Comet: fast attack destroyer
	starslayer = Unit('sel_cruiser', 'mov_heavy',  'wpn_artillery'),         -- Starslayer: plasma artillery cruiser
	eclipse    = Unit('sel_cruiser', 'mov_heavy',  'wpn_beam'),              -- Eclipse: command cruiser, graser

	-- Carriers
	carrier        = Unit('sel_carrier', 'mov_heavy',   'wpn_support'),      -- Fleet Carrier
	supportcarrier = Unit('sel_carrier', 'mov_heavy',   'wpn_artillery'),    -- Battle Carrier
	queencarrier   = Unit('sel_carrier', 'mov_capital', 'wpn_artillery'),    -- Advanced Battle Carrier
	stealthcarrier = Unit('sel_carrier', 'mov_stealth', 'wpn_support'),      -- Stealth Carrier

	-- Capital ships
	quasar    = Unit('sel_capital', 'mov_capital', 'wpn_beam'),              -- Quasar: assault battlecruiser
	imperator = Unit('sel_capital', 'mov_capital', 'wpn_support'),           -- Imperator: turret platform

	-- Imperator modules
	imperator_hardpoint     = Unit('sel_module', 'mov_static', nil),                -- empty hardpoint
	imperator_turret_cannon = Unit('sel_module', 'mov_static', 'wpn_kinetic_heavy'), -- Battle Cannon
	imperator_turret_plasma = Unit('sel_module', 'mov_static', 'wpn_artillery'),    -- Plasma Cannon
	imperator_turret_am     = Unit('sel_module', 'mov_static', 'wpn_beam'),         -- Antimatter Beam
	imperator_turret_pd     = Unit('sel_module', 'mov_static', 'wpn_pointdefense'), -- Point Defense
	imperator_hangar        = Unit('sel_module', 'mov_static', 'wpn_support'),      -- Hangar
	imperator_hive          = Unit('sel_module', 'mov_static', 'wpn_drone'),        -- Drone Hive

}
