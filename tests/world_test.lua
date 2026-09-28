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

-- Reset drops the cached controller so the next lookup re-resolves (level change).
local PC1, PC2 = { valid = true, id = "pc1" }, { valid = true, id = "pc2" }
local Current = PC1
FindAllOf = function() return { Current } end
check("controller resolved first", World.GetPlayerController() == PC1)
Current = PC2
check("controller cached", World.GetPlayerController() == PC1)
World.Reset()
check("reset re-resolves controller", World.GetPlayerController() == PC2)

-- Resolution prefers a local controller with a live pawn over a pawnless first entry.
local Wrong = { valid = true, id = "wrong" }
local LocalNoPawn = {
    valid = true, id = "local-nopawn",
    IsLocalController = function() return true end,
}
local LocalPawn = {
    valid = true, id = "local-pawn", Pawn = { valid = true },
    IsLocalController = function() return true end,
}
local RemotePawn = { valid = true, id = "remote-pawn", Pawn = { valid = true } }
local BrokenLocal = {
    valid = true, id = "broken-local", Pawn = { valid = true },
    IsLocalController = function() error("boom") end,
}

World.Reset()
FindAllOf = function() return { Wrong, LocalPawn } end
check("pawned local preferred", World.GetPlayerController() == LocalPawn)

World.Reset()
FindAllOf = function() return { RemotePawn, LocalNoPawn } end
check("local without pawn preferred over pawned remote", World.GetPlayerController() == LocalNoPawn)

World.Reset()
FindAllOf = function() return { Wrong, RemotePawn } end
check("pawned preferred when no local candidate", World.GetPlayerController() == RemotePawn)

World.Reset()
FindAllOf = function() return { BrokenLocal } end
check("IsLocalController error tolerated", World.GetPlayerController() == BrokenLocal)

-- A cached pawnless controller is replaced once a local one appears.
World.Reset()
FindAllOf = function() return { Wrong } end
check("pawnless controller cached", World.GetPlayerController() == Wrong)
FindAllOf = function() return { Wrong, LocalPawn } end
check("cache switches to local pawned", World.GetPlayerController() == LocalPawn)
World.Reset()
FindAllOf = function() return { Wrong } end
check("pawnless controller cached again", World.GetPlayerController() == Wrong)
FindAllOf = function() return { Wrong, LocalNoPawn } end
check("cache switches to local pawnless", World.GetPlayerController() == LocalNoPawn)

World.Reset()
FindAllOf = nil

IsValid = nil

return failures
