--- Key binding registry over UE4SS RegisterKeyBind.
---@class pd3.Keys
local Keys = {}

local Log = require("pd3lib.core.log")

local Registry = {}

--- Binds KeyCode to Fn and tracks the binding for UnbindAll.
---@param KeyCode integer # Key.* constant, e.g. Key.F5
---@param Fn fun() # invoked by UE4SS on the input thread
---@param Description? string # used in log lines only
---@return boolean ok # false when RegisterKeyBind raised
function Keys.Bind(KeyCode, Fn, Description)
    local Ok, Err = pcall(RegisterKeyBind, KeyCode, Fn)
    if Ok then
        Registry[#Registry + 1] = { Key = KeyCode, Fn = Fn, Description = Description }
        Log.Info("keybind: %s", tostring(Description or KeyCode))
        return true
    end
    Log.Warn("keybind failed (%s): %s", tostring(Description or KeyCode), tostring(Err))
    return false
end

--- Number of tracked bindings.
---@return integer
function Keys.Count()
    return #Registry
end

--- Unregisters every tracked binding when UE4SS exposes UnregisterKeyBind.
---@return boolean ok # false when UnregisterKeyBind is unavailable (bindings stay active)
function Keys.UnbindAll()
    if type(UnregisterKeyBind) ~= "function" then
        Log.Warn("UnregisterKeyBind not available; %d keybinds stay active", #Registry)
        return false
    end
    for _, Entry in ipairs(Registry) do
        pcall(UnregisterKeyBind, Entry.Key, Entry.Fn)
    end
    Registry = {}
    return true
end

return Keys
