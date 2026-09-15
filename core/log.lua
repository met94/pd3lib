local Log = {}

local Prefix = "[pd3lib]"
local DebugEnabled = false

local function Emit(Msg, ...)
    local Text = tostring(Msg)
    if select("#", ...) > 0 then
        local Ok, Formatted = pcall(string.format, Text, ...)
        if Ok then Text = Formatted end
    end
    print(string.format("%s %s\n", Prefix, Text))
end

function Log.SetPrefix(NewPrefix)
    Prefix = tostring(NewPrefix)
end

function Log.GetPrefix()
    return Prefix
end

function Log.SetDebug(Enabled)
    DebugEnabled = not not Enabled
end

function Log.Info(Msg, ...)
    Emit(Msg, ...)
end

function Log.Warn(Msg, ...)
    Emit("[warn] " .. tostring(Msg), ...)
end

function Log.Err(Msg, ...)
    Emit("[error] " .. tostring(Msg), ...)
end

function Log.Debug(Msg, ...)
    if not DebugEnabled then return end
    Emit("[debug] " .. tostring(Msg), ...)
end

local function ToText(Value, Depth)
    if type(Value) ~= "table" or Depth <= 0 then
        return tostring(Value)
    end
    local Parts = {}
    for Key, Item in pairs(Value) do
        Parts[#Parts + 1] = string.format("%s=%s", tostring(Key), ToText(Item, Depth - 1))
    end
    return "{" .. table.concat(Parts, ", ") .. "}"
end

function Log.Dump(Value, MaxDepth)
    Emit(ToText(Value, MaxDepth or 2))
end

return Log
