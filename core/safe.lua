--- Error-tolerant accessors for UE4SS values. Every helper swallows errors
--- via pcall and never raises.
---@class pd3.Safe
local Safe = {}

local Unpack = table.unpack or unpack
local TextLibrary = nil

--- Returns true only when Value is a valid UObject (nil-safe).
---@param Value any
---@return boolean
local function SafeIsValid(Value)
    if Value == nil then return false end
    local Ok, Result = pcall(function() return Value:IsValid() end)
    return Ok and Result == true
end

--- Returns the cached KismetTextLibrary CDO, resolving it on first use.
---@return UObject? library
local function GetTextLibrary()
    if SafeIsValid(TextLibrary) then return TextLibrary end
    local Ok, Library = pcall(StaticFindObject, "/Script/Engine.Default__KismetTextLibrary")
    if Ok and SafeIsValid(Library) then
        TextLibrary = Library
    end
    return TextLibrary
end

--- Calls Fn in protected mode.
---@param Fn fun(...): ...
---@param ... any # forwarded to Fn
---@return boolean ok # false when Fn raised
---@return any ... # Fn's return values, or the error message when ok=false
function Safe.Call(Fn, ...)
    local Results = { pcall(Fn, ...) }
    local Ok = table.remove(Results, 1)
    if not Ok then return false, Results[1] end
    return true, Unpack(Results)
end

--- Reads Obj[Name], returning nil on error.
---@param Obj any
---@param Name string
---@return any value
function Safe.Get(Obj, Name)
    if Obj == nil then return nil end
    local Ok, Value = pcall(function() return Obj[Name] end)
    if not Ok then return nil end
    return Value
end

--- Writes Obj[Name] = Value in protected mode.
---@param Obj any
---@param Name string
---@param Value any
---@return boolean ok
---@return string? err # only when Obj is nil or the write raised
function Safe.Set(Obj, Name, Value)
    if Obj == nil then return false, "nil object" end
    return pcall(function() Obj[Name] = Value end)
end

--- Calls Obj:Name(...) in protected mode.
---@param Obj any
---@param Name string
---@param ... any # forwarded to the method
---@return boolean ok
---@return any ... # method return values
function Safe.CallFn(Obj, Name, ...)
    if Obj == nil then return false, "nil object" end
    local Args = { ... }
    local ArgCount = select("#", ...)
    return Safe.Call(function()
        return Obj[Name](Obj, Unpack(Args, 1, ArgCount))
    end)
end

--- Returns true only when Value is a valid UObject.
---@param Value any
---@return boolean
function Safe.IsValid(Value)
    return SafeIsValid(Value)
end

--- Human-readable description: "FullName [Class]" for objects, tostring otherwise.
--- Unwraps hook :get() wrappers; never invokes object methods on unknown
--- wrappers (calling e.g. GetFullName on a name/param wrapper crashes UE4SS).
---@param Value any
---@return string
function Safe.Describe(Value)
    if Value == nil then return "nil" end
    local Ok, Result = pcall(function()
        if type(Value) == "userdata" or type(Value) == "table" then
            local Target = Value
            local OkGet, Unwrapped = pcall(function() return Value:get() end)
            if OkGet and Unwrapped ~= nil then Target = Unwrapped end

            -- Object gate: never call object methods on non-object wrappers.
            -- type() exists on UObject/RemoteObject; string wrappers do not have it.
            local OkType = pcall(function() return Target:type() end)
            local LooksLikeObject = OkType
                or (HasMember(Target, "GetFullName") and not HasMember(Target, "ToString"))
            if LooksLikeObject then
                local OkName, Name = pcall(function() return Target:GetFullName() end)
                if OkName and Name ~= nil then
                    local OkClass, ClassName = pcall(function() return Target:GetClass():GetFullName() end)
                    return string.format("%s [%s]", tostring(Name), OkClass and tostring(ClassName) or "?")
                end
            end
        end
        return tostring(Value)
    end)
    if Ok then return Result end
    return "<unprintable>"
end

