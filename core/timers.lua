local Timers = {}

function Timers.InGameThread(Fn)
    ExecuteInGameThread(Fn)
end

function Timers.After(Milliseconds, Fn)
    ExecuteWithDelay(Milliseconds, function()
        ExecuteInGameThread(Fn)
    end)
end

function Timers.Every(Milliseconds, Fn)
    return LoopInGameThreadWithDelay(Milliseconds, Fn)
end

function Timers.Cancel(Handle)
    if Handle ~= nil then
        pcall(CancelDelayedAction, Handle)
    end
end

return Timers
