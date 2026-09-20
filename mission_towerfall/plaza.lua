-- The plaza (bubble 6, region 48): the Cabal fleet over the city, Zavala at his bunker, the three
-- assaults he and the player repel, down to the way out to the boulevard.
-- The beats and their delays follow Homecoming 0.4.0's plaza sequences.
local shared = require("mission_towerfall.shared")
local Slot, Squad, TaskGroup, Directive = shared.Slot, shared.Squad, shared.TaskGroup,
    shared.Directive
local scenes, cue = shared.scenes, shared.cue
local unit, line = shared.unit, shared.line

local plaza = {}

plaza.legs = {
    {id = "plaza", state = shared.states.plaza, arm = {
        Slot.PT_SPIRE_TRIGGER, Slot.PT_DEFEND, Slot.PT_ZAVALA_LOOP, Slot.PT_GOTO_BOULEVARD,
    }},
}

-- Every plaza squad is assigned to the kill objective before it is placed. It has one task group,
-- so a squad either takes it or stands on no group: the two victims Zavala's combat scene kills
-- wait where they are placed.
local OBJECTIVE, GROUP = Slot.OBJ_PLAZA_KILL_CABAL, TaskGroup.OBJ_PLAZA_KILL_CABAL.GROUP_0

-- Every squad is placed at an explicit count per lane, as 0.4.0 tuned them.
local VICTIMS = {
    unit(Squad.SQUAD_KILL_CABAL_1, Slot.SQUAD_KILL_CABAL_1, nil, 1),
    unit(Squad.SQUAD_KILL_CABAL_2, Slot.SQUAD_KILL_CABAL_2, nil, 1),
}

-- The counter goal carries the "Defend the Tower" title itself. Each assault is a step that
-- shows the count so far and ends once its wave is gone; the waves' barriers keep the way out
-- from ending them early.
plaza.steps = {
    -- The goal stays "Find Zavala" from the Underwatch. The plaza's slots take nothing until the
    -- client holds the region, some fifteen seconds after the hangar's way out.
    {id = "goto_plaza", ends = {region = "plaza"}},
    -- The plaza's music (section 11) belongs to the volume just past the door, but that volume is
    -- crossed before the client holds the region, which is when it could be armed. The hold
    -- comes at about the same moment, so the music plays from there instead, with the fleet.
    {id = "plaza", ends = {trigger = Slot.PT_DEFEND}, sequence = {{after_ms = 2500, music = 11}}},
    -- A wave ends once its squads are gone, or once every Cabal it placed on the task group has
    -- died by the objective's count, whatever killed it (the client does not report every
    -- squad's members), and the two victims, on no task group and so never counted there, have
    -- no member alive: Zavala kills them in his scene, or the player does. The client creates
    -- fewer Cabal than asked at times, so once the wave's pods are all down the count also
    -- accepts every created member dead.
    {id = "wave1", barrier = true, directive = Directive.ASSAULTS_REPELLED, progress = {0, 3},
        ends = {clear = "wave1",
            kills = {objective = Slot.OBJ_PLAZA_KILL_CABAL, count = 5, of = WAVE_1,
                gone = VICTIMS}}},
    {id = "wave2", barrier = true, directive = Directive.ASSAULTS_REPELLED, progress = {1, 3},
        ends = {clear = "wave2",
            kills = {objective = Slot.OBJ_PLAZA_KILL_CABAL, count = 11, of = WAVE_2,
                settle_ms = 45000, gone = VICTIMS}}},
    {id = "wave3", barrier = true, directive = Directive.ASSAULTS_REPELLED, progress = {2, 3},
        ends = {clear = "wave3",
            kills = {objective = Slot.OBJ_PLAZA_KILL_CABAL, count = 10, of = WAVE_3,
                settle_ms = 45000, gone = VICTIMS}}},
    {id = "repelled", barrier = true, directive = Directive.ASSAULTS_REPELLED, progress = {3, 3},
        ends = {sequence = true}, sequence = {
            {after_ms = 1500, lines = {line(cue.CUE_59)}},
            {after_ms = 4500},
        }},
    {id = "speaker", directive = Directive.LEAVE_THE_PLAZA_AND_FIND_THE_SPEAKER,
        ends = {trigger = Slot.PT_GOTO_BOULEVARD}},
}