--- FText -> Lua string via :ToString(), falling back to KismetTextLibrary
--- Conv_TextToString and finally Safe.Describe.
---@param Value any
---@return string
function Safe.Text(Value)
    if Value == nil then return "nil" end
    local Ok, Str = pcall(function() return Value:ToString() end)
    if Ok and type(Str) == "string" then return Str end

    local Library = GetTextLibrary()
    if Library ~= nil then
        local OkConvert, Converted = pcall(function() return Library:Conv_TextToString(Value) end)
        if OkConvert and type(Converted) == "string" then return Converted end
    end

    return Safe.Describe(Value)
end

--- Returns true when Value[MemberName] is readable and non-nil.
---@param Value any
---@param MemberName string
---@return boolean
local function HasMember(Value, MemberName)
    local Ok, Member = pcall(function() return Value[MemberName] end)
    return Ok and Member ~= nil
end

--- Unwraps UE4SS value wrappers to the underlying value:
---   * RemoteUnrealParam / LocalUnrealParam -> :get()
---   * FString / FName / FText / FGuid     -> :ToString() (Lua string)
---   * UObject derivatives and unknown wrappers pass through unchanged
--- Never invokes object methods on unknown wrappers: calling e.g. GetFullName
--- on a name/param wrapper crashes UE4SS marshalling (push_nameproperty).
---@param Value any
---@param Depth? integer # internal recursion guard, max 3; omit when calling
---@return any resolved
function Safe.Resolve(Value, Depth)
    Depth = Depth or 0
    if Value == nil then return nil end
    if Depth > 3 then return Value end

    local ValueType = type(Value)
    if ValueType ~= "userdata" and ValueType ~= "table" then return Value end

    local OkGet, Inner = pcall(function() return Value:get() end)
    if OkGet and Inner ~= nil and Inner ~= Value then return Safe.Resolve(Inner, Depth + 1) end

    if HasMember(Value, "ToString") then
        local OkStr, Str = pcall(function() return Value:ToString() end)
        if OkStr and type(Str) == "string" then return Str end
    end

    return Value
end

--- Resolve then tostring for primitives; Safe.Describe fallback. Never nil.
---@param Value any
---@return string
function Safe.String(Value)
    local Resolved = Safe.Resolve(Value)
    if Resolved == nil then return "nil" end
    if type(Resolved) == "string" or type(Resolved) == "number" or type(Resolved) == "boolean" then
        return tostring(Resolved)
    end
    return Safe.Describe(Resolved)
end

--- Element count of array-like values. Arrays of structs may come back as
--- opaque "TrivialObject" wrappers that support neither # nor GetArrayNum;
--- callers must handle nil.
---@param Value any
---@return integer? count
function Safe.ArrayCount(Value)
    if Value == nil then return nil end
    local OkCount, Count = pcall(function() return #Value end)
    if OkCount and type(Count) == "number" then return Count end
    local OkNum, Num = pcall(function() return Value:GetArrayNum() end)
    if OkNum and type(Num) == "number" then return Num end
    return nil
end

--- Pre-builds an FName from a Lua string. This UE4SS build crashed argument
--- marshalling (push_nameproperty) when Lua strings were passed where FName
--- parameters were expected; pass the FName userdata returned here instead.
---@param Text string? # must already exist in the global name pool
---@return FName? name
---@return integer? index # comparison index, 0 means "not in pool"
function Safe.ToFName(Text)
    if Text == nil then return nil end
    local Ok, Name = pcall(FName, Text)
    if not Ok or Name == nil then return nil end
    local OkIdx, Index = pcall(function() return Name:GetComparisonIndex() end)
    if not OkIdx or type(Index) ~= "number" or Index == 0 then return nil end
    return Name, Index
end

--- Counts elements of Obj[Name] with #, returning nil on error.
---@param Obj any
---@param Name string
---@return integer? count
function Safe.Count(Obj, Name)
    local Array = Safe.Get(Obj, Name)
    if Array == nil then return nil end
    local Ok, Count = pcall(function() return #Array end)
    if Ok then return Count end
    return nil
end

--- Returns Value when it is a number, Default otherwise.
---@param Value any
---@param Default any
---@return any
function Safe.Num(Value, Default)
    if type(Value) == "number" then return Value end
    return Default
end

return Safe
