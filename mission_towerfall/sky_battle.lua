-- The Cabal command ship (bubble 8, region 64): Holliday drops the player on the hull, the
-- console that drops the entry shield, the damaged hall, the deck and its dropship, the ship's
-- inside down to the shield generator, its three turbines, and the escape to the outro.
-- The beats and their delays follow Homecoming 0.4.0's sky battle script, which was its first
-- pass: the volumes it read on exit are read on the next volume in here, and its unidentified
-- lines are given the cues that fit.
local shared = require("mission_towerfall.shared")
local Slot, Squad, TaskGroup, Directive = shared.Slot, shared.Squad, shared.TaskGroup,
    shared.Directive
local scenes, cue = shared.scenes, shared.cue
local unit, line = shared.unit, shared.line

local sky_battle = {}

sky_battle.legs = {
    -- The boarding cutscene lands here, on the ship's authored default spawn.
    {id = "ship", state = shared.states.ship, spawn_set = 0x2EA8FB98, arm = {
        Slot.PT_DAMAGED, Slot.PT_DAMAGED_HALL, Slot.PT_DAMAGED_HALL_STAIRS,
        Slot.PT_DAMAGED_HALL_STAIRS_DOOR, Slot.PT_DECK_START, Slot.PT_DECK_MID,
        Slot.PT_DECK_HARDPOINT, Slot.PT_DECK_DOOR, Slot.PT_AIRLOCK, Slot.PT_SKYBATTLE_NAVMODE_2B, Slot.PT_ENGINE_ROOM_LOWER, Slot.PT_DESTROY_BATTLESHIP,
        Slot.PT_ESCAPE_EXPLOSION_A_80B508F4, Slot.PT_ESCAPE_EXPLOSION_B_80B508F4,
        Slot.PT_GOTO_END,
    }},
}

-- The ship's combat objectives: the hull and the damaged hall on one, the deck and the inside on
-- another, the deck boss on its own. Every squad takes the task group that costs the least.
local DAMAGED, DAMAGED_GROUPS = Slot.OBJ_DAMAGED, TaskGroup.OBJ_DAMAGED
local DECK, DECK_GROUPS = Slot.OBJ_DECK, TaskGroup.OBJ_DECK
local ULTRA, ULTRA_GROUPS = Slot.OBJ_DECK_ULTRA, TaskGroup.OBJ_DECK_ULTRA

local TURBINES = {Slot.SHIELD_GENERATOR_A, Slot.SHIELD_GENERATOR_B, Slot.SHIELD_GENERATOR_C}
-- The turbines' own devices spin them; the column's collar and core, the generator, the heat
-- sinks and the vents sit inert until driven. They all run as the room's inner door opens. The
-- column's energy beam of the original is not among them: no object, device lane, hop-on or
-- toggle of the registry brings it up.
local TURBINE_DEVICES = {
    Slot.D_SHIELD_GENERATOR_A, Slot.D_SHIELD_GENERATOR_B, Slot.D_SHIELD_GENERATOR_C,
}
--- The fall of `count` turbine devices: hit, then settled, each lighting its own panel. A device
--- driven up stops reporting a little short of one at times, so the top is read from 0.9.
local function turbines_down(count)
    return {slots = TURBINE_DEVICES, from = 0.9, below = 0.5, rest = 0.4, count = count, open = {
        [Slot.D_SHIELD_GENERATOR_A] = Slot.D_GEN_A_LIGHTS,
        [Slot.D_SHIELD_GENERATOR_B] = Slot.D_GEN_B_LIGHTS,
        [Slot.D_SHIELD_GENERATOR_C] = Slot.D_GEN_C_LIGHTS,
    }}
end
local GENERATOR_ROOM = {
    Slot.D_SHIP_DOOR_ENTER, TURBINE_DEVICES[1], TURBINE_DEVICES[2], TURBINE_DEVICES[3],
    Slot.D_SHIELD_GEN_COLLAR, Slot.D_SHIELD_GEN_CORE, Slot.D_SHIELD_GEN_B,
    Slot.D_HEAT_SINK_GLOWS, Slot.D_VENTS_A, Slot.D_VENTS_B, Slot.D_VENTS_C,
}

-- The shells hitting the ship's shield: each impact is an object and the device that fires it,
-- authored in groups along the way. A group goes off one impact at a time, spread over its zone.
local function impacts(...)
    local names, items = {...}, {}
    for index, name in ipairs(names) do
        items[index] = {after_ms = index == 1 and 500 or 900,
            objects = {slots = {Slot["O_SHIELD_IMPACT_FX_" .. name]}},
            move = {to = "open", slots = {Slot["D_SHIELD_IMPACT_FX_" .. name]}}}
    end
    return items
end

