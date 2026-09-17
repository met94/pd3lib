--- Heist-scoped activation callbacks. `Watch` fires Enter when the live mission's
--- heist ref matches and Exit when leaving the heist, so mods can keep hooks and
--- timers idle outside their heist. Detection runs once per level init (deferred
--- out of hook context); there is no continuous polling.
---@class pd3.Heist
local Heist = {}

local Log = require("pd3lib.core.log")
local Timers = require("pd3lib.core.timers")
local Lifecycle = require("pd3lib.core.lifecycle")
local Mission = require("pd3lib.game.mission")

--- Reasons passed to Exit callbacks.
---@type table<string, string>
Heist.ExitReasons = {
    Menu = "menu",
    Restart = "restart",
    Level = "level",
    Unwatch = "unwatch",
}

--- Callbacks for Heist.Watch.
---@class pd3.Heist.Callbacks
---@field Enter? fun(ref: string) # heist ref matched; the session is now active
---@field Exit? fun(ref: string, reason: string) # session over; reason is a Heist.ExitReasons value

local Watchers = {}
local NextId = 0
local ActiveRef = nil
local HooksInstalled = false

---@param Ref string
---@return boolean
local function IsWatched(Ref)
    for _, Watcher in ipairs(Watchers) do
        if Watcher.Ref == Ref then return true end
    end
    return false
end

---@param Callbacks pd3.Heist.Callbacks?
---@param Name string
---@param ... any
local function Fire(Callbacks, Name, ...)
    local Fn = Callbacks ~= nil and Callbacks[Name] or nil
    if Fn == nil then return end
    local Ok, Err = pcall(Fn, ...)
    if not Ok then
        Log.Err("heist %s callback error: %s", Name, tostring(Err))
    end
end

--- Marks the session inactive and fires Exit on every watcher for the ref.
---@param Reason string
local function Deactivate(Reason)
    local Ref = ActiveRef
    if Ref == nil then return end
    ActiveRef = nil
    Log.Info("heist inactive: %s (%s)", Ref, Reason)
    for _, Watcher in ipairs(Watchers) do
        if Watcher.Ref == Ref then
            Fire(Watcher.Callbacks, "Exit", Ref, Reason)
        end
    end
end

--- Marks the session active and fires Enter on every matching watcher.
---@param Ref string
local function Activate(Ref)
    if ActiveRef == Ref then return end
    ActiveRef = Ref
    Log.Info("heist active: %s", Ref)
    for _, Watcher in ipairs(Watchers) do
        if Watcher.Ref == Ref then
            Fire(Watcher.Callbacks, "Enter", Ref)
        end
    end
end

--- Reads the live heist ref and activates matching watchers. Never called from
--- hook context: UFunction calls inside hook callbacks are unsafe.
local function Detect()
    local Ref = Mission.HeistRef()
    if Ref == nil or Ref == "" then
        Log.Debug("heist ref not readable")
        return
    end
    Ref = tostring(Ref)
    if not IsWatched(Ref) then
        Deactivate(Heist.ExitReasons.Level)
        Log.Debug("heist %s not watched", Ref)
        return
    end
    if ActiveRef ~= nil and ActiveRef ~= Ref then
        Deactivate(Heist.ExitReasons.Level)
    end
    Activate(Ref)
end

local function InstallHooks()
    if HooksInstalled then return end
    HooksInstalled = true

    Lifecycle.OnLevelInit(function()
        Deactivate(Heist.ExitReasons.Level)
        Timers.After(0, Detect)
    end)
    Lifecycle.OnLevelRestart(function()
        -- Re-arm happens on the following level init; detecting here would arm
        -- against the tearing-down level and arm/disarm twice per restart.
        Deactivate(Heist.ExitReasons.Restart)
    end)
    Lifecycle.OnReturnToMenu(function()
        Deactivate(Heist.ExitReasons.Menu)
    end)
end

--- Watches a heist ref and invokes callbacks when it becomes/stops being the
--- live mission. Detection runs on level init and once at Watch time; a level
--- restart fires Exit and the following level init re-arms. Mission end does
--- not fire Exit: the mission state stays alive until the level changes, so
--- watchers that unlock things on mission end keep working.
---@param Ref string # heist ref token such as "penthouse"
---@param Callbacks pd3.Heist.Callbacks
---@return integer? id # pass to Heist.Unwatch; nil when arguments are invalid
function Heist.Watch(Ref, Callbacks)
    if type(Ref) ~= "string" or Ref == "" or type(Callbacks) ~= "table" then
        Log.Warn("heist.Watch: invalid ref or callbacks")
        return nil
    end
    NextId = NextId + 1
    local Id = NextId
    Watchers[#Watchers + 1] = { Id = Id, Ref = Ref, Callbacks = Callbacks }
    InstallHooks()
    Timers.After(0, Detect)
    return Id
end

--- Removes a watcher; fires its Exit when it was the active session.
---@param Id integer
---@return boolean ok # false when no watcher has the id
function Heist.Unwatch(Id)
    for Index = #Watchers, 1, -1 do
        local Watcher = Watchers[Index]
        if Watcher.Id == Id then
            table.remove(Watchers, Index)
            if ActiveRef == Watcher.Ref and not IsWatched(Watcher.Ref) then
                Deactivate(Heist.ExitReasons.Unwatch)
            end
            return true
        end
    end
    return false
end

--- Heist ref currently active for this mod, or nil.
---@return string? ref
function Heist.Active()
    return ActiveRef
end

--- Re-runs detection on the next tick (debug/testing).
function Heist.Probe()
    Timers.After(0, Detect)
end

return Heist
