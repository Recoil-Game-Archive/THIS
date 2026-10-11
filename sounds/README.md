# Sounds

Every `.wav` / `.ogg` below this folder becomes a sound named after the file:
lowercase, no folder, no extension. `sounds/weapons/klightfire.wav` is
`klightfire` everywhere (weapon defs, gadget configs, `Spring.PlaySoundFile`).

- A file name may only be used **once** in the whole tree. Duplicates are
  reported in `infolog.txt` and the first one wins.
- The folder decides the mix (gain, how many copies may overlap, distance
  falloff). Those settings are in `gamedata/sounds.lua`.
- A sound that is configured but has no file is skipped, not an error. Each
  gadget prints what it is still missing in `infolog.txt` when the game loads
  (search for `[GUI Sound Effects]`, `[Death Sounds]`, `[Impact Sounds]`).

| Folder | What goes in it | Played by |
| --- | --- | --- |
| `commands/` | order acknowledgements, `cmd_*` | `gui_soundeffects` |
| `unitselections/` | unit voice layers, `sel_*` `mov_*` `wpn_*` | `gui_soundeffects` |
| `deathsounds/<class>/` | unit deaths, any file names | `unit_death_sounds` |
| `impacts/<class>/` | hull hits, any file names | `unit_impact_sounds` |
| `weapons/`, `weaponsloud/` | weapon fire and hit (`soundStart` / `soundHit`) | engine |
| `explosions/` | explosions that belong to a weapon | engine |
| `ui/` | interface, chat, map pings | engine / widgets |
| `misc/` | one-off unit effects | scripts |

---

# Sounds to make

## 1. Orders: `commands/` (12)

Short, flat interface blips. Played once per order on the interface channel,
underneath the unit's own acknowledgement (section 2).

| File | Order |
| --- | --- |
| `cmd_move` | Move |
| `cmd_attack` | Attack |
| `cmd_fight` | Fight (attack-move) |
| `cmd_patrol` | Patrol |
| `cmd_guard` | Guard |
| `cmd_stop` | Stop |
| `cmd_wait` | Wait |
| `cmd_repeat` | Repeat on/off |
| `cmd_selfd` | Self destruct |
| `cmd_manualfire` | Quasar: fire the mega laser |
| `cmd_turn` | Large ships: turn in place |
| `cmd_empbomb` | Meteor: EMP bomb |

## 2. Unit voices: `unitselections/` (29)

Each unit is three base sounds played on top of each other: what hull it is,
what drive it has, what it is armed with. 29 base sounds give all 32 units a
combination of their own. The assignment is in
`LuaRules/Configs/gui_soundeffects.lua`.

| When | Hull `sel_` | Drive `mov_` | Armament `wpn_` |
| --- | --- | --- | --- |
| Selected | 0.35 | | 0.7 |
| Given an order | | 0.8 | 0.2 |
| Leaves the yard | 0.8 | | 0.2 |

So: `sel_` carries "unit ready" and sits under the weapon layer on selection,
`mov_` is the main acknowledgement, and `wpn_` is the loud layer on selection
and a quiet tail on everything else.

### Hull (11)

| File | Used by |
| --- | --- |
| `sel_light` | Dagger |
| `sel_medium` | Sword, Mace, Claymore, Longbow, Wraith, Warhammer, Crossbow |
| `sel_probe` | Iris |
| `sel_torpedo` | Shuriken |
| `sel_gunstar` | Cannon Gunstar, Torpedo Gunstar, Flash Mine |
| `sel_station` | Starbase |
| `sel_frigate` | Meteor, Ring |
| `sel_cruiser` | Comet, Starslayer, Eclipse |
| `sel_carrier` | Fleet Carrier, Battle Carrier, Advanced Battle Carrier, Stealth Carrier |
| `sel_capital` | Quasar, Imperator |
| `sel_module` | Imperator hardpoint, turrets, Hangar, Drone Hive |

### Drive (6)

| File | Used by |
| --- | --- |
| `mov_light` | Dagger, Shuriken |
| `mov_medium` | Sword, Mace, Claymore, Longbow, Wraith, Crossbow, Comet |
| `mov_heavy` | Meteor, Ring, Starslayer, Eclipse, Fleet Carrier, Battle Carrier |
| `mov_capital` | Quasar, Imperator, Advanced Battle Carrier |
| `mov_stealth` | Warhammer, Iris, Stealth Carrier |
| `mov_static` | Gunstars, Flash Mine, Starbase, all Imperator modules |

### Armament (12)

