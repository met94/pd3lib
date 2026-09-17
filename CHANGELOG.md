# Changelog

All notable changes to pd3lib are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and versions match the `pd3.Version`
compatibility line.

## [2.1.1] - 2026-09-17

### Added

- `release.ps1` — builds `dist/pd3lib-<version>.zip` for the ModWorkshop submission (root
  `pd3lib/`, library files only) and verifies the archive contents.

### Changed

- README: ModWorkshop install steps, a vendoring guide (ship pd3lib inside a mod's `Scripts`
  folder so released mods are self-contained) and a compatibility promise (additive-only within
  a major; breaking changes ship side-by-side under a new package name).

## [2.1.0] - 2026-09-17

### Added

- `game.heist` — heist-scoped `Watch`/`Unwatch` with `Enter`/`Exit` callbacks; detection runs
  once per level init (deferred out of hook context), so single-heist mods can keep their
  hooks and timers idle in menus and other heists.

## [2.0.0] - 2026-09-16

Initial standalone release. Extracted from the InsurancePolicySolo monorepo with full history.

### Added

- `core`: log, safe, world, hooks, timers, keys, lifecycle, maps, reflect.
- `game`: entities, interact, shield, challenge, mission.
- `pd3.selftest` — PASS/FAIL checks against live game state, extensible and key-bindable.
- `core.reflect` — game-update-resistant property/struct/class/enum dumpers with output budgets.
- `core.maps` — TMap helpers with the tested UE4SS build's iteration quirks handled.
- `core.safe` crash workarounds: wrapper resolution guards, `ToFName` pre-building, `Describe`
  object gating.
- LuaCATS annotations on the full public API, and per-class generated reference in `docs/api/`.
- `docs/knowledge-base.md` — PAYDAY 3 engine notes (interaction flow, human shield, challenge
  and achievement internals, UE4SS data-type pitfalls).

### Compatibility

- Tested with PD3 UE4SS V3.01 + Allow Pak Mods (BETA), UE4SS v3.0.1 Beta #0.
- Lua 5.1-compatible; runs on the UE4SS Lua runtime.
