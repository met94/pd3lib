local Lifecycle = {}
local Hooks = require("pd3lib.core.hooks")
local Log = require("pd3lib.core.log")
local World = require("pd3lib.core.world")

local Registered = false
local Callbacks = {
    LevelInit = {},
    LevelRestart = {},
    MissionEnd = {},
    ReturnToMenu = {},
}

local function Add(Name, Fn)
    Callbacks[Name][#Callbacks[Name] + 1] = Fn
    Lifecycle.Register()
end

local function Fire(Name, ...)
    for _, Fn in ipairs(Callbacks[Name]) do
        local Ok, Err = pcall(Fn, ...)
        if not Ok then
            Log.Err("lifecycle %s callback error: %s", Name, tostring(Err))
        end
    end
end

function Lifecycle.OnLevelInit(Fn)
    Add("LevelInit", Fn)
end

function Lifecycle.OnLevelRestart(Fn)
    Add("LevelRestart", Fn)
end

function Lifecycle.OnMissionEnd(Fn)
    Add("MissionEnd", Fn)
end

function Lifecycle.OnReturnToMenu(Fn)
    Add("ReturnToMenu", Fn)
end

function Lifecycle.Register()
    if Registered then return end
    Registered = true

    Hooks.Hook("/Script/Starbreeze.SBZGameplayManager:OnPlayableLevelInitialized", function()
        Fire("LevelInit", World.GetLevelName())
    end)
    Hooks.Hook("/Script/Starbreeze.SBZGameplayManager:OnRestartLevelStarted", function()
        Fire("LevelRestart")
    end)
    Hooks.Hook("/Script/Starbreeze.SBZGameStateMachine:RequestMissionEnd", function()
        Fire("MissionEnd")
    end)
    Hooks.Hook("/Script/Starbreeze.SBZGameStateMachine:RequestReturnToMainMenu", function()
        Fire("ReturnToMenu")
    end)
end

return Lifecycle
