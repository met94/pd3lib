--- Live GAS attribute values (FGameplayAttributeData members) from attribute
--- sets. All reads are reflection-driven, so missing fields resolve to nil
--- instead of raising; plain numeric properties on the same set are returned
--- as the current (and base) value.
---
--- Raw-memory reference for debugger work (verified on build 5.5.4, UE 5.5):
--- FGameplayAttributeData is 16 bytes with an 8-byte base, BaseValue at +8 and
--- CurrentValue at +12. Re-verify Attributes.Layout after every game update;
--- the reflection reads below do not depend on it.
---@class pd3.Attributes
local Attributes = {}

local Safe = require("pd3lib.core.safe")

--- FGameplayAttributeData layout constant used by raw-memory tooling.
---@type table<string, integer|string>
Attributes.Layout = {
    Build = "5.5.4",
    Size = 16,
    BaseValueOffset = 8,
    CurrentValueOffset = 12,
}

--- Current and base value of one attribute-set field.
--- FGameplayAttributeData members resolve to their `CurrentValue` / `BaseValue`;
--- plain numeric properties return the number for both; missing fields return nil.
---@param AttributeSet any # attribute set object
---@param Field string # property name, e.g. "Health" or "Armor"
---@return number? current
---@return number? base
function Attributes.Values(AttributeSet, Field)
    local Raw = Safe.Get(AttributeSet, Field)
    if Raw == nil then return nil, nil end
    local Resolved = Safe.Resolve(Raw)
    if type(Resolved) == "number" then return Resolved, Resolved end

    local Current = Safe.Num(Safe.Resolve(Safe.Get(Resolved, "CurrentValue")))
    local Base = Safe.Num(Safe.Resolve(Safe.Get(Resolved, "BaseValue")))
    if Current == nil and Base == nil then return nil, nil end
    return Current, Base
end

--- Current value only (nil when the field is missing or unreadable).
---@param AttributeSet any
---@param Field string
---@return number? current
function Attributes.Current(AttributeSet, Field)
    local Current = Attributes.Values(AttributeSet, Field)
    return Current
end

--- Base value only (nil when the field is missing or unreadable).
---@param AttributeSet any
---@param Field string
---@return number? base
function Attributes.Base(AttributeSet, Field)
    local _, Base = Attributes.Values(AttributeSet, Field)
    return Base
end

return Attributes
