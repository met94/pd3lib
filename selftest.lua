local SelfTest = {}
local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Hooks = require("pd3lib.core.hooks")
local Timers = require("pd3lib.core.timers")
local Entities = require("pd3lib.game.entities")
local Interact = require("pd3lib.game.interact")
local Shield = require("pd3lib.game.shield")

local ExtraChecks = {}

function SelfTest.Add(Name, Fn)
    ExtraChecks[#ExtraChecks + 1] = { Name = Name, Fn = Fn }
end

local function DefaultChecks()
    return {
        {
            Name = "log",
            Fn = function()
                Log.Info("selftest: log works")
                return true
            end,
        },
        {
            Name = "safe.Describe(PlayerController)",
            Fn = function()
                local Controller = World.GetPlayerController()
                return Safe.IsValid(Controller), Safe.Describe(Controller)
            end,
        },
        {
            Name = "world.GetPawn",
            Fn = function()
                local Pawn = World.GetPawn()
                return Safe.IsValid(Pawn), Safe.Describe(Pawn)
            end,
        },
        {
            Name = "world.GetLevelName",
            Fn = function()
                local Name = World.GetLevelName()
                return Name ~= nil, tostring(Name)
            end,
        },
        {
            Name = "entities.Civilians",
            Fn = function()
                local Count = #Entities.Civilians()
                return true, tostring(Count) .. " found"
            end,
        },
        {
            Name = "entities.CrewPawns",
            Fn = function()
                local Count = #Entities.CrewPawns()
                return true, tostring(Count) .. " found"
            end,
        },
        {
            Name = "interact.PlayerInteractor",
            Fn = function()
                local Pawn = World.GetPawn()
                local InteractorRef = Interact.PlayerInteractor(Pawn)
                return Safe.IsValid(InteractorRef), Safe.Describe(InteractorRef)
            end,
        },
        {
            Name = "hooks register/unhook",
            Fn = function()
                local PreId = Hooks.Hook(Interact.HookPaths.SimulatedComplete, function() end)
                if PreId == nil then return false, "register failed" end
                Hooks.Unhook(Interact.HookPaths.SimulatedComplete, PreId)
                return true, "ok"
            end,
        },
        {
            Name = "timers.After",
            Fn = function()
                Timers.After(1, function() end)
                return true, "scheduled"
            end,
        },
        {
            Name = "shield AI instigator flag",
            Fn = function()
                return Shield.AIInstigatorUnsupported == true, "AI instigator marked unsupported"
            end,
        },
    }
end

function SelfTest.Run()
    Log.Info("=== pd3lib selftest ===")

    local All = {}
    for _, Check in ipairs(DefaultChecks()) do All[#All + 1] = Check end
    for _, Check in ipairs(ExtraChecks) do All[#All + 1] = Check end

    local Passed, Failed = 0, 0
    for _, Check in ipairs(All) do
        local Ok, Result, Info = pcall(Check.Fn)
        if not Ok then
            Failed = Failed + 1
            Log.Warn("FAIL %s: %s", Check.Name, tostring(Result))
        elseif Result == false then
            Failed = Failed + 1
            Log.Warn("FAIL %s: %s", Check.Name, tostring(Info))
        else
            Passed = Passed + 1
            Log.Info("PASS %s: %s", Check.Name, tostring(Info))
        end
    end

    Log.Info("=== selftest done: %d passed, %d failed ===", Passed, Failed)
    return Passed, Failed
end

return SelfTest
