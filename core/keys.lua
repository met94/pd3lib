local Keys = {}
local Log = require("pd3lib.core.log")

local Registry = {}

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

function Keys.Count()
    return #Registry
end

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
