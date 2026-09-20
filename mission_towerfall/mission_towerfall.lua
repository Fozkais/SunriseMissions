-- Homecoming. One file per bubble, in the order the player crosses them; each returns its legs,
-- steps, encounters and the objects its seeds leave out. shared.lua names what they share.
local campaign = require("mission_towerfall.campaign")
local shared = require("mission_towerfall.shared")

local bubbles = {
    require("mission_towerfall.underwatch"),
    require("mission_towerfall.military"),
    require("mission_towerfall.plaza"),
    require("mission_towerfall.boulevard"),
    require("mission_towerfall.sky_battle"),
}

local legs, steps, encounters, omit = {}, {}, {}, {}
local function append(target, source)
    for _, value in ipairs(source or {}) do target[#target + 1] = value end
end
for _, bubble in ipairs(bubbles) do
    append(legs, bubble.legs)
    append(steps, bubble.steps)
    append(encounters, bubble.encounters)
    append(omit, bubble.omit)
end

-- Development only: opens the mission in a later bubble with the earlier steps counted as played.
-- Set to nil for a full run.
local DEBUG_START = nil

return campaign.new{
    key = "towerfall",
    debug_start = DEBUG_START,
    directive_sensor = shared.directive_sensor,
    dialogue_sensor = shared.dialogue_sensor,
    music_sensor = shared.music_sensor,
    -- The Guardian flies in over the City right after the opening movie of the activity before.
    intro = {{state = shared.states.opening, cinematic = shared.Slot.PREFAB_HRO_CINEMATIC}},
    legs = legs,
    steps = steps,
    encounters = encounters,
    omit = omit,
}
