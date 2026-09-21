--- Game-thread scheduling wrappers over UE4SS Execute* functions.
---@class pd3.Timers
local Timers = {}

local Log = require("pd3lib.core.log")

--- Runs Fn on the next game thread tick.
---@param Fn fun()
function Timers.InGameThread(Fn)
    ExecuteInGameThread(Fn)
end

--- Runs Fn on the game thread after Milliseconds have passed.
---@param Milliseconds integer
---@param Fn fun()
function Timers.After(Milliseconds, Fn)
    ExecuteWithDelay(Milliseconds, function()
        ExecuteInGameThread(Fn)
    end)
end

--- Repeats Fn every Milliseconds on the game thread.
---@param Milliseconds integer
---@param Fn fun()
---@return any handle # pass to Timers.Cancel
function Timers.Every(Milliseconds, Fn)
    return LoopInGameThreadWithDelay(Milliseconds, Fn)
end

--- Cancels a handle returned by Timers.Every (safe on nil/garbage handles).
---@param Handle any
function Timers.Cancel(Handle)
    if Handle ~= nil then
        local Ok, Err = pcall(CancelDelayedAction, Handle)
        if not Ok then
            Log.Debug("timers: Cancel failed: %s", tostring(Err))
        end
    end
end

return Timers
