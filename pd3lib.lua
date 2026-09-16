--- pd3lib entry point. Require, Init, then use the pd3.* aliases.
---
--- ```lua
--- local pd3 = require("pd3lib")
--- pd3.Init({ prefix = "[MyMod]", debug = false })
--- ```
---@class pd3lib
---@field Version integer # library version
---@field core pd3.Core # module table (pd3lib.core.*)
---@field game pd3.Game # module table (pd3lib.game.*)
---@field selftest pd3.SelfTest
---@field log pd3.Log
---@field safe pd3.Safe
---@field world pd3.World
---@field hooks pd3.Hooks
---@field timers pd3.Timers
---@field keys pd3.Keys
---@field lifecycle pd3.Lifecycle
---@field maps pd3.Maps
---@field reflect pd3.Reflect
---@field entities pd3.Entities
---@field interact pd3.Interact
---@field shield pd3.Shield
---@field challenge pd3.Challenge
---@field mission pd3.Mission
local pd3 = { Version = 2 }

--- Options for pd3.Init.
---@class pd3lib.InitOptions
---@field prefix? string # log line prefix; default "[pd3lib]"
---@field debug? boolean # enables pd3.log.Debug; default false
---@field enableSelftest? boolean # bind the selftest key; default false
---@field selftestKey? integer # Key.* constant, used only with enableSelftest = true

--- Generic UE4SS/UE helper modules.
---@class pd3.Core
---@field log pd3.Log
---@field safe pd3.Safe
---@field world pd3.World
---@field hooks pd3.Hooks
---@field timers pd3.Timers
---@field keys pd3.Keys
---@field lifecycle pd3.Lifecycle
---@field maps pd3.Maps
---@field reflect pd3.Reflect
pd3.core = {
    log = require("pd3lib.core.log"),
    safe = require("pd3lib.core.safe"),
    world = require("pd3lib.core.world"),
    hooks = require("pd3lib.core.hooks"),
    timers = require("pd3lib.core.timers"),
    keys = require("pd3lib.core.keys"),
    lifecycle = require("pd3lib.core.lifecycle"),
    maps = require("pd3lib.core.maps"),
    reflect = require("pd3lib.core.reflect"),
}

--- Payday 3 specific modules.
---@class pd3.Game
---@field entities pd3.Entities
---@field interact pd3.Interact
---@field shield pd3.Shield
---@field challenge pd3.Challenge
---@field mission pd3.Mission
pd3.game = {
    entities = require("pd3lib.game.entities"),
    interact = require("pd3lib.game.interact"),
    shield = require("pd3lib.game.shield"),
    challenge = require("pd3lib.game.challenge"),
    mission = require("pd3lib.game.mission"),
}

pd3.selftest = require("pd3lib.selftest")

pd3.log = pd3.core.log
pd3.safe = pd3.core.safe
pd3.world = pd3.core.world
pd3.hooks = pd3.core.hooks
pd3.timers = pd3.core.timers
pd3.keys = pd3.core.keys
pd3.lifecycle = pd3.core.lifecycle
pd3.maps = pd3.core.maps
pd3.reflect = pd3.core.reflect
pd3.entities = pd3.game.entities
pd3.interact = pd3.game.interact
pd3.shield = pd3.game.shield
pd3.challenge = pd3.game.challenge
pd3.mission = pd3.game.mission

--- Applies options (prefix, debug, selftest key) and logs the load line.
---@param Options? pd3lib.InitOptions
---@return pd3lib pd3 # this module, for chaining
function pd3.Init(Options)
    Options = Options or {}

    if Options.prefix ~= nil then
        pd3.core.log.SetPrefix(Options.prefix)
    end
    if Options.debug ~= nil then
        pd3.core.log.SetDebug(Options.debug)
    end
    if Options.enableSelftest and Options.selftestKey ~= nil then
        pd3.core.keys.Bind(Options.selftestKey, pd3.selftest.Run, "pd3lib selftest")
    end

    pd3.core.log.Info("pd3lib v%d loaded", pd3.Version)
    return pd3
end

--- Unhooks everything and unbinds keys (keybind removal only when the UE4SS
--- build exposes UnregisterKeyBind).
function pd3.Unload()
    pd3.core.hooks.UnhookAll()
    pd3.core.keys.UnbindAll()
    pd3.core.log.Info("pd3lib unloaded")
end

return pd3