sky_battle.steps = {
    -- "Board the command ship" stays until the first goal here.
    {id = "goto_ship", ends = {region = "ship"}},
    -- The ship's music (section 13) starts with the landing. The Hawk is an object and its
    -- movement device, like the hangar carriers: put in place, then driven so it pulls away as
    -- Holliday speaks. The drop-pod launcher across the gap is the same pair. The three
    -- Legionaries by the hologram are the first encounter.
    {id = "landing", barrier = true, ends = {sequence = true}, sequence = {
        {after_ms = 1000, music = 13, objects = {slots = {Slot.HAWK, Slot.DROP_POD_LAUNCH}},
            move = {to = "open", slots = {Slot.D_DROP_POD_LAUNCH}}},
        {after_ms = 1000, move = {to = "open", slots = {Slot.D_HAWK}}, lines = {line(cue.CUE_77)}},
        {after_ms = 8000},
    }},
    -- The goal lands as her line ends. The three are dead by the objective's count, or once none
    -- is alive, since the client loses a member at times.
    {id = "shields", barrier = true, directive = Directive.DISABLE_THE_SHIELDS,
        ends = {kills = {objective = DAMAGED, count = 3}, clear = "pods"}},
    -- The hologram's Ghost scan is skipped: arrived from the boulevard, the client plays it but
    -- reports none of it, whenever its link is armed. Two seconds after the three are dead the
    -- Ghost asks for the console, the console runs and the two energy doors give way.
    {id = "console", barrier = true, ends = {sequence = true}, sequence = {
        {after_ms = 2000, lines = {line(cue.CUE_78)},
            move = {to = "open", slots = {Slot.D_CABAL_CONSOLE}}},
        {after_ms = 500, lines = {line(cue.CUE_79)},
            move = {to = "open", slots = {Slot.D_SHIP_POD_DOOR_A, Slot.D_SHIP_POD_DOOR_B}}},
        -- The energy doors did not answer a move; they are powered down as well.
        {after_ms = 200,
            move = {to = "power_off", slots = {Slot.D_SHIP_POD_DOOR_A, Slot.D_SHIP_POD_DOOR_B}}},
    }},
    -- The way in: the damaged hall, the deck, the airlock, the shield room, down to the
    -- generator. Its fights are the encounters below.
    {id = "hall", directive = Directive.REACH_THE_SHIELD_GENERATOR,
        ends = {trigger = Slot.PT_DESTROY_BATTLESHIP}},
    -- The generator room, put in place as its door opens (the engine room encounter). Nothing
    -- typed reports a turbine's destruction, but its device, driven to full, drops
    -- at the first hit and settles a little higher once destroyed: the counter goal counts the
    -- settled ones, one line each, and each lights its own panel. The heat sinks stop glowing
    -- once the second turbine is gone. The room's fire hazard hop-on burns the players for good
    -- and does nothing on the generator, so it stays out.
    {id = "overload", barrier = true, directive = Directive.EXHAUST_TURBINES_DESTROYED,
        progress = {0, 3}, lines = {line(cue.CUE_86)},
        ends = {fell = turbines_down(1)}},
    {id = "overload_2", barrier = true, directive = Directive.EXHAUST_TURBINES_DESTROYED,
        progress = {1, 3}, lines = {line(cue.CUE_88)},
        ends = {fell = turbines_down(2)}},
    {id = "overload_3", barrier = true, directive = Directive.EXHAUST_TURBINES_DESTROYED,
        progress = {2, 3}, lines = {line(cue.CUE_90)},
        move = {to = "close", slots = {Slot.D_HEAT_SINK_GLOWS}},
        ends = {fell = turbines_down(3)}},
    -- The last line waits for the blast to land; the way out opens.
    {id = "shields_down", barrier = true, directive = Directive.EXHAUST_TURBINES_DESTROYED,
        progress = {3, 3}, ends = {sequence = true}, sequence = {
            {after_ms = 2000, lines = {line(cue.CUE_91)},
                move = {to = "open", slots = {Slot.D_SHIP_DOOR_EXIT, Slot.D_GEN_EXIT_LIGHTS}}},
            {after_ms = 6000},
        }},
    -- The escape: the crawler in the wreckage, the explosions on the way out, then the end.
    {id = "escape", directive = Directive.ESCAPE_THE_COMMAND_SHIP,
        ends = {trigger = Slot.PT_GOTO_END}, sequence = {
            {place = {objective = DECK, groups = DECK_GROUPS, squads = {
                unit(Squad.CABAL_CRAWLER, Slot.CABAL_CRAWLER)}}},
            {after_ms = 2000, lines = {line(cue.CUE_92)}},
        }},
    {id = "outro", barrier = true, ends = {cutscene = true}, cutscene = {
        state = shared.states.outro, cinematic = Slot.OUTRO_CINEMATIC_CINEMATIC}},
}

