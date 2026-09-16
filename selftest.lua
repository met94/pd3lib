--- Live-state PASS/FAIL smoke tests (bound to a key via pd3.Init).
---@class pd3.SelfTest
local SelfTest = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Hooks = require("pd3lib.core.hooks")
local Timers = require("pd3lib.core.timers")
local Maps = require("pd3lib.core.maps")
local Reflect = require("pd3lib.core.reflect")
local Entities = require("pd3lib.game.entities")
local Interact = require("pd3lib.game.interact")
local Shield = require("pd3lib.game.shield")
local Challenge = require("pd3lib.game.challenge")
local Mission = require("pd3lib.game.mission")

local ExtraChecks = {}

--- One registered check.
---@class pd3.SelfTest.Check
---@field Name string
---@field Fn fun(): boolean?, string? # returns ok, info; ok=false marks FAIL

--- Registers an extra check. Fn returning false (or raising) counts as FAIL.
---@param Name string
---@param Fn fun(): boolean?, string?
function SelfTest.Add(Name, Fn)
    ExtraChecks[#ExtraChecks + 1] = { Name = Name, Fn = Fn }
end

--- The built-in checks (world accessors, finders, interactor, hooks, timers, maps, reflect).
---@return pd3.SelfTest.Check[] checks
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
        {
            Name = "safe.Resolve/String",
            Fn = function()
                local OkFind, Statics = pcall(StaticFindObject, "/Script/Engine.Default__GameplayStatics")
                if not OkFind or not Safe.IsValid(Statics) then return false, "GameplayStatics not found" end
                local Resolved = Safe.Resolve(Statics:GetFName())
                local Text = Safe.String(Statics:GetFName())
                return type(Resolved) == "string" and type(Text) == "string", Text
            end,
        },
        {
            Name = "maps.Size/ForEach (challenge map)",
            Fn = function()
                local Map = Challenge.Achievements()
                if Map == nil then return true, "no challenge manager in this context" end
                local Count = 0
                local Ok = Maps.ForEach(Map, function() Count = Count + 1 end)
                return Ok, string.format("size=%s iterated=%d", tostring(Maps.Size(Map)), Count)
            end,
        },
        {
            Name = "challenge status names",
            Fn = function()
                return Challenge.StatusName(Challenge.CompletedStatus) == "COMPLETED", "COMPLETED==2"
            end,
        },
        {
            Name = "safe.ToFName",
            Fn = function()
                local OkFind, Statics = pcall(StaticFindObject, "/Script/Engine.Default__GameplayStatics")
                if not OkFind or not Safe.IsValid(Statics) then return false, "GameplayStatics not found" end
                local Text = Safe.String(Statics:GetFName())
                local Name, Index = Safe.ToFName(Text)
                return Name ~= nil and type(Index) == "number" and Index > 0,
                    string.format("%s idx=%s", Text, tostring(Index))
            end,
        },
        {
            Name = "reflect.DumpProperties",
            Fn = function()
                local OkFind, Statics = pcall(StaticFindObject, "/Script/Engine.Default__GameplayStatics")
                if not OkFind or not Safe.IsValid(Statics) then return false, "GameplayStatics not found" end
                local Lines = Reflect.DumpProperties(Statics, { MaxLines = 6, MaxArray = 2 })
                return #Lines > 0, string.format("%d lines, first=%s", #Lines, tostring(Lines[1]))
            end,
        },
        {
            Name = "mission state (info)",
            Fn = function()
                local State = Mission.Get()
                if State == nil then return true, "no live mission (menu)" end
                local Difficulty, Name = Mission.Difficulty(State)
                return true, string.format("difficulty=%s heistRef=%s", tostring(Name), tostring(Mission.HeistRef(State)))
            end,
        },
    }
end

--- Runs the built-in checks plus SelfTest.Add checks, logging PASS/FAIL lines.
---@return integer passed
---@return integer failed
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
