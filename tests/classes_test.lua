-- Pure tests for core.classes variant order and the incremental loader.
local Classes = require("pd3lib.core.classes")

-- Object validity stub: real UObjects resolve through IsValid; test states are
-- tables, so they opt out with valid = false when simulating a dead object.
IsValid = function(Value) return Value ~= nil and Value.valid ~= false end

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

local ObjectPath = "/Game/Chars/CH_Dozer.CH_Dozer_C"
local Variants = Classes.Variants(ObjectPath)
check("four variants for object path", #Variants == 4)
check("object LoadAsset first", Variants[1].Kind == "LoadAsset" and Variants[1].Arg == ObjectPath)
check("object FindObject second", Variants[2].Kind == "FindObject" and Variants[2].Arg == ObjectPath)
check("package LoadAsset third", Variants[3].Kind == "LoadAsset" and Variants[3].Arg == "/Game/Chars/CH_Dozer")
check("package FindObject fourth", Variants[4].Kind == "FindObject" and Variants[4].Arg == "/Game/Chars/CH_Dozer")
check("variant labels present", Variants[1].Label == "LoadAsset(object)" and Variants[3].Label == "LoadAsset(package)")

local NoDot = Classes.Variants("/Game/Foo")
check("dotless path dedupes args", #NoDot == 2)
check("dotless keeps kind order", NoDot[1].Kind == "LoadAsset" and NoDot[2].Kind == "FindObject")

local Resolved = { a = { name = "ClassA" }, b = { name = "ClassB" } }
local Calls = {}
local Loader = Classes.NewLoader({
    BudgetPerTick = 2,
    MaxAttempts = 3,
    Resolve = function(Path)
        Calls[#Calls + 1] = Path
        return Resolved[Path]
    end,
})

check("enqueue adds all", Loader:Enqueue({ "a", "b", "c" }) == 3)
check("enqueue skips resolved", Loader:Enqueue({ "a" }) == 0)
check("pending count", Loader:Pending() == 3)

local Processed = Loader:Step()
check("budget respected", Processed == 2 and #Calls == 2)
check("resolved get", Loader:Get("a") ~= nil and Loader:Get("a").name == "ClassA")
check("unresolved get nil", Loader:Get("c") == nil)
check("pending after step", Loader:Pending() == 1)

Loader:Step()
check("failed class retried next step", #Calls == 3 and Calls[3] == "c")
Loader:Step()
local _, _, GaveUp = Loader:Step()
check("gave up after max attempts", Loader:Get("c") == false)
check("step reports gave up", GaveUp == 1)
check("pending empty after give-up", Loader:Pending() == 0)

check("retry failed re-enqueues", Loader:RetryFailed() == 1)
check("retry state reset", Loader:Get("c") == nil)
check("retry pending", Loader:Pending() == 1)

local Solver = Classes.NewLoader({ Resolve = function(Path) return Path == "x" and "class-x" or nil end })
Solver:Enqueue({ "x" })
Solver:Step()
check("custom resolver used", Solver:Get("x") == "class-x")

-- A resolved class that died with the previous level must not be handed out.
local StaleClass = { valid = true, name = "stale" }
local StaleLoader = Classes.NewLoader({ Resolve = function() return StaleClass end })
StaleLoader:Enqueue({ "s1" })
StaleLoader:Step()
check("stale precondition resolved", StaleLoader:Get("s1") == StaleClass)
StaleClass.valid = false
check("stale state invalidated", StaleLoader:Get("s1") == nil)
StaleClass.valid = true
check("invalidated state re-enqueued", StaleLoader:Enqueue({ "s1" }) == 1)
StaleLoader:Step()
check("stale state re-resolved", StaleLoader:Get("s1") == StaleClass)

-- Reset clears resolved, queued and gave-up state for a new level.
local ResetLoader = Classes.NewLoader({
    BudgetPerTick = 2,
    Resolve = function(Path) return { name = Path, valid = true } end,
})
ResetLoader:Enqueue({ "r1", "r2" })
ResetLoader:Step()
check("reset precondition resolved", ResetLoader:Get("r1") ~= nil)
ResetLoader:Reset()
check("reset clears resolved", ResetLoader:Get("r1") == nil)
check("reset clears queue", ResetLoader:Pending() == 0)
check("reset allows re-enqueue", ResetLoader:Enqueue({ "r1" }) == 1)
ResetLoader:Step()
check("reset re-resolves", ResetLoader:Get("r1") ~= nil)

return failures
