-- Device falls: a step ends once type-23 devices the script drove have fallen back.
--   ends = {fell = {slots = {Slot.<D_...>, ...}, below = 0.5, rest = 0.4, count = n}}
-- The client reports a device's position as it moves, and reports it again when something in
-- the world changes it: a turbine the player shoots has its device drop from the position it
-- was driven to, and settle a little higher once destroyed. A device has fallen once it reported
-- a position at or above `from` (default 1), then one below `below`, then, when `rest` is given,
-- one below `rest` and one back at or above it, in this attempt; the end holds once `count` of
-- the listed devices
-- (default all of them) have. The falls are kept per device, so steps that count them up share
-- one list: `count = 1`, then `count = 2`, each showing its own progress. `open` maps a device
-- to another one opened the moment it falls, such as the panel that lights up for its turbine.
local lib = require("lib.mission_lib")

local devices = {name = "devices"}

local UP, FELL, BOTTOM, DOWN = 1, 2, 3, 4

local function fall_key(context, slot)
    return "fell." .. tostring(context.attempt_generation) .. "." .. slot
end

-- Every step end that counts falls, and the devices they watch, each once with its thresholds.
local function watched(content)
    local seen, slots, list = {}, {}, {}
    for _, step in ipairs(content.steps or {}) do
        local fell = (step.ends or {}).fell
        if fell ~= nil then
            list[#list + 1] = {step = step, fell = fell}
            for _, slot in ipairs(type(fell.slots) == "table" and fell.slots or {}) do
                if not seen[slot] then
                    seen[slot] = true
                    slots[#slots + 1] = {slot = slot, from = fell.from or 1, below = fell.below,
                        rest = fell.rest, open = fell.open ~= nil and fell.open[slot] or nil}
                end
            end
        end
    end
    return list, slots
end

function devices.check(content)
    for _, entry in ipairs(watched(content)) do
        local where, fell = "step " .. tostring(entry.step.id) .. " fell", entry.fell
        assert(type(fell.slots) == "table" and #fell.slots > 0, where .. " needs device slots")
        for _, slot in ipairs(fell.slots) do lib.one(slot, where .. " slot") end
        assert(type(fell.below) == "number" and fell.below > 0 and fell.below <= 1,
            where .. " below must be a position between zero and one")
        assert(fell.from == nil or (type(fell.from) == "number" and fell.from > fell.below),
            where .. " from must be a position above below")
        assert(fell.rest == nil or (type(fell.rest) == "number" and fell.rest > 0
            and fell.rest <= (fell.from or 1)), where .. " rest must be a position up to from")
        -- The sandbox has no `pairs`: the map is read through the listed devices.
        if fell.open ~= nil then
            assert(type(fell.open) == "table", where .. " open must map devices to devices")
            for _, slot in ipairs(fell.slots) do
                if fell.open[slot] ~= nil then lib.one(fell.open[slot], where .. " opened device") end
            end
        end
        assert(fell.count == nil
            or (math.type(fell.count) == "integer" and fell.count > 0 and fell.count <= #fell.slots),
            where .. " count must be a positive integer up to the number of slots")
    end
end

function devices.declare(content, builder)
    if #watched(content) == 0 then return end
    builder:end_kind("fell", function(_, fell)
        local wanted = fell.count or #fell.slots
        return {function(context, state)
            local fallen = 0
            for _, slot in ipairs(fell.slots) do
                if state:variable(fall_key(context, slot)) == DOWN then fallen = fallen + 1 end
            end
            return fallen >= wanted
        end}
    end)
end

function devices.build(content, builder)
    local list, slots = watched(content)
    if #list == 0 then return end
    local function down(context, state, event, entry)
        context:set_variable(fall_key(context, entry.slot), DOWN)
        if entry.open ~= nil then
            context:slot(entry.open):transition{transition = context.sdk.device_transitions.open}
        end
        builder:handle(context, state, event)
    end
    builder:on("on_event_device_state", function(context, state, event)
        local position = event.position
        if position == nil then return end
        for _, entry in ipairs(slots) do
            if lib.is_slot(context, event, entry.slot) then
                local key = fall_key(context, entry.slot)
                local stage = state:variable(key)
                if stage == nil and position + 0.001 >= entry.from then
                    context:set_variable(key, UP)
                elseif stage == UP and position < entry.below then
                    if entry.rest == nil then
                        down(context, state, event, entry)
                    else
                        context:set_variable(key, FELL)
                    end
                elseif stage == FELL and position < entry.rest then
                    context:set_variable(key, BOTTOM)
                elseif stage == BOTTOM and position + 0.001 >= entry.rest then
                    down(context, state, event, entry)
                end
                return
            end
        end
    end)
end

return devices