sky_battle.encounters = {
    -- The three Legionaries by the hologram, a second into the landing.
    {id = "pods", after = "landing", sequence = {
        {after_ms = 1000, place = {objective = DAMAGED, groups = DAMAGED_GROUPS, squads = {
            unit(Squad.SQ_PODS, Slot.SQ_PODS)}}},
    }},
    -- The damaged hall: two Cabal and an Incendior at the door with the pair behind them, then
    -- the rear pair and the melee one, and the stair pair on the stairs.
    {id = "damaged", after = "hall", trigger = Slot.PT_DAMAGED,
        objective = DAMAGED, groups = DAMAGED_GROUPS, squads = {
            unit(Squad.SQ_DAMAGED_HALL_FRONT, Slot.SQ_DAMAGED_HALL_FRONT),
            unit(Squad.SQ_DAMAGED, Slot.SQ_DAMAGED),
        }},
    {id = "hall", after = "hall", trigger = Slot.PT_DAMAGED_HALL,
        objective = DAMAGED, groups = DAMAGED_GROUPS, squads = {
            unit(Squad.SQ_DAMAGED_HALL_REAR_ANCHOR, Slot.SQ_DAMAGED_HALL_REAR_ANCHOR),
            unit(Squad.SQ_DAMAGED_HALL_REAR, Slot.SQ_DAMAGED_HALL_REAR),
        }, sequence = {
            {after_ms = 1500, place = {objective = DAMAGED, groups = DAMAGED_GROUPS, squads = {
                unit(Squad.SQ_DAMAGED_HALL_MELEE, Slot.SQ_DAMAGED_HALL_MELEE)}}},
        }},
    -- The Ghost calls Cayde as the player leaves the hall for the stairs.
    {id = "stairs", after = "hall", trigger = Slot.PT_DAMAGED_HALL_STAIRS,
        objective = DAMAGED, groups = DAMAGED_GROUPS, lines = {line(cue.CUE_82)}, squads = {
            unit(Squad.SQ_DAMAGED_HALL_REAR_STAIR, Slot.SQ_DAMAGED_HALL_REAR_STAIR),
            unit(Squad.SQ_DAMAGED_HALL_REAR_STAIR_ANCHOR, Slot.SQ_DAMAGED_HALL_REAR_STAIR_ANCHOR),
        }},
    -- The deck, placed from the door at the top of the stairs so nothing pops in sight: the first
    -- set and the Cabal dropship that comes in to attack, then the second set with the deck boss
    -- four seconds on. The squads with a rule of their own arrive by it. The dropship's authored
    -- paths (cps_dropship_a_enter, _exit) carry no destination the runtime accepts, so it is
    -- placed as a squad.
    {id = "deck", after = "hall", trigger = Slot.PT_DAMAGED_HALL_STAIRS_DOOR,
        objective = DECK, groups = DECK_GROUPS, squads = {
            unit(Squad.SQ_DECK_FRONT_A_A, Slot.SQ_DECK_FRONT_A_A),
            unit(Squad.SQ_DECK_FRONT_A_B, Slot.SQ_DECK_FRONT_A_B),
            unit(Squad.SQ_DECK_FRONT_A_C, Slot.SQ_DECK_FRONT_A_C),
            unit(Squad.SQ_DROPSHIP_A, Slot.SQ_DROPSHIP_A),
        }, sequence = {
            {after_ms = 4000, place = {objective = DECK, groups = DECK_GROUPS, squads = {
                unit(Squad.SQ_DECK_FRONT_B_A, Slot.SQ_DECK_FRONT_B_A),
                unit(Squad.SQ_DECK_FRONT_B_B, Slot.SQ_DECK_FRONT_B_B),
                unit(Squad.SQ_DECK_FRONT_B_C, Slot.SQ_DECK_FRONT_B_C)}}},
        }},
    {id = "deck_boss", after = "hall", trigger = Slot.PT_DAMAGED_HALL_STAIRS_DOOR, sequence = {
        {after_ms = 4000, place = {objective = ULTRA, groups = ULTRA_GROUPS, squads = {
            unit(Squad.SQ_DECK_ULTRA, Slot.SQ_DECK_ULTRA)}}},
    }},
    -- The ship door opens on the melee set. The entry set is placed inside at the same time, so
    -- nothing pops in sight, and held where it stands: sent to its task groups from behind the
    -- door, two of its squads were gone within three seconds. The airlock releases them.
    {id = "ship_door", after = "hall", trigger = Slot.PT_DECK_DOOR,
        objective = DECK, groups = DECK_GROUPS, squads = {
            unit(Squad.SQ_SHIP_DOOR_MELEE, Slot.SQ_SHIP_DOOR_MELEE),
            unit(Squad.SQ_SHIP_DOOR_MELEE_B, Slot.SQ_SHIP_DOOR_MELEE_B),
            unit(Squad.SQ_SHIP_DOOR_MELEE_C, Slot.SQ_SHIP_DOOR_MELEE_C),
            unit(Squad.SQ_SHIP_DOOR_MELEE_D, Slot.SQ_SHIP_DOOR_MELEE_D),
            unit(Squad.SQ_SHIP_DOOR_MELEE_E, Slot.SQ_SHIP_DOOR_MELEE_E),
        }, move = {to = "open", slots = {Slot.D_SHIP_DOOR}}},
    {id = "ship_entry", after = "hall", trigger = Slot.PT_DECK_DOOR,
        objective = DECK, groups = DECK_GROUPS, hold = true, squads = {
            unit(Squad.SQ_SHIP_ENTRY_A_A, Slot.SQ_SHIP_ENTRY_A_A),
            unit(Squad.SQ_SHIP_ENTRY_A_B, Slot.SQ_SHIP_ENTRY_A_B),
            unit(Squad.SQ_SHIP_ENTRY_A_B_O, Slot.SQ_SHIP_ENTRY_A_B_O),
            unit(Squad.SQ_SHIP_ENTRY_A_C, Slot.SQ_SHIP_ENTRY_A_C),
        }},
    {id = "airlock", after = "hall", trigger = Slot.PT_AIRLOCK, release = {"ship_entry"}},
    -- The shield room, then its melee squad and the inner door.
    {id = "shield_room", after = "hall", trigger = Slot.PT_SKYBATTLE_NAVMODE_2B,
        objective = DECK, groups = DECK_GROUPS, lines = {line(cue.CUE_85)}, squads = {
            unit(Squad.SQ_SHIELD_SNIPES, Slot.SQ_SHIELD_SNIPES),
            unit(Squad.SQ_SHIELD_FRONT, Slot.SQ_SHIELD_FRONT),
            unit(Squad.SQ_SHIELD_MID, Slot.SQ_SHIELD_MID),
            unit(Squad.SQ_SHIELD_REAR, Slot.SQ_SHIELD_REAR),
        }},
    -- The generator room's objects are absent by default and stay inert until their devices
    -- run: they come with the inner door, so nothing pops once the player is inside.
    {id = "engine_room", after = "hall", trigger = Slot.PT_ENGINE_ROOM_LOWER,
        objective = DECK, groups = DECK_GROUPS,
        squads = {unit(Squad.SQ_SHIELD_MELEE, Slot.SQ_SHIELD_MELEE)},
        objects = {slots = {TURBINES[1], TURBINES[2], TURBINES[3], Slot.O_SHIELD_GEN_B}},
        move = {to = "open", slots = GENERATOR_ROOM}},
    -- The shield impacts, by zone: the landing, the damaged hall and its rear, the deck in three.
    {id = "impacts_start", after = "landing",
        sequence = impacts("START_A", "START_B", "START_C", "START_D", "START_E", "START_F")},
    {id = "impacts_hall", after = "hall", trigger = Slot.PT_DAMAGED,
        sequence = impacts("HALL_A", "HALL_B", "HALL_C", "HALL_D", "HALL_E", "HALL_F")},
    {id = "impacts_hall_rear", after = "hall", trigger = Slot.PT_DAMAGED_HALL,
        sequence = impacts("HALL_B_A", "HALL_B_B", "HALL_B_C", "HALL_B_D", "HALL_B_E")},
    {id = "impacts_deck_a", after = "hall", trigger = Slot.PT_DECK_START,
        sequence = impacts("DECK_A", "DECK_A_B", "DECK_A_C")},
    {id = "impacts_deck_b", after = "hall", trigger = Slot.PT_DECK_MID,
        sequence = impacts("DECK_B", "DECK_B_B", "DECK_B_C")},
    {id = "impacts_deck_c", after = "hall", trigger = Slot.PT_DECK_HARDPOINT,
        sequence = impacts("DECK_C", "DECK_C_B", "DECK_C_C", "DECK_C_D")},
    -- One explosion scene per volume on the way out.
    {id = "ship_explosion_a", after = "escape", trigger = Slot.PT_ESCAPE_EXPLOSION_A_80B508F4,
        scenes = {{scene = scenes.SC_EXPLOSION_A_80B508F4}}},
    {id = "ship_explosion_b", after = "escape", trigger = Slot.PT_ESCAPE_EXPLOSION_B_80B508F4,
        scenes = {{scene = scenes.SC_EXPLOSION_B_80B508F4}}},
}

return sky_battle
