-- Development start: opens the campaign in a later leg, at one of its steps, as if everything
-- before that step had been played.
--   debug_start = {leg = "<leg id>", step = "<step id>"}
-- The mission arrives in that leg's region. The named step counts as played: it shows the goal the
-- played steps left and ends at once, so the step after it starts on arrival. Earlier steps, the
-- encounters that wait on them or on the arrival, and the intro cutscenes are dropped.
local debug = {}

local function index_of(list, id, what)
    for index, entry in ipairs(list) do
        if entry.id == id then return index end
    end
    assert(false, "debug_start names an unknown " .. what .. ": " .. tostring(id))
end

--- Applies `content.debug_start` to a content declaration, in place.
--- @return The declaration.
function debug.apply(content)
    local start = content.debug_start
    if start == nil then return content end
    local last = index_of(content.steps, start.step, "step")
    local leg = index_of(content.legs, start.leg, "leg")

    -- The goal the played steps left on the HUD.
    local goal
    for index = 1, last do
        if content.steps[index].directive ~= nil then goal = content.steps[index] end
    end
    -- Only its own end finishes the step, and it has none: a later step's trigger must not hold it.
    local held = {id = content.steps[last].id, barrier = true}
    if goal ~= nil then
        held.directive, held.navpoint, held.waypoint = goal.directive, goal.navpoint, goal.waypoint
    end

    local steps = {held}
    for index = last + 1, #content.steps do steps[#steps + 1] = content.steps[index] end

    -- Encounters wait on a step that has started; a played step's own are over.
    local played = {arrival = true}
    for index = 1, last do played[content.steps[index].id] = true end
    local encounters = {}
    for _, encounter in ipairs(content.encounters or {}) do
        if not played[encounter.after or "arrival"] then encounters[#encounters + 1] = encounter end
    end

    -- The first leg is where the mission opens; the others stay for the triggers steps end on.
    local legs = {content.legs[leg]}
    for index, entry in ipairs(content.legs) do
        if index ~= leg then legs[#legs + 1] = entry end
    end

    content.steps, content.encounters, content.legs = steps, encounters, legs
    content.intro = nil
    content.debug_start = nil
    return content
end

return debug
