--- Reflection-driven dumpers. Everything is introspection-driven (property
--- and struct metadata) so dumps keep working after game updates; missing
--- members are reported, never fatal. Output is budgeted and truncation is
--- always logged; known-freeze properties (ModeArray/ModeDataArray) are
--- skipped by default.
---@class pd3.Reflect
---@field Defaults pd3.Reflect.Options # global defaults used when a call passes no Opts
local Reflect = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")

--- Per-call dump options; missing fields fall back to Reflect.Defaults.
---@class pd3.Reflect.Options
---@field MaxDepth? integer # nested struct recursion depth (objects are described, not recursed); default 1
---@field MaxArray? integer # array elements printed per array; 0 = unlimited; default 25
---@field MaxString? integer # max chars per formatted value; 0 = unlimited; default 200
---@field MaxLines? integer # max output lines per dump; 0 = unlimited; default 400
---@field Filter? string # property-name substring; non-empty limits DumpProperties output
---@field Skip? table<string, boolean> # property names never dumped

---@type pd3.Reflect.Options
Reflect.Defaults = {
    MaxDepth = 1,   -- nested struct recursion depth (objects are described, not recursed)
    MaxArray = 25,  -- array elements printed per array; 0 = unlimited
    MaxString = 200, -- max chars per formatted value; 0 = unlimited
    MaxLines = 400, -- max output lines per dump; 0 = unlimited
    Skip = {
        ModeArray = true,
        ModeDataArray = true,
    },
}

--- Merges Overrides into Reflect.Defaults (shallow; Skip is replaced whole).
---@param Overrides? pd3.Reflect.Options
function Reflect.SetDefaults(Overrides)
    for Key, Value in pairs(Overrides or {}) do
        Reflect.Defaults[Key] = Value
    end
end

--- Resolves effective options: defaults overlaid with Opts.
---@param Opts? pd3.Reflect.Options # per-call overrides
---@return pd3.Reflect.Options
local function Options(Opts)
    local Result = {}
    for Key, Value in pairs(Reflect.Defaults) do Result[Key] = Value end
    for Key, Value in pairs(Opts or {}) do Result[Key] = Value end
    return Result
end

--- True when Obj[MethodName] is readable and non-nil.
---@param Obj any
---@param MethodName string
---@return boolean
local function HasMethod(Obj, MethodName)
    if Obj == nil then return false end
    local Ok, Member = pcall(function() return Obj[MethodName] end)
    return Ok and Member ~= nil
end

--- FProperty class names in IsA probe order.
local PropertyTagOrder = {
    "StructProperty", "ArrayProperty", "MapProperty", "SetProperty",
    "ObjectProperty", "ObjectPtrProperty", "WeakObjectProperty", "ClassProperty", "InterfaceProperty",
    "EnumProperty", "ByteProperty", "BoolProperty",
    "IntProperty", "Int64Property", "UInt16Property", "UInt32Property", "UInt64Property",
    "FloatProperty", "DoubleProperty",
    "StrProperty", "NameProperty", "TextProperty",
    "DelegateProperty", "MulticastDelegateProperty",
}

--- Short type tag of a UScriptStruct/UScriptClass property (e.g. "StructProperty").
---@param Property UObject? # FProperty
---@return string tag # "Property" when the class is unknown, "?" when nil
local function PropertyTag(Property)
    if Property == nil then return "?" end
    for _, Key in ipairs(PropertyTagOrder) do
        local Constant = PropertyTypes ~= nil and PropertyTypes[Key] or nil
        if Constant ~= nil then
            local Ok, Is = pcall(function() return Property:IsA(Constant) end)
            if Ok and Is == true then return Key end
        end
    end
    return "Property"
end

--- UScriptStruct schema behind a struct FProperty.
---@param Property UObject? # FProperty
---@return UObject? schema
local function StructSchemaOf(Property)
    if Property == nil then return nil end
    local Ok, Schema = pcall(function()
        if Property:IsA(PropertyTypes.StructProperty) then
            return Property:GetStruct()
        end
        return nil
    end)
    if Ok and Schema ~= nil then return Schema end
    return nil
end

--- UScriptStruct schema of an array FProperty's element type (struct arrays only).
---@param Property UObject? # FProperty
---@return UObject? schema
local function ArrayElementSchemaOf(Property)
    if Property == nil then return nil end
    local Ok, Inner = pcall(function()
        if Property:IsA(PropertyTypes.ArrayProperty) then
            return Property:GetInner()
        end
        return nil
    end)
    if not Ok or Inner == nil then return nil end
    return StructSchemaOf(Inner)
