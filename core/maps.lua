--- Helpers for UE4SS TMap values.
---
--- This UE4SS build quirks:
---   * TMap:ForEach callback must NOT return a value - a non-nil return aborts
---     iteration with "attempt to call a nil value"; early-stop is unavailable,
---     count/skip inside the closure instead.
---   * pairs() never works on TMaps.
---   * TMap:Find is unavailable on some maps; Size returns nil then.
---@class pd3.Maps
local Maps = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")

--- Entry count of a TMap, or nil when the map type does not support #.
---@param Map TMap<any, any>?
---@return integer? size
function Maps.Size(Map)
    if Map == nil then return nil end
    local Ok, Count = pcall(function() return #Map end)
    if Ok and type(Count) == "number" then return Count end
    return nil
end

--- Looks up Key via Map:Find; nil when missing or unsupported.
---@param Map TMap<any, any>?
---@param Key any
---@return any value
function Maps.Find(Map, Key)
    if Map == nil then return nil end
    local Ok, Value = pcall(function() return Map:Find(Key) end)
    if Ok then return Value end
    return nil
end

--- True when Map:Contains(Key) reports true.
---@param Map TMap<any, any>?
---@param Key any
---@return boolean
function Maps.Contains(Map, Key)
    if Map == nil then return false end
    local Ok, Value = pcall(function() return Map:Contains(Key) end)
    return Ok and Value == true
end

--- Iterates a TMap. Fn receives (resolvedKey, rawValueWrapper); a callback
--- error is logged and iteration continues. The callback must not return a
--- value (see class remarks).
---@param Map TMap<any, any>?
---@param Fn fun(Key: any, Value: any)
---@return boolean ok
---@return string? err # "nil map" / "ForEach unavailable" / iteration error
function Maps.ForEach(Map, Fn)
    if Map == nil then return false, "nil map" end
    local OkMethod, Method = pcall(function() return Map.ForEach end)
    if not OkMethod or Method == nil then return false, "ForEach unavailable" end
    local OkIter, Err = pcall(function()
        Map:ForEach(function(KeyWrapper, ValueWrapper)
            local Key = Safe.Resolve(KeyWrapper)
            local OkCall, CallErr = pcall(Fn, Key, ValueWrapper)
            if not OkCall then
                Log.Err("maps.ForEach callback error: %s", tostring(CallErr))
            end
        end)
    end)
    if not OkIter then return false, tostring(Err) end
    return true
end

return Maps
