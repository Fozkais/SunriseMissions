-- Declarative world changes any step, encounter or sequence item can carry:
--   move    = {to = "<device transition>", slots = {type-23 slots}, snap = true}
--   objects = {slots = {type-4 slots}, active = false}
--   signal  = {scene = mission.scenes.<NAME>, keys = {event keys}}  keys for an active scene
--   stop    = {mission.scenes.<NAME>, ...}                           ends each scene's generation
-- They run in that order, after the holder's own scenes.
local lib = require("lib.mission_lib")
local common = require("lib.campaign.common")

local actions = {name = "actions"}

local function slots(value, where)
    assert(type(value) == "table" and #value > 0, where .. " needs a nonempty slot list")
    for index = 1, #value do lib.one(value[index], where .. " slot " .. index) end
end

local function scene(value, where)
    assert(type(value) == "table" and type(value.id) == "string",
        where .. " must name a mission.scenes entry")
end

function actions.check(content)
    for _, place in ipairs(common.holders(content)) do
        local holder, where = place.holder, place.where
        if holder.move ~= nil then
            assert(type(holder.move.to) == "string", where .. " move needs a transition name")
            slots(holder.move.slots, where .. " move")
            assert(holder.move.snap == nil or type(holder.move.snap) == "boolean",
                where .. " move snap must be a boolean")
        end
        if holder.objects ~= nil then
            slots(holder.objects.slots, where .. " objects")
            assert(holder.objects.active == nil or type(holder.objects.active) == "boolean",
                where .. " objects active must be a boolean")
        end
        if holder.signal ~= nil then
            scene(holder.signal.scene, where .. " signal")
            local keys = holder.signal.keys
            assert(type(keys) == "table" and #keys > 0, where .. " signal needs keys")
            for number = 1, #keys do
                assert(math.type(keys[number]) == "integer" and keys[number] > 0,
                    where .. " signal key " .. number .. " must be a positive integer")
            end
        end
        if holder.stop ~= nil then
            assert(type(holder.stop) == "table" and #holder.stop > 0, where .. " stop needs scenes")
            for number = 1, #holder.stop do scene(holder.stop[number], where .. " stop") end
        end
    end
end

function actions.declare(_, builder)
    builder:action("move", function(context, _, _, move)
        local transition = context.sdk.device_transitions[move.to]
        for _, slot in ipairs(move.slots) do
            context:slot(slot):transition{transition = transition, snap = move.snap}
        end
    end)
    builder:action("objects", function(context, _, _, objects)
        context:activate_objects{slots = objects.slots, active = objects.active}
    end)
    builder:action("signal", function(context, _, _, signal)
        local target = context:scene(signal.scene.id)
        for _, key in ipairs(signal.keys) do target:send_event{key = key} end
    end)
    builder:action("stop", function(context, _, _, list)
        for _, target in ipairs(list) do context:scene(target.id):stop{} end
    end)
end

return actions
