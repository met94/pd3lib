--- AI controller helpers. `FreezePawn` disables AI via
--- `SBZAIController:SetAIEnabled(false, FName)` — proven to stop both movement
--- and shooting instantly (CrewLab) — with dedupe so a per-tick guard does not
--- re-call it, and a per-class unsupported cache for controllers that have no
--- `SetAIEnabled` (e.g. the Moon drone).
---
--- HARD RULE: never register a UE4SS hook on `SetAIEnabled` in a mod that
--- calls it. Calling a hooked UFunction from Lua re-enters the hook and crashes
--- (`push_nameproperty`); observation-only hooks on that function are safe, the
--- call is not.
---@class pd3.AI
local AI = {}

local Safe = require("pd3lib.core.safe")
local Log = require("pd3lib.core.log")

local Frozen = setmetatable({}, { __mode = "k" })
local Unsupported = {}

--- True when the controller's last disabled reason differs from ours (ours
--- was overridden by the game and should be re-applied).
---@param LastReason string?
---@param Reason string?
---@return boolean needsFreeze
function AI.NeedsFreeze(LastReason, Reason)
    return LastReason ~= Reason
end

--- Controller of a pawn: the `Controller` property first, `GetController()`
--- second. Nil when neither resolves to a valid object.
---@param Pawn any
---@return UObject? controller
function AI.ControllerOf(Pawn)
    if not Safe.IsValid(Pawn) then return nil end

    local Controller = Safe.Get(Pawn, "Controller")
    if Safe.IsValid(Controller) then return Controller end

    local Ok, Called = Safe.CallFn(Pawn, "GetController")
    if Ok and Safe.IsValid(Called) then return Called end
    return nil
end

--- Cache key: controller class short name, else the object's tostring.
---@param Controller any
---@return string key
local function CacheKey(Controller)
    local OkName, RawName = pcall(function() return Controller:GetClass():GetFName() end)
    if OkName then
        local Name = Safe.String(RawName)
        if Name ~= nil and Name ~= "" and Name ~= "nil" then return Name end
    end
    local OkStr, Str = pcall(tostring, Controller)
    return OkStr and Str or "unknown"
end

--- Disables AI on a pawn's controller, once. Returns true when the controller
--- is (or was already) frozen, false when it has no usable `SetAIEnabled`
--- (logged once per controller class).
---
--- Reading `LastDisabledReason` drives the dedupe:
---   * unreadable -> the in-memory frozen cache is used
---   * equal to Reason -> no call
---   * different -> re-apply (the game or another mod changed it)
---@param Pawn any
---@param Reason string? # FName text; must exist in the name pool (default "pd3lib")
---@return boolean ok
---@return string detail
function AI.FreezePawn(Pawn, Reason)
    Reason = Reason or "pd3lib"

    local Controller = AI.ControllerOf(Pawn)
    if Controller == nil then return false, "no controller" end

    local Key = CacheKey(Controller)
    if Unsupported[Key] then return false, "unsupported controller" end

    local RawLast = Safe.Get(Controller, "LastDisabledReason")
    local Last = nil
    if RawLast ~= nil then
        Last = Safe.String(RawLast)
        if Last == "" or Last == "nil" then Last = nil end
    end

    if Last == nil then
        if Frozen[Controller] then return true, "frozen (cached)" end
    elseif not AI.NeedsFreeze(Last, Reason) then
        return true, "already disabled: " .. tostring(Last)
    end

    local ReasonName = Safe.ToFName(Reason)
    if ReasonName == nil then return false, "reason not in FName pool: " .. tostring(Reason) end

    local Ok = Safe.CallFn(Controller, "SetAIEnabled", false, ReasonName)
    if Ok then
        Frozen[Controller] = true
        return true, "frozen"
    end

    Unsupported[Key] = true
    Log.Warn("ai: freeze unsupported for %s (no SetAIEnabled)", Key)
    return false, "SetAIEnabled unavailable"
end

--- True when the pawn's controller class previously failed to freeze.
---@param Pawn any
---@return boolean unsupported
function AI.IsFreezeUnsupported(Pawn)
    local Controller = AI.ControllerOf(Pawn)
    if Controller == nil then return false end
    return Unsupported[CacheKey(Controller)] == true
end

--- Number of controllers frozen through this module (weak-keyed cache).
---@return integer count
function AI.FrozenCount()
    local Count = 0
    for _ in pairs(Frozen) do Count = Count + 1 end
    return Count
end

--- Clears the frozen and unsupported caches (call on level change / restart).
function AI.Reset()
    Frozen = setmetatable({}, { __mode = "k" })
    Unsupported = {}
end

return AI
