-- Encounters: squads placed once their step has started and their trigger or monitor reported.
-- They live in a second graph, so each graph stays inside the step and fact limits.
local lib = require("lib.mission_lib")
local flow = require("lib.flow")
local common = require("lib.campaign.common")
local speak = common.speak

local encounters = {name = "encounters"}

-- Assign the objective before the placement. A squad body that changes after its members exist
-- reports alive 0 for about a second, and a cohort reads that as cleared. A unit with a count
-- places every member lane at that count instead of the package default. A unit with no group of
-- its own starts on the approach group, when the holder names one.
local function place_units(context, objective, units, approach)
    for _, unit in ipairs(units or {}) do
        if objective ~= nil then
            context:slot(unit.source):assign_combat_objective{
                objective = context:slot(objective), task_group = unit.group or approach,
            }
        end
        local squad = context:squad(unit.squad)
        local request = {}
        if unit.count ~= nil then
            local counts = squad:counts()
            for lane = 1, counts.count do counts:set(lane, unit.count) end
            request.counts = counts
        end
        squad:place(request)
    end
end

-- A squad that reported members alive in this attempt: the mark is a mission variable.
local function seen_key(context, source)
    return "seen." .. tostring(context.attempt_generation) .. "." .. source
end

local function populate(content, builder, context, state, encounter)
    place_units(context, encounter.objective, encounter.squads, encounter.approach)
    speak(content, context, encounter)
    builder:run_actions(context, state, encounter)
    if encounter.on_start ~= nil then encounter.on_start(context) end
end

function encounters.check(content, builder)
    local legs = builder:need("legs")
    for _, place in ipairs(common.holders(content)) do
        local squads = place.holder.place
        if squads ~= nil then
            assert(place.item, place.where .. " place belongs in a sequence item")
            assert(type(squads.squads) == "table" and #squads.squads > 0,
                place.where .. " place needs a nonempty squad list")
        end
        local assign = place.holder.assign
        if assign ~= nil then
            lib.one(assign.objective, place.where .. " assign objective")
            assert(type(assign.group) == "table" and assign.group.group_index ~= nil,
                place.where .. " assign needs one mission.TaskGroup group")
            assert(type(assign.squads) == "table" and #assign.squads > 0,
                place.where .. " assign needs a nonempty squad list")
        end
    end
    for _, encounter in ipairs(content.encounters or {}) do
        lib.one(encounter.id, "encounter id")
        assert(legs.step_ids[encounter.after or "arrival"],
            encounter.id .. " waits on an unknown step")
        if encounter.trigger ~= nil then
            assert(legs.armed[encounter.trigger], encounter.id .. " waits on a trigger no leg arms")
        end
        if encounter.monitor ~= nil then
            assert(legs.watched[encounter.monitor],
                encounter.id .. " waits on a monitor no leg watches")
        end
    end
end

function encounters.declare(content, builder)
    -- Gives squads already alive their group. A new evaluation would move them onto their task,
    -- so it keeps the revision the placement or the performance left.
    builder:action("assign", function(context, _, _, assign)
        for _, unit in ipairs(assign.squads) do
            context:slot(unit.source):assign_combat_objective{
                objective = context:slot(assign.objective), task_group = assign.group}
        end
    end)
    -- A sequence item places its own squads later than its encounter does.
    builder:action("place", function(context, _, _, place)
        place_units(context, place.objective, place.squads, place.approach)
    end)
    local placed = {}
    for _, encounter in ipairs(content.encounters or {}) do placed[encounter.id] = encounter end
    -- `graph` is the placement graph, set by build; nil when no encounter declares a placement.
    local service = {}
    --- An encounter's squads are its own and the ones its sequence items place; a cohort with a
    --- squad not placed yet is not cleared, so the condition waits for the whole sequence. The
    --- runtime's own `cleared` also wants every requested member seen, and the client places
    --- fewer than asked at times, so a cohort whose every squad reported members alive once in
    --- this attempt and now reports none alive counts as cleared too.
    --- @return A condition that holds once every squad of the named encounters is gone.
    function service.cleared(ids)
        local units = {}
        for _, id in ipairs(ids) do
            local encounter = lib.one(placed[id], "encounter " .. id)
            local own = 0
            for _, unit in ipairs(encounter.squads or {}) do
                units[#units + 1], own = unit, own + 1
            end
            for _, item in ipairs(encounter.sequence or {}) do
                for _, unit in ipairs(item.place ~= nil and item.place.squads or {}) do
                    units[#units + 1], own = unit, own + 1
                end
            end
            assert(own > 0, "encounter " .. id .. " places no squad to clear")
        end
        return service.gone(units)
    end
    --- @return A condition that holds once every listed unit's squad is gone, as `cleared`
    --- reads it. A squad listed twice is one member of the cohort.
    function service.gone(units)
        local seen, unique, sources = {}, {}, {}
        for _, unit in ipairs(units) do
            if not seen[unit.squad] then
                seen[unit.squad], unique[#unique + 1] = true, unit.squad
                sources[#sources + 1] = unit.source
            end
        end
        assert(#unique > 0, "a clear needs at least one squad")
        return function(context, state)
            local cohort = context:cohort{squads = unique}
            if cohort.cleared then return true end
            if cohort.alive_count ~= 0 then return false end
            for _, source in ipairs(sources) do
                if state:variable(seen_key(context, source)) ~= true then return false end
            end
            return true
        end
    end
    --- @return True once the named encounter has placed in this attempt.
    function service.placed(context, state, id)
        return service.graph ~= nil and service.graph:started(context, state, id)
    end
    builder:provide("encounters", service)
end

function encounters.build(content, builder)
    -- Which squads have had members alive, for the clear conditions.
    builder:on("on_event_squad_state", function(context, _, event)
        local id = event.slot ~= nil and event.slot.id or nil
        if id ~= nil and (event.alive_count or 0) > 0 then
            context:set_variable(seen_key(context, id), true)
        end
    end)
    local facts, fact_of, graph = {}, {}, nil
    for _, encounter in ipairs(content.encounters or {}) do
        local source = encounter.trigger or encounter.monitor
        if source ~= nil and fact_of[source] == nil then
            local id = "t" .. (#facts + 1)
            fact_of[source] = id
            facts[#facts + 1] = {id = id, observe = function(context, _, event)
                return lib.is_slot(context, event, source)
            end}
        end
    end
    -- Trigger facts latch, so an encounter whose trigger fired early places once its step starts.
    local core = builder:need("core")
    local placements = {}
    for _, encounter in ipairs(content.encounters or {}) do
        local after = encounter.after or "arrival"
        local source = encounter.trigger or encounter.monitor
        -- The arrival step is waiting from the start, so arrival itself must have happened.
        local function begun(context, state)
            if after == "arrival" then return core.graph():fact(context, state, "arrival") end
            return core.graph():started(context, state, after)
        end
        local when = function(context, state)
            return begun(context, state) and (source == nil
                or graph:fact(context, state, fact_of[source]))
        end
        placements[#placements + 1] = {id = encounter.id, when = when,
            run = function(context, state)
                populate(content, builder, context, state, encounter)
            end}
    end
    if #placements > 0 then
        graph = flow.new{key = content.key .. ".enc", facts = facts, steps = placements}
        builder:graph(graph)
        builder:need("encounters").graph = graph
    end
end

return encounters