-- The sky battle is authored absent, like the hangar's command ship: its objects are instantiated
-- on arrival, and its carriers driven, or they sit inert. The spire's own device is left alone
-- until its missile rain.
local FLEET = {
    Slot.O_SPIRE, Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_CABAL_SHIP,
    Slot.O_CABAL_CARRIER_L_80B5103A, Slot.O_CABAL_CARRIER_R_80B5103A, Slot.O_CABAL_CARRIER_B,
    Slot.O_CABAL_CARRIER_FAR_A, Slot.O_CABAL_CARRIER_FAR_A_1, Slot.O_CABAL_CARRIER_FAR_A_2,
    Slot.O_CABAL_CARRIER_FAR_B, Slot.O_CABAL_CARRIER_FAR_B_1, Slot.O_CABAL_CARRIER_FAR_B_2,
    Slot.O_CABAL_CARRIER_FAR_C, Slot.O_CABAL_CARRIER_FAR_C_1, Slot.O_CABAL_CARRIER_FAR_C_2,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_0, Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_1,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_2, Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_3,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_4, Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_5,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_6, Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_7,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_LEFT_0,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_LEFT_1,
    Slot.SPECOPS_PLAZA_SHIP_BATTLE_O_DO_SHIP_LEFT_2,
}
local CARRIERS = {
    Slot.D_CABAL_CARRIER_L_80B5103A, Slot.D_CABAL_CARRIER_R_80B5103A, Slot.D_CABAL_CARRIER_B,
    Slot.D_CABAL_CARRIER_FAR_A, Slot.D_CABAL_CARRIER_FAR_A_1, Slot.D_CABAL_CARRIER_FAR_A_2,
    Slot.D_CABAL_CARRIER_FAR_B, Slot.D_CABAL_CARRIER_FAR_B_1, Slot.D_CABAL_CARRIER_FAR_B_2,
    Slot.D_CABAL_CARRIER_FAR_C, Slot.D_CABAL_CARRIER_FAR_C_1, Slot.D_CABAL_CARRIER_FAR_C_2,
}

--- A squad on the task group, `count` members per lane.
local function fighter(squad, source, count)
    return unit(squad, source, GROUP, count)
end

-- The fighters of each assault, for the count of the members the client creates.
local WAVE_1 = {
    fighter(Squad.SQ_PLAZA_REINFORCE_A_A, Slot.SQ_PLAZA_REINFORCE_A_A, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_START_B, Slot.SQ_PLAZA_REINFORCE_START_B, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 1),
}
local WAVE_2 = {
    fighter(Squad.SQ_PLAZA_REINFORCE_A_D, Slot.SQ_PLAZA_REINFORCE_A_D, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_A_D_EXTRA, Slot.SQ_PLAZA_REINFORCE_A_D_EXTRA, 3),
    fighter(Squad.SQ_PLAZA_INTERIM_A_A, Slot.SQ_PLAZA_INTERIM_A_A, 2),
}
local WAVE_3 = {
    fighter(Squad.SQ_PLAZA_INTERIM_A_B, Slot.SQ_PLAZA_INTERIM_A_B, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_B_A, Slot.SQ_PLAZA_REINFORCE_B_A, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_B_B, Slot.SQ_PLAZA_REINFORCE_B_B, 2),
    fighter(Squad.SQ_PLAZA_REINFORCE_B_A_EXTRA, Slot.SQ_PLAZA_REINFORCE_B_A_EXTRA, 2),
}

-- Zavala is one squad member: each of his scenes binds his cell, so it plays on that member
-- instead of creating an actor of its own. The combat scene plays with no key; the bunker shield
-- scene takes over while his lines call the player in.
local ZAVALA = {Slot.SQ_ZAVALA_BANSHEE}
local combat = {scene = scenes.SC_ZAVALA_COMBAT, bind = ZAVALA, keys = {}}
local bunker = {scene = scenes.SC_ZAVALA_BUNKER_SHIELD_BUNKER, bind = ZAVALA}