end

--- Clamps Text to Max chars, appending "...<+N chars>" when truncated.
---@param Text any
---@param Max integer? # 0/nil = unlimited
---@return string
local function Truncate(Text, Max)
    Text = tostring(Text)
    if Max ~= nil and Max > 0 and #Text > Max then
        return string.sub(Text, 1, Max) .. "...<+" .. (#Text - Max) .. " chars>"
    end
    return Text
end

local Format

--- Formats one struct value as "{Field=Value, ...}", capped at 64 fields.
---@param Value any # struct value (wrapper or table)
---@param Schema UObject # UScriptStruct
---@param Options pd3.Reflect.Options
---@param Depth integer
---@return string
local function FormatStructFields(Value, Schema, Options, Depth)
    local Parts = {}
    local Total, Printed = 0, 0
    local OkIter = pcall(function()
        Schema:ForEachProperty(function(Property)
            Total = Total + 1
            if Printed < 64 then
                Printed = Printed + 1
                local Name = Safe.String(Property:GetFName())
                local FieldValue = Safe.Get(Value, Name)
                Parts[#Parts + 1] = Name .. "=" .. Format(FieldValue, Options, Depth - 1, Property)
            end
        end)
    end)
    if not OkIter then return "<struct unreadable>" end
    if Total > Printed then Parts[#Parts + 1] = "...<" .. (Total - Printed) .. " more fields>" end
    return "{" .. table.concat(Parts, ", ") .. "}"
end

--- Formats an array value as "[e1, e2, ...]", applying MaxArray and struct schemas.
---@param Value any # array wrapper
---@param Options pd3.Reflect.Options
---@param Depth integer
---@param ElementSchema UObject? # UScriptStruct for struct arrays
---@return string
local function FormatArray(Value, Options, Depth, ElementSchema)
    local Total = Safe.ArrayCount(Value)
    if Total == nil then return "<array unreadable>" end
    local Limit = Options.MaxArray
    if Limit == nil or Limit <= 0 then Limit = Total end
    local Shown = math.min(Total, Limit)

    local Parts = {}
    for Index = 1, Shown do
        local Ok, Element = pcall(function() return Value[Index] end)
        if Ok then
            if ElementSchema ~= nil and Depth > 0 then
                Parts[#Parts + 1] = FormatStructFields(Safe.Resolve(Element), ElementSchema, Options, Depth)
            else
                Parts[#Parts + 1] = Format(Element, Options, Depth - 1, nil)
            end
        else
            Parts[#Parts + 1] = "<element error>"
        end
    end

    local Suffix = ""
    if Shown < Total then
        Suffix = string.format(" ... [%d shown / %d total, cap MaxArray=%s]", Shown, Total, tostring(Options.MaxArray))
    end
    return "[" .. table.concat(Parts, ", ") .. Suffix .. "]"
end

--- Formats any reflected value: resolves wrappers, recurses structs/arrays per
--- Options, describes objects, truncates long strings.
---@param Value any
---@param Options pd3.Reflect.Options
---@param Depth integer? # recursion budget; <= 0 stops struct/array expansion
---@param Property UObject? # FProperty carrying the struct/array schema
---@return string
Format = function(Value, Options, Depth, Property)
    Depth = Depth or 0
    local Resolved = Safe.Resolve(Value)
    if Resolved == nil then return "nil" end

    local ResolvedType = type(Resolved)
    if ResolvedType == "string" then return Truncate(Resolved, Options.MaxString) end
    if ResolvedType == "number" or ResolvedType == "boolean" then return tostring(Resolved) end

    local Schema = StructSchemaOf(Property)
    if Schema ~= nil and Depth > 0 then
        return FormatStructFields(Resolved, Schema, Options, Depth)
    end

    if Safe.ArrayCount(Resolved) ~= nil then
        return FormatArray(Resolved, Options, Depth, ArrayElementSchemaOf(Property))
    end

    if HasMethod(Resolved, "GetFullName") then
        return Truncate(Safe.Describe(Resolved), Options.MaxString)
    end
    return Truncate(Safe.String(Resolved), Options.MaxString)
end

Reflect.Format = Format
Reflect.PropertyTag = PropertyTag

--- All FProperty objects of a UObject, UScriptStruct or UScriptClass
--- (anything exposing ForEachProperty or GetClass).
---@param Target any
---@return UObject[] properties
function Reflect.PropertiesOf(Target)
    local Struct = nil
    if HasMethod(Target, "ForEachProperty") then
        Struct = Target
    elseif HasMethod(Target, "GetClass") then
        local Ok, Class = pcall(function() return Target:GetClass() end)
        if Ok then Struct = Class end
    end

    local Properties = {}
    if Struct == nil then return Properties end
    pcall(function()
        Struct:ForEachProperty(function(Property)
            Properties[#Properties + 1] = Property
        end)
    end)
    return Properties
end

--- Names of all UFunctions of a UScriptStruct/UScriptClass.
---@param Struct any # UScriptStruct/UScriptClass
---@return string[] functionNames
function Reflect.FunctionsOf(Struct)
    local Names = {}
    if Struct == nil then return Names end
    pcall(function()
        Struct:ForEachFunction(function(Function)
            Names[#Names + 1] = Safe.String(Function:GetFName())
        end)
    end)
    return Names
end

--- Resolves a UScriptStruct by name or path. Non-string arguments pass through.
--- Struct names drop the F prefix: "FSBZChallengeData" -> "SBZChallengeData".
---@param NameOrPath any # struct name, full path, or an existing object
---@return UObject? schema
function Reflect.FindStruct(NameOrPath)
    if NameOrPath == nil then return nil end
    if type(NameOrPath) ~= "string" then return NameOrPath end

    local Candidates = {}
    if string.find(NameOrPath, "/", 1, true) then
        Candidates[1] = NameOrPath
    else
        Candidates[1] = "/Script/Starbreeze." .. NameOrPath
        Candidates[2] = "/Script/Starbreeze.F" .. NameOrPath
        Candidates[3] = NameOrPath
    end
    for _, Path in ipairs(Candidates) do
        local Ok, Found = pcall(StaticFindObject, Path)
        if Ok and Found ~= nil and Safe.IsValid(Found) then return Found end
    end
    return nil
end

--- Dumps all reflected properties of a live UObject with values and type tags.
---@param Target any # live UObject; nil yields a single "<nil target>" line
---@param Opts? pd3.Reflect.Options # per-call overrides; opts.Filter = name substring
---@return string[] lines # lines are also logged via pd3.log.Info
function Reflect.DumpProperties(Target, Opts)
    local Options = Options(Opts)
    local Lines = {}

    --- Appends Line to Lines and logs it.
    ---@param Line string
    local function Emit(Line)
        Lines[#Lines + 1] = Line
        Log.Info("%s", Line)
    end

    if Target == nil then
        Emit("<nil target>")
        return Lines
    end

    Emit("=== reflect: " .. Safe.Describe(Target) .. " ===")
    local Properties = Reflect.PropertiesOf(Target)
    local Skipped, Filtered = 0, 0

    for Index, Property in ipairs(Properties) do
        local Name = Safe.String(Property:GetFName())
        if Options.Skip[Name] then
            Skipped = Skipped + 1
        elseif Options.Filter ~= nil and Options.Filter ~= ""
            and not string.find(string.lower(Name), string.lower(Options.Filter), 1, true) then
            Filtered = Filtered + 1
        else
            if Options.MaxLines > 0 and #Lines >= Options.MaxLines then
                Emit(string.format("... truncated at MaxLines=%d (%d of %d props not shown)",
                    Options.MaxLines, #Properties - Index + 1, #Properties))
                break
            end
            local Value = Safe.Get(Target, Name)
            Emit(string.format("%s = %s (%s)", Name,
                Format(Value, Options, Options.MaxDepth, Property), PropertyTag(Property)))
        end
    end

    if Skipped > 0 then
        Emit(string.format("... %d props skipped by Skip list", Skipped))
    end
    if Filtered > 0 then
        Emit(string.format("... %d props hidden by Filter=%s", Filtered, tostring(Options.Filter)))
    end
    return Lines
end

--- Dumps a struct value (wrapper or table) using reflection from its UScriptStruct.
---@param Value any # struct value; nil yields a single "<nil value>" line
---@param Struct any # name ("SBZChallengeData"), path, or UScriptStruct object
---@param Opts? pd3.Reflect.Options
---@return string[] lines # lines are also logged via pd3.log.Info
function Reflect.DumpStruct(Value, Struct, Opts)
    local Options = Options(Opts)
    local Lines = {}

    --- Appends Line to Lines and logs it.
    ---@param Line string
    local function Emit(Line)
        Lines[#Lines + 1] = Line
        Log.Info("%s", Line)
    end

    local Schema = Reflect.FindStruct(Struct)
    Emit(string.format("=== reflect struct %s ===", tostring(Struct)))
    if Value == nil then
        Emit("<nil value>")
        return Lines
    end
    if Schema == nil then
        Emit("schema not found; describe: " .. Safe.Describe(Value))
        return Lines
    end

    local Properties = {}
    pcall(function()
        Schema:ForEachProperty(function(Property)
            Properties[#Properties + 1] = Property
        end)
    end)

    for Index, Property in ipairs(Properties) do
        if Options.MaxLines > 0 and #Lines >= Options.MaxLines then
            Emit(string.format("... truncated at MaxLines=%d (%d fields not shown)",
                Options.MaxLines, #Properties - Index + 1))
            break
        end
        local Name = Safe.String(Property:GetFName())
        Emit(string.format("%s = %s (%s)", Name,
            Format(Safe.Get(Value, Name), Options, Options.MaxDepth, Property), PropertyTag(Property)))
    end
    return Lines
end

--- Dumps a class/struct: property list then function list.
---@param NameOrPath any # live object/class, class short name, or full object path
---@param Opts? pd3.Reflect.Options
---@return string[] lines # lines are also logged via pd3.log.Info
function Reflect.DumpClass(NameOrPath, Opts)
    local Options = Options(Opts)
    local Lines = {}

    --- Appends Line to Lines and logs it.
    ---@param Line string
    local function Emit(Line)
        Lines[#Lines + 1] = Line
        Log.Info("%s", Line)
    end

    local Class = nil
    if NameOrPath ~= nil and type(NameOrPath) ~= "string" then
        Class = NameOrPath
    elseif type(NameOrPath) == "string" then
        local OkFind, Found = pcall(StaticFindObject, NameOrPath)
        if OkFind and Found ~= nil and Safe.IsValid(Found) then
            Class = Found
        else
            local OkList, List = pcall(FindAllOf, NameOrPath)
            if OkList and type(List) == "table" and List[1] ~= nil and Safe.IsValid(List[1]) then
                local OkClass, Cls = pcall(function() return List[1]:GetClass() end)
                if OkClass then Class = Cls end
            end
        end
    end

    if Class == nil then
        Emit("class not found: " .. tostring(NameOrPath))
        return Lines
    end

    Emit("=== reflect class: " .. Safe.Describe(Class) .. " ===")
    local Properties = Reflect.PropertiesOf(Class)
    Emit(string.format("properties: %d", #Properties))
    for Index, Property in ipairs(Properties) do
        if Options.MaxLines > 0 and #Lines >= Options.MaxLines then
            Emit(string.format("... truncated at MaxLines=%d (%d props not shown)", Options.MaxLines, #Properties - Index + 1))
            break
        end
        Emit(string.format("  %s (%s)", Safe.String(Property:GetFName()), PropertyTag(Property)))
    end

    local Functions = Reflect.FunctionsOf(Class)
    Emit(string.format("functions: %d", #Functions))
    for Index, FunctionName in ipairs(Functions) do
        if Options.MaxLines > 0 and #Lines >= Options.MaxLines then
            Emit(string.format("... truncated at MaxLines=%d (%d funcs not shown)", Options.MaxLines, #Functions - Index + 1))
            break
        end
        Emit("  fn " .. FunctionName)
    end
    return Lines
end

--- Dumps an enum's names and values.
---@param EnumOrName any # enum name (tried under /Script/Starbreeze first), path, or UEnum object
---@param Opts? pd3.Reflect.Options
---@return string[] lines # lines are also logged via pd3.log.Info
function Reflect.DumpEnum(EnumOrName, Opts)
    local Options = Options(Opts)
    local Lines = {}

    --- Appends Line to Lines and logs it.
    ---@param Line string
    local function Emit(Line)
        Lines[#Lines + 1] = Line
        Log.Info("%s", Line)
    end

    local Enum = EnumOrName
    if type(EnumOrName) == "string" then
        local Ok, Found = pcall(StaticFindObject, "/Script/Starbreeze." .. EnumOrName)
        if not Ok or Found == nil then
            pcall(function() Found = StaticFindObject(EnumOrName) end)
        end
        Enum = Found
    end
    if Enum == nil or not Safe.IsValid(Enum) then
        Emit("enum not found: " .. tostring(EnumOrName))
        return Lines
    end

    Emit("=== reflect enum: " .. Safe.Describe(Enum) .. " ===")
    pcall(function()
        Enum:ForEachName(function(Name, Value)
            if Options.MaxLines > 0 and #Lines >= Options.MaxLines then
                Emit(string.format("... truncated at MaxLines=%d", Options.MaxLines))
                return true
            end
            Emit(string.format("  %s = %s", Safe.String(Name), tostring(Value)))
        end)
    end)
    return Lines
end

return Reflect
