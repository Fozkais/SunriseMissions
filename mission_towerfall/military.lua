-- The hangar (bubble 4, region 32): the Cabal drop pod, the two Amanda doors, the command ship's
-- strike and the escape explosions, down to the way out to the plaza.
local shared = require("mission_towerfall.shared")
local Slot, Squad, TaskGroup = shared.Slot, shared.Squad, shared.TaskGroup
local scenes, cue = shared.scenes, shared.cue
local unit, line = shared.unit, shared.line

local military = {}

military.legs = {
    {id = "hangar", state = shared.states.military, arm = {
        Slot.PT_HANGAR_EARLY, Slot.PT_HANGAR_SPAWN, Slot.PT_HANGAR_SPAWN_BACKUP,
        Slot.PT_HANGAR_SPAWN_POD, Slot.PT_AMANDA_SKIP,
        Slot.PT_HANGAR_COMBAT, Slot.PT_HOLLIDAY, Slot.PT_HANGAR_FODDER_BACKUP_SPAWN,
        Slot.PT_ESCAPE_EXPLOSION_A_80B5036A,
        Slot.PT_ESCAPE_EXPLOSION_B_80B5036A, Slot.PT_NUX_CROUCH, Slot.PT_NUX_DOUBLE_JUMP,
        Slot.PT_GOTO_PLAZA_80B50B91,
    }},
}

-- The goal stays "Find Zavala" from the Underwatch.
military.steps = {
    {id = "hangar", ends = {trigger = Slot.PT_GOTO_PLAZA_80B50B91}},
}

-- Every hangar squad is assigned to the one objective before it is placed.
local OBJECTIVE, GROUPS = Slot.OBJ_HANGAR, TaskGroup.OBJ_HANGAR
-- The Cabal warbase intro jumps an actor in on its jetpack, weapon drawn, onto its anchor, where
-- its combat AI takes over.
local INTRO = "WORLD_RIFLE_ANY_CABAL_WARBASE_INTRO"

local LEDGE_CENTURION = {
    unit(Squad.SQ_HANGAR_OVERLOOK_A_A_CENT, Slot.SQ_HANGAR_OVERLOOK_A_A_CENT, nil, 1),
}

local FODDERS = {
    unit(Squad.SQ_HANGAR_FODDER_A, Slot.SQ_HANGAR_FODDER_A),
    unit(Squad.SQ_HANGAR_FODDER_B, Slot.SQ_HANGAR_FODDER_B),
    unit(Squad.SQ_HANGAR_FODDER_C, Slot.SQ_HANGAR_FODDER_C),
}
local FODDER_CELLS = {
    Slot.SQ_HANGAR_FODDER_A_CELL, Slot.SQ_HANGAR_FODDER_B_CELL, Slot.SQ_HANGAR_FODDER_C_CELL,
}

