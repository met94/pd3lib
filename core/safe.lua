local Safe = {}

local Unpack = table.unpack or unpack
local TextLibrary = nil

local function SafeIsValid(Value)
    if Value == nil then return false end
    local Ok, Result = pcall(function() return Value:IsValid() end)
    return Ok and Result == true
end

local function GetTextLibrary()
    if SafeIsValid(TextLibrary) then return TextLibrary end
    local Ok, Library = pcall(StaticFindObject, "/Script/Engine.Default__KismetTextLibrary")
    if Ok and SafeIsValid(Library) then
        TextLibrary = Library
    end
    return TextLibrary
end

function Safe.Call(Fn, ...)
    local Results = { pcall(Fn, ...) }
    local Ok = table.remove(Results, 1)
    if not Ok then return false, Results[1] end
    return true, Unpack(Results)
end

function Safe.Get(Obj, Name)
    if Obj == nil then return nil end
    local Ok, Value = pcall(function() return Obj[Name] end)
    if not Ok then return nil end
    return Value
end

function Safe.Set(Obj, Name, Value)
    if Obj == nil then return false, "nil object" end
    return pcall(function() Obj[Name] = Value end)
end

function Safe.CallFn(Obj, Name, ...)
    if Obj == nil then return false, "nil object" end
    local Args = { ... }
    local ArgCount = select("#", ...)
    return Safe.Call(function()
        return Obj[Name](Obj, Unpack(Args, 1, ArgCount))
    end)
end

function Safe.IsValid(Value)
    return SafeIsValid(Value)
end

function Safe.Describe(Value)
    if Value == nil then return "nil" end
    local Ok, Result = pcall(function()
        if type(Value) == "userdata" or type(Value) == "table" then
            local Target = Value
            local OkGet, Unwrapped = pcall(function() return Value:get() end)
            if OkGet and Unwrapped ~= nil then Target = Unwrapped end

            local OkName, Name = pcall(function() return Target:GetFullName() end)
            if OkName and Name ~= nil then
                local OkClass, ClassName = pcall(function() return Target:GetClass():GetFullName() end)
                return string.format("%s [%s]", tostring(Name), OkClass and tostring(ClassName) or "?")
            end
        end
        return tostring(Value)
    end)
    if Ok then return Result end
    return "<unprintable>"
end

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

function Safe.Count(Obj, Name)
    local Array = Safe.Get(Obj, Name)
    if Array == nil then return nil end
    local Ok, Count = pcall(function() return #Array end)
    if Ok then return Count end
    return nil
end

function Safe.Num(Value, Default)
    if type(Value) == "number" then return Value end
    return Default
end

return Safe
