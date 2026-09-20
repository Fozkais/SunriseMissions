-- Kill counts: a step ends once the combat objective's task counters have risen by a number of
-- kills since the step started.
--   ends = {kills = {objective = Slot.<OBJ>, count = n, gone = {unit(...), ...}}}
-- The client reports one cumulative counter per objective task for the members of the squads
-- assigned to it, and only its rises reach the script. They are summed per attempt in a mission
-- variable, and a step records the sum when it starts, so a restart or an earlier fight does not
-- count. A squad the client never reports alive for still counts its kills here, which is what
-- makes this end the one for a wave whose squads a cohort cannot see. `gone` names squads the
-- objective does not count, such as ones on no task group: the end also waits until none of
-- their members is alive, as a clear reads it.
local lib = require("lib.mission_lib")

local kills = {name = "kills"}

local function total_key(context, objective)
    return "kills." .. tostring(context.attempt_generation) .. "." .. objective
end

local function base_key(context, step)
    return "kills.base." .. tostring(context.attempt_generation) .. "." .. step.id
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
        end
    end)
    builder:end_kind("kills", function(step, value)
        local gone = value.gone ~= nil and builder:need("encounters").gone(value.gone) or nil
        return {function(context, state)
            local total = state:variable(total_key(context, value.objective)) or 0
            local base = state:variable(base_key(context, step)) or 0
            return total - base >= value.count and (gone == nil or gone(context, state))
        end}
    end)
end

function kills.build(content, builder)
    local list, objectives = watched(content)
    if #list == 0 then return end
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
