local pd3 = { Version = 1 }

pd3.core = {
    log = require("pd3lib.core.log"),
    safe = require("pd3lib.core.safe"),
    world = require("pd3lib.core.world"),
    hooks = require("pd3lib.core.hooks"),
    timers = require("pd3lib.core.timers"),
    keys = require("pd3lib.core.keys"),
    lifecycle = require("pd3lib.core.lifecycle"),
}

pd3.game = {
    entities = require("pd3lib.game.entities"),
    interact = require("pd3lib.game.interact"),
    shield = require("pd3lib.game.shield"),
}

pd3.selftest = require("pd3lib.selftest")

pd3.log = pd3.core.log
pd3.safe = pd3.core.safe
pd3.world = pd3.core.world
pd3.hooks = pd3.core.hooks
pd3.timers = pd3.core.timers
pd3.keys = pd3.core.keys
pd3.lifecycle = pd3.core.lifecycle
pd3.entities = pd3.game.entities
pd3.interact = pd3.game.interact
pd3.shield = pd3.game.shield

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

function pd3.Unload()
    pd3.core.hooks.UnhookAll()
    pd3.core.keys.UnbindAll()
    pd3.core.log.Info("pd3lib unloaded")
end

return pd3
