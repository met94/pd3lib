-- Pure tests for core.world.PruneValid.
local World = require("pd3lib.core.world")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

IsValid = function(Value) return Value ~= nil and Value.valid == true end

local A, B, C = { valid = true, id = "a" }, { valid = false, id = "b" }, { valid = true, id = "c" }
local Lost = {}
local Survivors, LostCount = World.PruneValid({ A, B, C }, function(entry, index)
    Lost[#Lost + 1] = entry.id .. ":" .. index
end)
check("survivors kept in order", #Survivors == 2 and Survivors[1] == A and Survivors[2] == C)
check("lost count", LostCount == 1)
check("onLost entry and index", Lost[1] == "b:2")

local Intact = { A, C }
local Same, None = World.PruneValid(Intact, function() error("should not fire") end)
check("no-loss returns same table", Same == Intact and None == 0)

local Empty, EmptyLost = World.PruneValid({ B }, function() error("callback boom") end)
check("onLost error swallowed", #Empty == 0 and EmptyLost == 1)
check("nil list is empty", #World.PruneValid(nil) == 0)

IsValid = nil

return failures
