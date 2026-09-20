-- The boulevard and the bazaar (bubble 0, region 0): the entry door, the Cabal on the stairs Ikora
-- blasts on her way to the Speaker, the pod at the bazaar door, the Incendiors inside, the bazaar
-- fights, and Holliday's Hawk that takes the player to the command ship.
-- The beats and their delays follow Homecoming 0.4.0's boulevard script.
local shared = require("mission_towerfall.shared")
local Slot, Squad, TaskGroup, Directive = shared.Slot, shared.Squad, shared.TaskGroup,
    shared.Directive
local scenes, cue = shared.scenes, shared.cue
local unit, line = shared.unit, shared.line

local boulevard = {}

boulevard.legs = {
    {id = "boulevard", state = shared.states.boulevard, arm = {
        Slot.PT_START_IKORA, Slot.PT_BAZAAR_MID, Slot.PT_BAZAAR_FARTHER,
    }},
}

-- Every bazaar squad is assigned to the bazaar objective before it is placed; the fighters take
-- the task group that costs the least, the four Cabal Ikora blasts stand on no group where her
-- scene finds them.
local OBJECTIVE, GROUPS = Slot.OBJ_BAZAAR, TaskGroup.OBJ_BAZAAR

--- A squad on the pathing, `count` members per lane.
local function fighter(squad, source, count)
    return unit(squad, source, nil, count)
end

-- Ikora's scene victims: the three Cabal on the stairs and the lone one behind them. Placed
-- while the scene runs, so it claims them: a squad placed before the activation has already
-- engaged the player and is never blasted. The invisible target she shoots at has no member
-- and no squad the runtime resolves; her entrance plays without it.
local IKORA_CAST = {
    unit(Squad.SQUAD_CABAL_BLASTED_1, Slot.SQUAD_CABAL_BLASTED_1, nil, 1),
    unit(Squad.SQUAD_CABAL_BLASTED_2, Slot.SQUAD_CABAL_BLASTED_2, nil, 1),
    unit(Squad.SQUAD_CABAL_BLASTED_3, Slot.SQUAD_CABAL_BLASTED_3, nil, 1),
    unit(Squad.SQUAD_CABAL_BLASTED_4, Slot.SQUAD_CABAL_BLASTED_4, nil, 1),
}

-- The objective counts the kills of the squads on its task groups, whatever killed them, which
-- is how the bazaar's gates read: the pod's three Cabal open the door, the Incendiors and the
-- two bazaar squads bring the finale, the finale brings Holliday. The blasted Cabal stand on no
-- group and count nowhere.
local POD, BAZAAR, FINALE = 3, 2 + 4 + 3, 2

boulevard.steps = {
    -- The goal stays "Leave the Plaza and find the Speaker". The region is held as the player
    -- reaches the spawn area, in front of the closed entry door.
    {id = "goto_boulevard", ends = {region = "boulevard"}},
    -- The door opens three seconds after the hold, the boulevard's music (section 13) a little
    -- later. Ikora's scene is activated with no key first, then its cast is placed into it. On
    -- the stairs volume her whole entrance plays on its second key, her lines and Zavala's
    -- orders included; her blast is not part of the scene: the nova bomb is an object that flies
    -- in and detonates on instantiation, timed on her arrival. She jumps onto the Cabal ship
    -- and the pod touches down in front of the bazaar door about seventeen seconds in.
    {id = "stairs", barrier = true, ends = {sequence = true}, sequence = {
        {after_ms = 3000, move = {to = "open", slots = {Slot.D_DOOR_GATING}},
            scenes = {{scene = scenes.SCENE_IKORA_BOULEVARD, keys = {}}}},
        {after_ms = 200, place = {objective = OBJECTIVE, squads = IKORA_CAST}},
        {after_ms = 2500, music = 13},
        {on = Slot.PT_START_IKORA, signal = {scene = scenes.SCENE_IKORA_BOULEVARD,
            keys = {scenes.SCENE_IKORA_BOULEVARD.event_keys[1],
                scenes.SCENE_IKORA_BOULEVARD.event_keys[2]}}},
        {after_ms = 1500, objects = {slots = {Slot.O_NOVA_BOMB_PROJECTILE}}},
        {after_ms = 13500},
    }},
    -- The pod touches down with the new goal; its three Cabal open the bazaar door. The pod is
    -- the squad's own spawn rule: one lane, three Cabal out of it. They fight where they land,
    -- on a group of their own: routed, the squad would spawn again a few seconds in, and a
    -- Cabal killed by then would be lost to the count.
    {id = "board", barrier = true, directive = Directive.BOARD_THE_COMMAND_SHIP,
        ends = {kills = {objective = OBJECTIVE, count = POD}},
        sequence = {{place = {objective = OBJECTIVE, squads = {
            unit(Squad.SQ_BAZAAR_START, Slot.SQ_BAZAAR_START, GROUPS.GROUP_0, 3)}}}}},
    -- The door opens on an Incendior: the pyro scene's only participant has no cell, so it is
    -- placed first and the scene plays on it. Two more Incendiors wait inside; the bazaar
    -- squads come on the volumes further in.
    {id = "bazaar", barrier = true, ends = {kills = {objective = OBJECTIVE, count = BAZAAR}},
        sequence = {
            {place = {squads = {unit(Squad.SQ_FLAME, Slot.SQ_FLAME)}},
                move = {to = "open", slots = {Slot.D_DOOR_BAZAAR}}},
            {after_ms = 500, scenes = {{scene = scenes.SC_PYRO_INTRO}},
                place = {objective = OBJECTIVE, groups = GROUPS, squads = {
                    fighter(Squad.SQ_BAZAAR_A_B, Slot.SQ_BAZAAR_A_B)}}},
            {after_ms = 1000, lines = {line(cue.CUE_74)}},
        }},
    {id = "finale", barrier = true, ends = {kills = {objective = OBJECTIVE, count = FINALE}},
        sequence = {{place = {objective = OBJECTIVE, groups = GROUPS, squads = {
            fighter(Squad.SQ_BAZAAR_FINALE, Slot.SQ_BAZAAR_FINALE, 1)}}}}},
    -- Holliday's Hawk comes down (the other two are the other players' ships), her line, then
    -- the ride to the command ship.
    {id = "holliday", barrier = true, ends = {sequence = true}, sequence = {
        {objects = {slots = {Slot.O_HAWK_1}}},
        {after_ms = 2000, lines = {line(cue.CUE_76)}},
        {after_ms = 5000},
    }},
    {id = "boarding", barrier = true, ends = {cutscene = true}, cutscene = {
        state = shared.states.boarding, cinematic = Slot.MID_CINEMATIC_CINEMATIC,
        after = shared.states.ship}},
}

boulevard.encounters = {
    {id = "bazaar_mid", after = "bazaar", trigger = Slot.PT_BAZAAR_MID,
        objective = OBJECTIVE, groups = GROUPS,
        squads = {fighter(Squad.SQ_BAZAAR_A_A, Slot.SQ_BAZAAR_A_A)}},
    {id = "bazaar_farther", after = "bazaar", trigger = Slot.PT_BAZAAR_FARTHER,
        objective = OBJECTIVE, groups = GROUPS, lines = {line(cue.CUE_75)},
        squads = {fighter(Squad.SQ_BAZAAR_A_C, Slot.SQ_BAZAAR_A_C)}},
}

return boulevard
