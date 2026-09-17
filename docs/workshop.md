# ModWorkshop page copy — pd3lib

Paste-ready text for the ModWorkshop submission (category: Libraries, tags: UE4SS, Lua).

## Title

pd3lib — helper library for PAYDAY 3 UE4SS mods (for modders)

## Short description

A library for mod authors. Players: you don't need this — mods that use it include it in
their own download.

## Description

**pd3lib is a library for building PAYDAY 3 UE4SS mods.** It does nothing on its own.

**Players:** you do not need to install this. Any mod built with pd3lib includes it inside
its own download.

**Modders:** download the zip and copy `pd3lib.lua` and the `pd3lib` folder into your mod's
`scripts` folder. That is the whole install — no shared folders, no `mods.txt` changes, no
load order to worry about. Keep the folder named `pd3lib`.

Your mod ends up like this:

```
MyMod/
  scripts/
    main.lua
    pd3lib.lua
    pd3lib/
      core/
      game/
      selftest.lua
      LICENSE.md
```

### What's inside

- `core` — log, safe error-tolerant accessors for UE4SS values, world/player accessors,
  hooks, timers, keybinds, lifecycle callbacks, TMap helpers, reflection dumpers that keep
  working across game updates.
- `game` — PAYDAY 3 helpers: entities/civilians, interactions, human shields, challenges,
  achievements, mission/escape state, heist-scoped watch callbacks.
- A live selftest (`pd3.selftest`) that runs PASS/FAIL checks against the game.

Everything is pcall-guarded: library errors are logged, never fatal.

### Requirements

PAYDAY 3 + [PD3 UE4SS V3.01 + Allow Pak Mods](https://modworkshop.net/mod/47771). Pure Lua,
no other dependencies.

### Documentation & source

API reference, knowledge base and examples:
<https://github.com/met94/pd3lib>

### Versioning

Within a major version changes are additive only — existing functions never change or
disappear. Breaking changes bump the major; mods vendor the version they shipped with, so old
releases keep working forever.

### Changelog

See [CHANGELOG](https://github.com/met94/pd3lib/blob/main/CHANGELOG.md). Current version:
2.1.1.
