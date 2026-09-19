-- The Underwatch (bubble 9, region 72): the wake-up, the collapsing wall, the Centurion, Cayde at
-- Shaxx's door, the hold-to-open door and the way out to the hangar.
local shared = require("mission_towerfall.shared")
local Slot, Squad, Directive, scenes, cue = shared.Slot, shared.Squad, shared.Directive,
    shared.scenes, shared.cue
local unit, line = shared.unit, shared.line
local shaxx_key = scenes.SCENE_SHAXX.event_keys

local underwatch = {}

underwatch.legs = {
    {id = "underwatch", state = shared.states.underwatch, arm = {
        Slot.PT_START, Slot.PT_SC_UNDERWATCH_INTRO_STAND, Slot.PT_CENTURION_INTRO,
        Slot.PT_CENTURION_INTRO_REINFORCE, Slot.PT_SHAXX_ENTERS, Slot.PT_SC_CIVILIAN_GROUND_1_LOOK,
        Slot.PT_SC_CIVILIAN_WALL_SIT_C, Slot.PT_SC_CIVILIANS_MID, Slot.PT_HERO_MOMENT,
        Slot.PT_WEAPON, Slot.PT_WEAPON_COMPLETE, Slot.PT_GOTO_MILITARY, Slot.PT_NUX_JUMP,
    }},
}

underwatch.steps = {
    -- The player wakes to a fight between a Frame and a Red Guard, Cue 1 and the music start. The
    -- first goal waits for pt_start, the spawn platform: an armed volume reports the player already
    -- inside it only once the client is in the world, past the arrival's fade.
    {id = "wake", barrier = true, lines = {line(cue.CUE_1)}, music = 1,
        ends = {trigger = Slot.PT_START}},
    -- Cayde's scene spawns Cayde and the Legionaries, opens Shaxx's door and plays its own lines.
    -- It starts two seconds after Cue 10 has ended, once the player stands at the door. The scene
    -- reports neither its lines nor its end, so the goal changes when its last line has ended,
    -- 13.5 seconds after it starts.
    {id = "home", directive = Directive.DEFEND_YOUR_HOME, navpoint = Slot.AP_IKORA,
        sequence = {
            {on = Slot.PT_SHAXX_ENTERS},
            {spoken = cue.CUE_10, after_ms = 2000,
                scenes = {{scene = scenes.SCENE_CAYDE_GOLDEN_GUN}}},
            {after_ms = 13500},
        },
        ends = {sequence = true}},
    -- Cayde's scene never ends, and a scene still running starts over whenever the client loads
    -- the Underwatch again, so it is stopped once Cayde is done.
    {id = "find_zavala", directive = Directive.FIND_ZAVALA,
        sequence = {{after_ms = 3000, stop = {scenes.SCENE_CAYDE_GOLDEN_GUN}}},
        -- The Underwatch ends at the jump down to the hangar, past Cue 30's volume.
        ends = {trigger = Slot.PT_NUX_JUMP}},
}

-- The civilians of the Underwatch, present from the start: their scenes animate them but spawn
-- none. Left out: the test ones, the hero moment's, whose scene is not played, and wall_sit_c,
-- whose spot is inside Shaxx's door.
local CIVILIANS = {
    "SQ_CIVILIAN_CATATONIC", "SQ_CIVILIAN_KNEEL", "SQ_CIVILIAN_STAND", "SQ_CIVILIAN_WALL_SIT_A",
    "SQ_CIVILIAN_WALL_SIT_B", "SQ_CIVILIAN_GROUND_1", "SQ_CIVILIAN_GROUND_2",
    "SQ_CIVILIAN_ON_KNEES_CRYING",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_BENT_DOOR_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_BENT_INJURED_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_ARMS_WRAPPED_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_CROUCH_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_WORRIED_1_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_INJURED_WALL_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_CLASPED_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_CLASPED_FEMALE_SQ_CIVILIAN_REACT",
    "PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_TIRED_SQ_CIVILIAN_REACT",
}
local civilians = {}
for index, name in ipairs(CIVILIANS) do civilians[index] = unit(Squad[name], Slot[name]) end

