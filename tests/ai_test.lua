-- Pure tests for game.ai freeze dedupe and unsupported-controller handling,
-- using a stubbed FName global (Safe.ToFName path) and fake controllers.
local AI = require("pd3lib.game.ai")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

FName = function(Text)
    return { __text = Text, GetComparisonIndex = function() return 7 end }
end
IsValid = function(Value) return Value ~= nil end

local function FakeController(SupportsFreeze, LastReason)
    local Ctrl = { LastDisabledReason = LastReason, Calls = 0 }
    Ctrl.SetAIEnabled = function(self, Enabled, Reason)
        self.Calls = self.Calls + 1
        self.LastSet = { Enabled = Enabled, Reason = Reason }
        if not SupportsFreeze then error("controller has no SetAIEnabled") end
        return true
    end
    Ctrl.GetFullName = function() return "FakeController" end
    Ctrl.GetClass = function() return Ctrl end
    return Ctrl
end

check("needs freeze nil reason", AI.NeedsFreeze(nil, "TrainingSpawner") == true)
check("needs freeze same reason", AI.NeedsFreeze("TrainingSpawner", "TrainingSpawner") == false)
check("needs freeze other reason", AI.NeedsFreeze("Other", "TrainingSpawner") == true)

AI.Reset()
local Ctrl = FakeController(true, nil)
local Pawn = { Controller = Ctrl }
local Ok, Detail = AI.FreezePawn(Pawn, "TrainingSpawner")
check("freeze ok", Ok == true and type(Detail) == "string")
check("SetAIEnabled called with false", Ctrl.Calls == 1 and Ctrl.LastSet.Enabled == false)
check("FName reason passed", Ctrl.LastSet.Reason ~= nil and Ctrl.LastSet.Reason.__text == "TrainingSpawner")
check("frozen count", AI.FrozenCount() == 1)
AI.FreezePawn(Pawn, "TrainingSpawner")
check("cached frozen skips repeated call", Ctrl.Calls == 1)

local AlreadyCtrl = FakeController(true, "TrainingSpawner")
AI.FreezePawn({ Controller = AlreadyCtrl }, "TrainingSpawner")
check("same last reason skips call", AlreadyCtrl.Calls == 0)

local ChangedCtrl = FakeController(true, "Other")
AI.FreezePawn({ Controller = ChangedCtrl }, "TrainingSpawner")
AI.FreezePawn({ Controller = ChangedCtrl }, "TrainingSpawner")
check("re-applies when reason changed", ChangedCtrl.Calls == 2)

local BadCtrl = FakeController(false, nil)
local BadPawn = { Controller = BadCtrl }
local OkBad = AI.FreezePawn(BadPawn, "TrainingSpawner")
check("unsupported freeze reports false", OkBad == false and BadCtrl.Calls == 1)
AI.FreezePawn(BadPawn, "TrainingSpawner")
check("unsupported class cached", BadCtrl.Calls == 1)
check("unsupported query", AI.IsFreezeUnsupported(BadPawn) == true)

local GetterCtrl = FakeController(true, nil)
local GetterPawn = { GetController = function() return GetterCtrl end }
check("GetController fallback used", AI.FreezePawn(GetterPawn, "TrainingSpawner") == true and GetterCtrl.Calls == 1)

AI.Reset()
check("reset clears frozen count", AI.FrozenCount() == 0)
check("reset clears unsupported", AI.IsFreezeUnsupported(BadPawn) == false)

FName = nil
IsValid = nil

return failures
