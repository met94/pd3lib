--- Level/mission lifecycle callbacks. Registration is lazy: the underlying
--- hooks are installed on the first registered callback.
---@class pd3.Lifecycle
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

--- Appends Fn to the named callback list and ensures hooks are installed.
---@param Name string # key of Callbacks
---@param Fn function
local function Add(Name, Fn)
    Callbacks[Name][#Callbacks[Name] + 1] = Fn
    Lifecycle.Register()
end

--- Fires every callback registered under Name; errors are logged per callback.
---@param Name string
---@param ... any # forwarded to the callbacks
local function Fire(Name, ...)
    for _, Fn in ipairs(Callbacks[Name]) do
        local Ok, Err = pcall(Fn, ...)
        if not Ok then
            Log.Err("lifecycle %s callback error: %s", Name, tostring(Err))
        end
    end
end

--- Registers a callback for playable level init.
---@param Fn fun(LevelName: string?) # level name may be nil if lookup failed
function Lifecycle.OnLevelInit(Fn)
    Add("LevelInit", Fn)
end

--- Registers a callback for level restart (no arguments).
---@param Fn fun()
function Lifecycle.OnLevelRestart(Fn)
    Add("LevelRestart", Fn)
end

--- Registers a callback for mission end requests (no arguments).
---@param Fn fun()
function Lifecycle.OnMissionEnd(Fn)
    Add("MissionEnd", Fn)
end

--- Registers a callback for return-to-main-menu requests (no arguments).
---@param Fn fun()
function Lifecycle.OnReturnToMenu(Fn)
    Add("ReturnToMenu", Fn)
end

--- Installs the four SBZ engine hooks once; repeat calls are no-ops.
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
