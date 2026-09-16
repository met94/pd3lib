--- Logging helpers. All info-family calls accept string.format style arguments.
---@class pd3.Log
local Log = {}

local Prefix = "[pd3lib]"
local DebugEnabled = false

--- Writes one prefixed line to stdout; formats with string.format when args are given.
---@param Msg string # format string when additional arguments are passed
---@param ... any # string.format arguments
local function Emit(Msg, ...)
    local Text = tostring(Msg)
    if select("#", ...) > 0 then
        local Ok, Formatted = pcall(string.format, Text, ...)
        if Ok then Text = Formatted end
    end
    print(string.format("%s %s\n", Prefix, Text))
end

--- Sets the prefix prepended to every log line.
---@param NewPrefix string
function Log.SetPrefix(NewPrefix)
    Prefix = tostring(NewPrefix)
end

--- Returns the current log prefix.
---@return string prefix
function Log.GetPrefix()
    return Prefix
end

--- Enables or disables Log.Debug output.
---@param Enabled boolean
function Log.SetDebug(Enabled)
    DebugEnabled = not not Enabled
end

--- Logs an info line.
---@param Msg string # format string when arguments are passed
---@param ... any # string.format arguments
function Log.Info(Msg, ...)
    Emit(Msg, ...)
end

--- Logs a warning line (adds "[warn] ").
---@param Msg string # format string when arguments are passed
---@param ... any # string.format arguments
function Log.Warn(Msg, ...)
    Emit("[warn] " .. tostring(Msg), ...)
end

--- Logs an error line (adds "[error] ").
---@param Msg string # format string when arguments are passed
---@param ... any # string.format arguments
function Log.Err(Msg, ...)
    Emit("[error] " .. tostring(Msg), ...)
end

--- Logs a debug line; no-op unless SetDebug(true) was called.
---@param Msg string # format string when arguments are passed
---@param ... any # string.format arguments
function Log.Debug(Msg, ...)
    if not DebugEnabled then return end
    Emit("[debug] " .. tostring(Msg), ...)
end

--- Renders a value as text; tables are expanded up to Depth levels.
---@param Value any
---@param Depth integer
---@return string
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

--- Logs a value; tables are expanded up to MaxDepth levels.
---@param Value any
---@param MaxDepth? integer # default 2
function Log.Dump(Value, MaxDepth)
    Emit(ToText(Value, MaxDepth or 2))
end

return Log
