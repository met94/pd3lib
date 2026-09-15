local Hooks = {}
local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")

local Registry = {}

function Hooks.Hook(Path, Callback)
    local PreId, PostId
    local Ok, Err = pcall(function()
        PreId, PostId = RegisterHook(Path, function(Context, ...)
            local OkCallback, CallbackErr = pcall(Callback, Context, ...)
            if not OkCallback then
                Log.Err("hook %s callback error: %s", Path, tostring(CallbackErr))
            end
        end)
    end)

    if not Ok then
        Log.Warn("failed to hook %s: %s", Path, tostring(Err))
        return nil
    end

    Registry[#Registry + 1] = {
        Path = Path,
        PreId = PreId,
        PostId = PostId,
        Callback = Callback,
    }
    Log.Info("hook registered: %s", Path)
    return PreId
end

function Hooks.Unhook(Path, PreId)
    local Ok = false
    for Index = #Registry, 1, -1 do
        local Entry = Registry[Index]
        if Entry.Path == Path and Entry.PreId == PreId then
            Ok = pcall(function() UnregisterHook(Entry.Path, Entry.PreId, Entry.PostId) end)
            table.remove(Registry, Index)
            break
        end
    end
    return Ok
end

function Hooks.UnhookAll()
    for _, Entry in ipairs(Registry) do
        pcall(function() UnregisterHook(Entry.Path, Entry.PreId, Entry.PostId) end)
    end
    Registry = {}
end

function Hooks.Count()
    return #Registry
end

function Hooks.LogFire(Path, Context, ...)
    local Count = select("#", ...)
    local Parts = {}
    for Index = 1, Count do
        Parts[Index] = Safe.Describe((select(Index, ...)))
    end
    Log.Info("HOOK %s | ctx=%s | args: %s", Path, Safe.Describe(Context), table.concat(Parts, " | "))
end

function Hooks.HookLogged(Path, Callback)
    return Hooks.Hook(Path, function(Context, ...)
        Hooks.LogFire(Path, Context, ...)
        if Callback ~= nil then Callback(Context, ...) end
    end)
end

return Hooks
