-- Kill counts: a step ends once the combat objective's task counters have risen by a number of
-- kills since the step started.
--   ends = {kills = {objective = Slot.<OBJ>, count = n, of = {unit(...), ...},
--                    gone = {unit(...), ...}, settle_ms = 20000}}
-- The client reports one cumulative counter per objective task for the members of the squads
-- assigned to it, and only its rises reach the script. They are summed per attempt in a mission
-- variable, and a step records the sum when it starts, so a restart or an earlier fight does not
-- count. A squad the client never reports alive for still counts its kills here, which is what
-- makes this end the one for a wave whose squads a cohort cannot see. `gone` names squads the
-- objective does not count, such as ones on no task group: the end also waits until none of
-- their members is alive, as a clear reads it.
-- The client creates fewer members than asked at times, so `count` may never come. `of` names
-- the squads the count is made of: their created members are summed from the client's spawn
-- reports, and once `settle_ms` (default 20 s) have passed since the step started, the end also
-- holds when every created member is dead, that is when the kills since the step started reach
-- the members created in the attempt, at least one.
local lib = require("lib.mission_lib")

local kills = {name = "kills"}

local function total_key(context, objective)
    return "kills." .. tostring(context.attempt_generation) .. "." .. objective
end

local function base_key(context, step)
    return "kills.base." .. tostring(context.attempt_generation) .. "." .. step.id
end

local function created_key(context, source)
    return "created." .. tostring(context.attempt_generation) .. "." .. source
end

local function settled_key(context, step)
    return "kills.settled." .. tostring(context.attempt_generation) .. "." .. step.id
end

local DEFAULT_SETTLE_MS = 20000

local function settle_timer(content, step)
    return content.key .. ".kills." .. step.id
end

-- Every step end that counts kills, for checking, and the objectives they watch, each once.
local function watched(content)
    local seen, objectives, list = {}, {}, {}
    for _, step in ipairs(content.steps or {}) do
        local ends = step.ends or {}
        if ends.kills ~= nil then
            list[#list + 1] = {step = step, kills = ends.kills}
            if not seen[ends.kills.objective] then
                seen[ends.kills.objective] = true
                objectives[#objectives + 1] = ends.kills.objective
            end
        end
    end
    return list, objectives
end

function kills.check(content)
    for _, entry in ipairs(watched(content)) do
        local where = "step " .. tostring(entry.step.id) .. " kills"
        lib.one(entry.kills.objective, where .. " objective")
        assert(math.type(entry.kills.count) == "integer" and entry.kills.count > 0,
            where .. " count must be a positive integer")
        assert(entry.kills.gone == nil
            or (type(entry.kills.gone) == "table" and #entry.kills.gone > 0),
            where .. " gone must be a nonempty unit list")
        assert(entry.kills.of == nil
            or (type(entry.kills.of) == "table" and #entry.kills.of > 0),
            where .. " of must be a nonempty unit list")
        for _, unit in ipairs(entry.kills.of or {}) do lib.one(unit.source, where .. " of squad") end
        assert(entry.kills.settle_ms == nil or (math.type(entry.kills.settle_ms) == "integer"
            and entry.kills.settle_ms > 0), where .. " settle_ms must be a positive integer")
    end
end

function kills.declare(content, builder)
    if #watched(content) == 0 then return end
    -- The step's own `ends` is the holder field that runs when it starts, so the count the step
    -- measures from is the one at that moment.
    builder:action("ends", function(context, state, step, ends)
        if ends.kills ~= nil then
            context:set_variable(base_key(context, step),
                state:variable(total_key(context, ends.kills.objective)) or 0)
            if ends.kills.of ~= nil then
                context:set_variable(settled_key(context, step), false)
                context:start_timer(settle_timer(content, step),
                    ends.kills.settle_ms or DEFAULT_SETTLE_MS)
            end
        end
    end)
    builder:end_kind("kills", function(step, value)
        local gone = value.gone ~= nil and builder:need("encounters").gone(value.gone) or nil
        return {function(context, state)
            local total = state:variable(total_key(context, value.objective)) or 0
            local base = state:variable(base_key(context, step)) or 0
            local kills = total - base
            local enough = kills >= value.count
            if not enough and value.of ~= nil
                and state:variable(settled_key(context, step)) == true then
                local created = 0
                for _, unit in ipairs(value.of) do
                    created = created + (state:variable(created_key(context, unit.source)) or 0)
                end
                enough = created >= 1 and kills >= created
            end
            return enough and (gone == nil or gone(context, state))
        end}
    end)
end

function kills.build(content, builder)
    local list, objectives = watched(content)
    if #list == 0 then return end
    local sources, seen = {}, {}
    for _, entry in ipairs(list) do
        for _, unit in ipairs(entry.kills.of or {}) do
            if not seen[unit.source] then
                seen[unit.source], sources[#sources + 1] = true, unit.source
            end
        end
    end
    if #sources > 0 then
        -- A member the client created, per squad lane; the rise is the new members.
        builder:on("on_event_entity_spawned", function(context, state, event)
            for _, source in ipairs(sources) do
                if lib.is_slot(context, event, source) then
                    local rise = (event.count or 0) - (event.previous_count or 0)
                    if rise > 0 then
                        local key = created_key(context, source)
                        context:set_variable(key, (state:variable(key) or 0) + rise)
                    end
                    return
                end
            end
        end)
        builder:on("on_event_timer_elapsed", function(context, state, event)
            for _, entry in ipairs(list) do
                if entry.kills.of ~= nil and event.timer_name == settle_timer(content, entry.step) then
                    context:set_variable(settled_key(context, entry.step), true)
                    builder:handle(context, state, event)
                    return
                end
            end
        end)
    end
    builder:on("on_event_objective_progress", function(context, state, event)
        for _, objective in ipairs(objectives) do
            if lib.is_slot(context, event, objective) then
                local key = total_key(context, objective)
                local rise = (event.task_count or 0) - (event.previous_task_count or 0)
                if rise > 0 then
                    context:set_variable(key, (state:variable(key) or 0) + rise)
                end
                builder:handle(context, state, event)
                return
            end
        end
    end)
end

return kills