| File | Used by |
| --- | --- |
| `wpn_kinetic` | Dagger, Cannon Gunstar, Starbase |
| `wpn_kinetic_heavy` | Battle Cannon |
| `wpn_missile` | Sword, Warhammer |
| `wpn_laser` | Mace, Flash Mine |
| `wpn_pointdefense` | Wraith, Meteor, Point Defense turret |
| `wpn_plasma` | Claymore, Comet |
| `wpn_artillery` | Starslayer, Battle Carrier, Advanced Battle Carrier, Plasma Cannon |
| `wpn_torpedo` | Longbow, Shuriken, Torpedo Gunstar |
| `wpn_beam` | Eclipse, Quasar, Antimatter Beam |
| `wpn_drone` | Crossbow, Drone Hive |
| `wpn_sensor` | Iris |
| `wpn_support` | Ring, Fleet Carrier, Stealth Carrier, Imperator, Hangar |

Any of these can become a list of variations later
(`{ 'sel_medium', 'sel_medium2' }`) without touching the gadget.

## 3. Deaths: `deathsounds/<class>/`

Drop any number of files into a class folder; the file names do not matter.
The gadget cycles through all of them before repeating and never plays the
same one twice in a row, so 4 to 6 variations per class is a good target.

The files in there now are the old THIS explosions, as placeholders.

| Class | Units | Has now |
| --- | --- | --- |
| `small` | all small ships, Iris, Shuriken, gunstars, Flash Mine | 2 |
| `medium` | Imperator turrets, Hangar, Drone Hive | 1 |
| `large` | frigates, cruisers, carriers, Starbase | 3 |
| `huge` | Quasar, Imperator | 1 |

A unit picks its class with `customParams.death_sounds`; without it the class
comes from the unit's type (`gamedata/unitdefs_post.lua`). `none` is silent
and is what torpedoes, drones and hardpoints use.

## 4. Hull hits: `impacts/<class>/`

Same idea: any number of files per class, picked at random on every hit.
3 to 5 short variations per class. All of these folders are empty.

| Class | Weapons |
| --- | --- |
| `kinetic` | all light and medium kinetic guns |
| `kinetic_heavy` | Battle Cannon, Eclipse hull cannon |
| `plasma` | plasma cannons, plasma flak |
| `artillery` | plasma artillery |
| `missile` | all missiles |
| `torpedo` | torpedo warheads |
| `antimatter` | antimatter warheads |
| `generic` | fallback for everything else and for any class that is still empty |

A weapon picks its class with `customParams.impact_sounds`; without it the
class comes from its explosion effect (`gamedata/weapondefs_post.lua`). Beam
weapons (lasers, grasers, gravitrics) have no impact sound, they hit every
frame.

These play in addition to the weapon's own `soundHit`. For the kinetic guns
both land at the same moment, so once `impacts/kinetic/` is filled you will
probably want to empty `soundHit` on them.

## 5. Weapons: `weapons/`

Referenced by the defs but missing:

| File | Used by |
| --- | --- |
| `mlighthit` | hit sound of every missile and every torpedo warhead |
| `mtinyfire` | Drone missile launch |

Silent right now, no sound assigned in the defs:

| What | Where |
| --- | --- |
| Torpedo launch | Longbow, Torpedo Gunstar, Starbase, carriers, Comet, Eclipse, Quasar |
| Drone launch | Crossbow, Drone Hive |
| Grav flak firing | Comet, Fleet Carrier, Antimatter Beam, Quasar |
| Imperator death weapon | the death class `huge` covers it |

Shared, and worth splitting when you get to them:

| File | Used by |
| --- | --- |
| `klightfire` / `klighthit` | every kinetic gun from the Dagger to the Quasar (7 weapons) |
| `pmediumfire` / `pmediumhit` | light, medium and heavy plasma, plasma flak |
| `partyfire` / `partyhit` | all plasma artillery |
| `mlightfire`, `mlightfire2` | medium / light missile racks |
| `llightfire` | light lasers |
| `llightfire2` | all point defense |
| `lmediumfire` | medium and heavy lasers, Flash Mine |
| `kheavyfire` / `kheavyhit` | Battle Cannon, Eclipse hull cannon |
| `graserfire` | Quasar and Eclipse graser |
| `ambeamfire` | Antimatter Beam, Quasar mega laser |
| `grav` | gravitrics |
| `deathmed` | EMP bomb and Shuriken warhead detonation (borrowed from the death sounds) |

`klightfire2` and `klighthit2` exist but nothing uses them.

## 6. Interface: `ui/`

The engine plays these three by itself as soon as the file exists:

| File | When |
| --- | --- |
| `chat` | a chat message arrives |
| `multiselect` | several units are selected at once |
| `mappoint` | somebody places a map marker |

`beep4`, `beep6` and `button9` are the old THIS interface sounds; nothing
plays them at the moment.

## Not hooked up yet

These orders never reach the sound gadget, because the gadgets that own them
swallow the command: build and cancel in the fleet yard, placing a large ship,
rally point, repeat queue, the toggles (Longbow volley fire) and the Iris grav
decoy. Button clicks in the interface are silent too.
