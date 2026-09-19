-- Pathing: an encounter that names the task groups of its objective sends each of its squads to
-- the group that costs the least. The client reports every group's cost with each squad state.
-- A squad moves when another group is cheaper and stays put on a tie, which keeps it from
-- swapping between two zones whose quantised costs alternate.
--   groups = mission.TaskGroup.<OBJECTIVE>   on an encounter that also names its `objective`
local lib = require("lib.mission_lib")
local combat = require("lib.combat")

local pathing = {name = "pathing"}

-- An objective owns at most 24 task groups, named GROUP_0 to GROUP_23.
local GROUP_COUNT = 24

-- The groups of one objective in index order.
local function ordered(groups)
    local list = {}
    for index = 0, GROUP_COUNT - 1 do
        local group = groups["GROUP_" .. index]
        if group ~= nil then list[#list + 1] = group end
    end
    return list
end

local function relink(context, event, route, unit)
    local objective = context:slot(route.objective)
    local current, assigned = event:task_group{objective = objective}
    if not assigned then return end
    local selected, known = combat.lowest_cost(event, route.groups, current)
    if not known or selected == nil or combat.same_group(selected, current) then return end
    context:slot(unit.source):assign_combat_objective{objective = objective, task_group = selected}
end

function pathing.check(content)
    for _, encounter in ipairs(content.encounters or {}) do
        if encounter.groups ~= nil then
            assert(encounter.objective ~= nil, encounter.id .. " names task groups but no objective")
            assert(type(encounter.groups) == "table" and #ordered(encounter.groups) > 0,
                encounter.id .. " groups must be a mission.TaskGroup entry")
        end
    end
end

function pathing.build(content, builder)
    local routes = {}
    for _, encounter in ipairs(content.encounters or {}) do
        if encounter.groups ~= nil then
            routes[#routes + 1] = {objective = encounter.objective,
                groups = ordered(encounter.groups), squads = encounter.squads or {}}
        end
    end
    if #routes == 0 then return end
    -- A squad that reports nothing alive has no position to route from.
    builder:on("on_event_squad_state", function(context, _, event)
        if event.alive_count <= 0 then return end
        for _, route in ipairs(routes) do
            for _, unit in ipairs(route.squads) do
                if lib.is_slot(context, event, unit.source) then
                    relink(context, event, route, unit)
                    return
                end
            end
        end
    end)
end

return pathing
