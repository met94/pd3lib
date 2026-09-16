--- Hook registry over UE4SS RegisterHook/UnregisterHook. Callbacks run wrapped
--- in pcall; callback errors are logged, never fatal.
---@class pd3.Hooks
local Hooks = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")

local Registry = {}

--- Registers a pre-hook on Path and tracks it for Unhook/UnhookAll.
---@param Path string # full UFunction path, e.g. "/Script/Starbreeze.SBZCharacter:Multicast_...:"
---@param Callback fun(Context: any, ...): any # Context is the owning object; args are wrappers
---@return integer? preId # hook id for Hooks.Unhook; nil when registration failed
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

--- Unregisters the tracked hook matching Path + preId.
---@param Path string
---@param PreId integer
---@return boolean ok # false when no matching entry exists
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

--- Unregisters every tracked hook.
function Hooks.UnhookAll()
    for _, Entry in ipairs(Registry) do
        pcall(function() UnregisterHook(Entry.Path, Entry.PreId, Entry.PostId) end)
    end
    Registry = {}
end

--- Number of tracked hooks.
---@return integer
function Hooks.Count()
    return #Registry
end

--- Logs a formatted hook fire line (context + described args).
---@param Path string
---@param Context any
---@param ... any # hook arguments (wrappers)
function Hooks.LogFire(Path, Context, ...)
    local Count = select("#", ...)
    local Parts = {}
    for Index = 1, Count do
        Parts[Index] = Safe.Describe((select(Index, ...)))
    end
    Log.Info("HOOK %s | ctx=%s | args: %s", Path, Safe.Describe(Context), table.concat(Parts, " | "))
end

--- Hook + LogFire on every invocation, then forwards to Callback.
---@param Path string
---@param Callback? fun(Context: any, ...): any # nil = log only
---@return integer? preId
function Hooks.HookLogged(Path, Callback)
    return Hooks.Hook(Path, function(Context, ...)
        Hooks.LogFire(Path, Context, ...)
        if Callback ~= nil then Callback(Context, ...) end
    end)
end

return Hooks