military.encounters = {
    -- The hangar's music starts as the player lands in it.
    -- Section 4, found by ear.
    {id = "overlook", after = "hangar", trigger = Slot.PT_HANGAR_EARLY, music = 4,
        objective = OBJECTIVE, groups = GROUPS,
        squads = {unit(Squad.SQ_HANGAR_OVERLOOK_A_A, Slot.SQ_HANGAR_OVERLOOK_A_A)},
        move = {to = "close", slots = {Slot.D_GATING_AMANDA_START, Slot.D_GATING_AMANDA_HANGAR},
            snap = true}},
    -- The pod is absent until instantiated; its scene opens it later.
    -- Two overlook squads stand where they are placed until the pod opens.
    {id = "entrance", after = "hangar", trigger = Slot.PT_HANGAR_SPAWN,
        objective = OBJECTIVE, groups = GROUPS, hold = true,
        squads = {
            unit(Squad.SQ_HANGAR_OVERLOOK_A_C, Slot.SQ_HANGAR_OVERLOOK_A_C),
            unit(Squad.SQ_HANGAR_OVERLOOK_B_A, Slot.SQ_HANGAR_OVERLOOK_B_A),
        },
        objects = {slots = {Slot.O_CABAL_DROP_POD_MILITARY_HALLWAY}}},
    -- The ledge Centurion waits at the foot of the overlook on the objective with no task group;
    -- once in combat with the player it jets up in front of them. Anything sent to it afterwards
    -- stops that: a group of its own, even the cheapest one, sends it away from the player, and a
    -- fresh evaluation or awareness keeps it from the jump.
    {id = "ledge_centurion", after = "hangar", trigger = Slot.PT_HANGAR_SPAWN,
        objective = OBJECTIVE, squads = LEDGE_CENTURION},
    -- The scene opens the pod (about 2.7 s) and needs all three Legionaries in it; the two
    -- overlook squads start to move with it.
    {id = "pod_squad", after = "hangar", trigger = Slot.PT_HANGAR_SPAWN_BACKUP,
        objective = OBJECTIVE, groups = GROUPS, squads = {
            unit(Squad.SQ_MILITARY_HALLWAY_DESTRUCTION, Slot.SQ_MILITARY_HALLWAY_DESTRUCTION,
                nil, 3)},
        release = {"entrance"},
        scenes = {{scene = scenes.SC_MILITARY_HALLWAY_DESTRUCTION}}},
    -- Explosion C blows the first door, which opens on the blast.
    {id = "first_door", after = "hangar", trigger = Slot.PT_HANGAR_SPAWN_POD, sequence = {
        {after_ms = 1000,
            place = {objective = OBJECTIVE, groups = GROUPS, squads = {
                unit(Squad.SQ_HANGAR_OVERLOOK_B_B, Slot.SQ_HANGAR_OVERLOOK_B_B),
            }},
            scenes = {{scene = scenes.SC_EXPLOSION_C_80B5036A}},
            move = {to = "open", slots = {Slot.D_GATING_AMANDA_START}}},
    }},
    -- Before the second door the command ship and its escort are put in place at once, then
    -- explosion D opens it.
    {id = "second_door", after = "hangar", trigger = Slot.PT_AMANDA_SKIP,
        objects = {slots = {
            Slot.CABAL_DESTROYER, Slot.DOGFIGHT_BANK_RIGHT_INIT, Slot.DOGFIGHT_BANK_LEFT_A,
            Slot.DOGFIGHT_BANK_LEFT_B, Slot.DOGFIGHT_BANK_LEFT_C,
            Slot.DOGFIGHT_SHIPS_DISPLACEMENT_A,
            Slot.DOGFIGHT_SHIPS_DISPLACEMENT_B, Slot.DOGFIGHT_SHIPS_DISPLACEMENT_C,
            Slot.DOGFIGHT_BANK_RIGHT_A, Slot.DOGFIGHT_BANK_RIGHT_B, Slot.DOGFIGHT_BANK_RIGHT_C,
            Slot.O_CABAL_CARRIER_R_80B5036A, Slot.O_CABAL_CARRIER_L_80B5036A,
        }},
        move = {to = "open",
            slots = {Slot.D_CABAL_CARRIER_R_80B5036A, Slot.D_CABAL_CARRIER_L_80B5036A}},
        scenes = {{scene = scenes.SC_EXPLOSION_D_80B5036A}},
        -- Cue 34 follows the door by a second; no volume the client reports fits its moment.
        sequence = {
            {after_ms = 1200, move = {to = "open", slots = {Slot.D_GATING_AMANDA_HANGAR}}},
            {after_ms = 1000, lines = {line(cue.CUE_34)}},
        }},
    -- The six missiles hit as they appear, so they are spread out.
    {id = "missiles", after = "hangar", trigger = Slot.PT_AMANDA_SKIP, sequence = {
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_1_80B5036A}}},
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_2_80B5036A}}},
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_3_80B5036A}}},
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_4}}},
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_5}}},
        {after_ms = 250, objects = {slots = {Slot.O_CABAL_MISSILE_6}}},
    }},
    {id = "combat_music", after = "hangar", trigger = Slot.PT_HANGAR_COMBAT, music = 8},
    -- The fodders arrive over the command ship with their intro. Group 13 then holds the firing
    -- area: it goes out once they have landed, since an objective sent before keeps them from
    -- spawning.
    -- They set off from the volume just before explosion A, so they land as it goes off.
    {id = "fodders", after = "hangar", trigger = Slot.PT_HANGAR_FODDER_BACKUP_SPAWN,
        perform = {cells = FODDER_CELLS, sequence = INTRO},
        sequence = {{after_ms = 5000,
            assign = {objective = OBJECTIVE, group = GROUPS.GROUP_13, squads = FODDERS}}}},
    {id = "explosion_a", after = "hangar", trigger = Slot.PT_ESCAPE_EXPLOSION_A_80B5036A,
        scenes = {{scene = scenes.SC_EXPLOSION_A_80B5036A}}},
    -- The second pod crashes down with its three Legionaries at the blast.
    {id = "explosion_b", after = "hangar", trigger = Slot.PT_ESCAPE_EXPLOSION_B_80B5036A,
        objective = OBJECTIVE, groups = GROUPS,
        squads = {unit(Squad.SQ_HANGAR_A_B, Slot.SQ_HANGAR_A_B, nil, 1)},
        scenes = {{scene = scenes.SC_EXPLOSION_B_80B5036A}}},
    -- These two are placed ahead of the player as the stairwell is crossed, and defend their zone
    -- by the second explosion: group 14 holds the ground there, group 15 the overlook above it.
    {id = "stairwell_ground", after = "hangar", trigger = Slot.PT_HOLLIDAY,
        sequence = {{after_ms = 4000, place = {objective = OBJECTIVE, approach = GROUPS.GROUP_14,
            squads = {unit(Squad.SQ_HANGAR_A_A, Slot.SQ_HANGAR_A_A)}}}}},
    {id = "stairwell_overlook", after = "hangar", trigger = Slot.PT_HOLLIDAY,
        sequence = {{after_ms = 4000, place = {objective = OBJECTIVE, approach = GROUPS.GROUP_15,
            squads = {unit(Squad.SQ_HANGAR_A_B_SNIPER, Slot.SQ_HANGAR_A_B_SNIPER)}}}}},
    {id = "nux_crouch", after = "hangar", trigger = Slot.PT_NUX_CROUCH, lines = {line(cue.CUE_37)}},
    -- Music 1 comes back at the way out of the hangar.
    {id = "exit_music", after = "hangar", trigger = Slot.PT_NUX_DOUBLE_JUMP, music = 1},
}

return military