plaza.encounters = {
    -- The fleet and Zavala are placed as soon as the region is held: the volume at the plaza door
    -- is entered before the client holds the region and arms it.
    -- Zavala is bound to his cell and his scene plays on its third key alone.
    {id = "fleet", after = "plaza",
        objects = {slots = FLEET},
        move = {to = "open", slots = CARRIERS},
        scenes = {{scene = scenes.SC_ZAVALA, bind = ZAVALA,
            keys = {scenes.SC_ZAVALA.event_keys[3]}}}},
    -- The spire's missile rain, on the innermost of the plaza volumes, the first one reported
    -- after the region is held. Zavala's fake shield plays here too: it lasts six seconds and
    -- must be gone before the player reaches the bunker.
    {id = "spire", after = "plaza", trigger = Slot.PT_SPIRE_TRIGGER,
        objects = {slots = {Slot.O_SPIRE_MISSILE_ATTACK}},
        move = {to = "open", slots = {Slot.D_SPIRE}},
        scenes = {{scene = scenes.SC_FAKE_SHIELD}}},
    -- Squad anchors, from the bunker (Zavala at y = 30) outwards: the victims and START_B sit in
    -- front of it, A_A between, A_B mid-rear, A_D and the B_A family rear right, B_B rear
    -- left. A pod is one squad placement; `count` is its number of Cabal.
    -- The first assault: three pods close to the bunker, seven Cabal in all, among them Zavala's
    -- victims and the two squads his combat scene shoots at (A_A, A_B).
    {id = "wave1", after = "wave1", trigger = Slot.PT_ZAVALA_LOOP,
        sequence = {
            {after_ms = 2000, stop = {scenes.SC_ZAVALA},
                place = {objective = OBJECTIVE, squads = {VICTIMS[1], VICTIMS[2]}}},
            {after_ms = 2500, place = {objective = OBJECTIVE, squads = {
                fighter(Squad.SQ_PLAZA_REINFORCE_A_A, Slot.SQ_PLAZA_REINFORCE_A_A, 2)}}},
            {after_ms = 2500, place = {objective = OBJECTIVE, squads = {
                fighter(Squad.SQ_PLAZA_REINFORCE_START_B, Slot.SQ_PLAZA_REINFORCE_START_B, 2),
                fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 1)}}},
            {after_ms = 2200, scenes = {combat}},
        }},
    -- The second assault: the rear pod lands two seconds into the interlude, Zavala falls back to
    -- his shield for the missiles, then the wave comes down at a steady pace: two rear pods, one
    -- right in front of the bunker (his victims), one at the far end, one more a few seconds on.
    {id = "wave2", after = "wave2", lines = {line(cue.CUE_52)}, sequence = {
        {after_ms = 2000, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_A_D, Slot.SQ_PLAZA_REINFORCE_A_D, 2)}}},
        -- A holder's scenes play before its actions: the combat scene stops in its own item
        -- so the bunker scene finds Zavala free.
        {after_ms = 7000, stop = {scenes.SC_ZAVALA_COMBAT}},
        {after_ms = 100, scenes = {bunker}},
        {after_ms = 2300, lines = {line(cue.CUE_53)}},
        {after_ms = 12000, lines = {line(cue.CUE_51)},
            stop = {scenes.SC_ZAVALA_BUNKER_SHIELD_BUNKER},
            place = {objective = OBJECTIVE, squads = {
                fighter(Squad.SQ_PLAZA_REINFORCE_A_D, Slot.SQ_PLAZA_REINFORCE_A_D, 2)}}},
        -- A_C is refused as not runnable by the runtime, so the mid-rear pod is A_B again.
        {after_ms = 2500, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 2)}}},
        {after_ms = 2500, place = {objective = OBJECTIVE, squads = {VICTIMS[1], VICTIMS[2]}}},
        {after_ms = 3000, scenes = {combat}},
        {after_ms = 1000, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_A_D_EXTRA, Slot.SQ_PLAZA_REINFORCE_A_D_EXTRA, 3)}}},
        {after_ms = 3000, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_INTERIM_A_A, Slot.SQ_PLAZA_INTERIM_A_A, 2)}}},
    }},
    -- The third assault: the interlude pod at the far end, the shield again, then five pods at the
    -- same pace: rear right, middle, right in front (the victims), far rear left, rear right again.
    {id = "wave3", after = "wave3", sequence = {
        {after_ms = 500, lines = {line(cue.CUE_55)}, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_INTERIM_A_B, Slot.SQ_PLAZA_INTERIM_A_B, 2)}}},
        {after_ms = 8000, stop = {scenes.SC_ZAVALA_COMBAT}},
        {after_ms = 100, scenes = {bunker}},
        {after_ms = 2900, lines = {line(cue.CUE_57)}},
        {after_ms = 11000, lines = {line(cue.CUE_54)},
            stop = {scenes.SC_ZAVALA_BUNKER_SHIELD_BUNKER},
            place = {objective = OBJECTIVE, squads = {
                fighter(Squad.SQ_PLAZA_REINFORCE_B_A, Slot.SQ_PLAZA_REINFORCE_B_A, 2)}}},
        {after_ms = 2500, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B, 2)}}},
        {after_ms = 2500, place = {objective = OBJECTIVE, squads = {VICTIMS[1], VICTIMS[2]}}},
        {after_ms = 3000, scenes = {combat}},
        {after_ms = 1000, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_B_B, Slot.SQ_PLAZA_REINFORCE_B_B, 2)}}},
        {after_ms = 2500, place = {objective = OBJECTIVE, squads = {
            fighter(Squad.SQ_PLAZA_REINFORCE_B_A_EXTRA, Slot.SQ_PLAZA_REINFORCE_B_A_EXTRA, 2)}}},
    }},
}

return plaza