-- The hallway's civilian scenes. Each civilian that reacts as the player walks by plays its
-- prefab's scene on its first key only.
local hallway = {
    {scene = scenes.SC_CIVILIAN_GROUND_1}, {scene = scenes.SC_CIVILIAN_GROUND_2},
    {scene = scenes.SC_CIVILIAN_ON_KNEES_CRYING}, {scene = scenes.SC_CIVILIAN_KNEEL},
    {scene = scenes.SC_CIVILIAN_CATATONIC},
}
local REACTS = {
    "BENT_DOOR", "BENT_INJURED", "ARMS_WRAPPED", "CROUCH", "WORRIED_1", "INJURED_WALL", "CLASPED",
    "CLASPED_FEMALE", "TIRED",
}
for _, name in ipairs(REACTS) do
    local scene = scenes["PF_SC_T0_UNDERWATCH_CIVILIAN_REACT_" .. name .. "_SC_CIVILIAN_REACT"]
    hallway[#hallway + 1] = {scene = scene, keys = {scene.event_keys[1]}}
end

underwatch.encounters = {
    {id = "fake_fight", squads = {
        unit(Squad.SQ_FRAME_FAKE_FIGHT, Slot.SQ_FRAME_FAKE_FIGHT),
        unit(Squad.SQ_RED_GUARD_FAKE_FIGHT, Slot.SQ_RED_GUARD_FAKE_FIGHT),
    }},
    {id = "civilians_present", squads = civilians},
    -- The wall comes down: the scene plays the blast but spawns none of its Cabal, so the first
    -- contact squad and its backup are placed here. Cue 6 follows the scene.
    {id = "wall", after = "home", trigger = Slot.PT_SC_UNDERWATCH_INTRO_STAND,
        objective = Slot.OBJ_CABAL_FIRST_CONTACT, squads = {
            unit(Squad.SQUAD_FIRST_CONTACT_CABAL, Slot.SQUAD_FIRST_CONTACT_CABAL),
            unit(Squad.SQUAD_FIRST_CONTACT_CABAL_BACKUP_A, Slot.SQUAD_FIRST_CONTACT_CABAL_BACKUP_A),
        },
        lines = {line(cue.CUE_5)},
        retire = {Squad.SQ_FRAME_FAKE_FIGHT, Squad.SQ_RED_GUARD_FAKE_FIGHT},
        scenes = {{scene = scenes.SCENE_CABAL_FIRST_CONTACT}},
        move = {to = "open", slots = {Slot.D_UNDERWATCH_COLLAPSING_WALL}, snap = true},
        sequence = {{finished = Slot.SCENE_CABAL_FIRST_CONTACT, lines = {line(cue.CUE_6)}}}},
    -- The Centurion impales the Frame. The bound cell makes the scene spawn the Centurion itself,
    -- and the scene brings the Frame it kills.
    {id = "centurion", after = "home", trigger = Slot.PT_CENTURION_INTRO,
        objective = Slot.OBJ_CENTURION_INTRO, squads = {
            unit(Squad.SQ_CENTURION_INTRO_BACKUP, Slot.SQ_CENTURION_INTRO_BACKUP),
            unit(Squad.SQ_CENTURION_INTRO_RUSH, Slot.SQ_CENTURION_INTRO_RUSH),
        },
        scenes = {{scene = scenes.SC_CENTURION_INTRO, bind = {Slot.SQ_CENTURION_INTRO_CELL_1}}}},
    -- Shaxx's two doors and the hold-to-open door are absent objects until now: instantiated,
    -- they stand closed. Shaxx is no participant of his scene and is placed here.
    {id = "shaxx_doors", after = "home", trigger = Slot.PT_CENTURION_INTRO_REINFORCE,
        squads = {unit(Squad.SQ_SHAXX, Slot.SQ_SHAXX)},
        lines = {line(cue.CUE_10)},
        objects = {slots = {Slot.O_SHAXX_DOOR_ENTER, Slot.O_SHAXX_DOOR_EXIT, Slot.GUN_DOOR}},
        -- The door is held to open, so its use row goes out fresh.
        interact = {slots = {Slot.DOOR_INTERACTABLE}, used = false},
        sequence = {
            {interacted = Slot.DOOR_INTERACTABLE, move = {to = "open", slots = {Slot.D_GUN_DOOR}},
                interact = {slots = {Slot.DOOR_INTERACTABLE}, active = false}},
        }},
    -- Shaxx's scene starts with no key as the player looks at the civilians, then each volume on
    -- the way to the armory publishes the keys that move it on.
    {id = "shaxx", after = "home", trigger = Slot.PT_SC_CIVILIAN_GROUND_1_LOOK,
        scenes = {{scene = scenes.SCENE_SHAXX, keys = {}}},
        sequence = {
            {on = Slot.PT_SC_CIVILIANS_MID,
                signal = {scene = scenes.SCENE_SHAXX, keys = {shaxx_key[1], shaxx_key[2]}}},
            {on = Slot.PT_WEAPON,
                signal = {scene = scenes.SCENE_SHAXX, keys = {shaxx_key[4], shaxx_key[5]}}},
            -- Key 3 shuts the door, so it waits for Shaxx's two lines, which the scene plays.
            {after_ms = 5500, signal = {scene = scenes.SCENE_SHAXX, keys = {shaxx_key[3]}}},
        }},
    -- The civilians in the hallway all play at once as the player comes through Shaxx's door.
    {id = "civilians", after = "home", trigger = Slot.PT_SC_CIVILIAN_WALL_SIT_C,
        scenes = hallway},
    -- The hero moment's two Cabal, kept as an extra fight below the hallway. Its scene and civilian
    -- are left out: played blind, the scene did not hold together.
    {id = "hero_moment", after = "home", trigger = Slot.PT_HERO_MOMENT,
        objective = Slot.OBJ_CENTURION_INTRO, squads = {
            unit(Squad.SQ_CABAL_HERO_MOMENT, Slot.SQ_CABAL_HERO_MOMENT),
            unit(Squad.SQ_CABAL_HERO_MOMENT_B, Slot.SQ_CABAL_HERO_MOMENT_B),
        }},
    -- The way out: the Red Guard at the exit.
    {id = "post_gun", after = "home", trigger = Slot.PT_WEAPON_COMPLETE,
        objective = Slot.OBJ_POST_GUN,
        squads = {unit(Squad.SQ_RED_GUARD_ADS, Slot.SQ_RED_GUARD_ADS)}},
    -- Cue 30 plays in the volume just before the jump down to the hangar. No trigger reports that
    -- volume, so the line goes out as the player enters the corridor and the client holds it until
    -- the player reaches the volume.
    {id = "cue30", after = "home", trigger = Slot.PT_GOTO_MILITARY,
        lines = {line(cue.CUE_30, Slot.SLOT_0004_80B5168C)}},
}

-- The use row goes out with its step, so the object stays out of the seeds until then.
underwatch.omit = {Slot.DOOR_INTERACTABLE}

return underwatch
