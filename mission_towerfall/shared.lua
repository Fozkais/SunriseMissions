-- Names every Homecoming bubble shares. Generated names that read well (Slot.PT_SHAXX_ENTERS,
-- Squad.SQ_SHAXX) are used as they are; this file names the ones that do not: the mission's
-- states, its three sensors and its dialogue cues.
local missions = require("missions")
local mission = require(missions.MISSION_TOWERFALL)
local campaign = require("lib.campaign")

local shared = {
    mission = mission,
    Slot = mission.Slot,
    Squad = mission.Squad,
    Directive = mission.Directive,
    scenes = mission.scenes,
    TaskGroup = mission.TaskGroup,
    unit = campaign.unit,
    line = campaign.line,
    directive_sensor = mission.Slot.M_DIRECTIVE_SENSOR_80B50913,
    dialogue_sensor = mission.Slot.M_DIALOG_SENSOR_80B50913,
    music_sensor = mission.Slot.M_MUSIC_SENSOR_80B50913,
    cue = mission.DialogueCue.M_DIALOG_SENSOR_80B50913,
}

-- Each bubble's playable state, and the ordinal-1 states that own a cinematic.
local states = mission.states
shared.states = {
    boulevard = states.STATE_80B500BC_0000_0000_80B500AD,   -- bubble 0, region 0
    outro = states.STATE_80B500BC_0001_0001_80B500AF,       -- bubble 1, region 9: final cutscene
    opening = states.STATE_80B500BC_0002_0001_80B500B1,     -- bubble 2, region 17: prefab_hro
    military = states.STATE_80B500BC_0004_0000_80B500B3,    -- bubble 4, region 32
    plaza = states.STATE_80B500BC_0006_0000_80B500B6,       -- bubble 6, region 48
    ship = states.STATE_80B500BC_0008_0000_80B500B8,        -- bubble 8, region 64
    boarding = states.STATE_80B500BC_0008_0001_80B500B9,    -- bubble 8, region 65: mid cutscene
    underwatch = states.STATE_80B500BC_0009_0000_80B500BB,  -- bubble 9, region 72
}

return shared
