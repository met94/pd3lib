# Changelog

All notable changes to pd3lib are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and versions match the `pd3.Version`
compatibility line.

## [Unreleased]

### Added

- `game.attributes` — live `FGameplayAttributeData` reads (`Values`, `Current`, `Base`) with
  plain-number passthrough and nil-safe missing fields, plus a build-tagged `Layout` constant
  for raw-memory/debugger work (FGameplayAttributeData = 16 bytes, Base @ +8, Current @ +12 on
  build 5.5.4).
- `game.weapons` — `DamageAtDistance(raw, meters)` and `CritMultiplierAtDistance(raw, meters)`:
  the native hit-time band semantics (damage: first falloff entry with distance >= the shot,
  else the last; crit: first entry strictly beyond, else the last), matching
  `FUN_144d16f68` / `FUN_144d12fac`.
- `core.reflect` — `AddressOf(object)`: nil-safe `UObject:GetAddress` wrapper for debugger
  recipes and address logging.
- `game.weapons` — weapon database/entry enumeration (`Databases`, `All`, `Find`,
  `Ensure` with a `LoadAsset` fallback),
  raw and hidden stat reads (`Raw`: fire, spread, recoil/gun-kick, swap notify times
  and play rates), modular parts (`Parts`, `PartInfo` with `AttributeModifierMap`),
  attribute curve evaluation (`AttributeCurves`, `CurveValue`, `AttributeValue`)
  against the live `CT_ModData_Default` with a generated fallback
  (`game.weapons_curves`), parent-attribute expansion
  (`AttributeParents`, `ModifierMultipliers`) and UI stat weights
  (`UiWeights`, `UiStatsAsset`, `UiStats`; loaded-instances-only because UE4SS
  crashes wrapping the unset `WeaponStatsAssetPath` soft pointer), plus
  `Dump`/`Json`/`WriteJson` helpers.
- `game.weapons` — `AttributeIdentifiers` (the game's own attribute display names and
  children) and `BarsApprox`/`BarRanges` (reduced + cross-weapon normalized 0..100 bars
  when the game-computed values are unavailable).
- `game.loadout` — the actually equipped weapon config (`ActiveConfigIndex` +
  `EquippedConfig` via `SBZLoadoutLibrary:GetWeaponConfigSlot`, live menu widget
  fallbacks), equipped attachments (`ConfigParts` from `ModDataMap`/`ModDataArray`,
  supplied by the live loadout weapon slot button when the by-value library config
  loses them), display metadata (`WeaponData`) and the game-computed stat bars via a
  scratch `SBZMainMenuWeaponStatsWidget` (`ScratchWidget`, `ConfigBars`,
  `DataBars`, `EquippedBars`; normalized 0..100, all-zero results rejected,
  live widgets are never mutated), plus `Loadout.PrettyName` for attachment
  labels when the asset has no localized `DisplayName`.
- `core.safe` — `TextOrNil(ftext)` (trimmed FText, nil when missing) and a documented
  crash hazard: resolving FText property wrappers with `Resolve` faults inside
  `UE4SS.dll` (dump-verified); use `Text`/`TextOrNil`.
- `core.maps` — `Count(map)`: `Size` when available, otherwise counts via `ForEach`
  (struct-property TMaps iterate while `#`/`Size` fail).
- `core.world` — `LoadClass(packagePath, classPath)`: `StaticFindObject` with an
  `LoadAsset(package)` retry, for blueprint classes.
- README — "UE4SS marshalling quirks" section: FText wrapper crash, by-value struct
  returns dropping TArray/TMap, inconsistent `#`/`GetArrayNum`, out-parameter tables
  rejected, FName argument marshalling, UFunction userdata calls.
- `game.loadout` — `EquippedWeaponData(slot, index)`: the runtime
  (attachment-adjusted) weapon data of the equipped config plus the original base
  asset (the game swaps `EquippableData` for a transient player-state copy, so
  `Weapons.Raw` on it yields game-adjusted hidden stats).
- `game.loadout` — `WidgetConfig(slot, index)`: the scratch stats widget's runtime
  config including the `ModDataMap`, used as the primary attachment source
  (screen-independent, `Source = "loadout+widget"`); `EquippedConfig` info gains
  `BaseEquippableData`, and `WeaponData(config, dataOverride)` reports the base asset
  when the config holds a runtime copy.
- `core.classes` — class resolution with the ordered variants `LoadAsset(object)`,
  `StaticFindObject(object)`, `LoadAsset(package)`, `StaticFindObject(package)` (Blueprint
  assets unwrap to `GeneratedClass`) plus an incremental, non-fatal load queue
  (`NewLoader` with per-tick budget, retry cap, "gave up" state and `RetryFailed`) so one
  bad class never aborts a roster.
- `game.spawn` — direct spawning (`Statics`, `ActorFromClass`, `Destroy`) through
  Kismet-built transforms and `BeginDeferredActorSpawnFromClass`/`FinishSpawningActor`
  (script classes resolved with `StaticFindObject`; no Lua globals), plus the pure
  placement math (`OffsetLocation`, `FacingYaw`, `YawRadians`).
- `game.ai` — `FreezePawn(pawn, reason)` (`SetAIEnabled(false, FName)`) with
  `LastDisabledReason` dedupe, a per-class unsupported-controller cache (`IsFreezeUnsupported`,
  logged once) and `NeedsFreeze`/`ControllerOf`/`FrozenCount`/`Reset`.
- `game.weapons` — `EquippedFireDataLive()` (in-heist equipped weapon FireData via
  `PlayerController.Pawn.CurrentEquippableConfig.EquippableData.FireData`, fallback
  `.CurrentEquippable...`) and falloff breakpoints (`DistanceFieldCm`, `BreakpointsCm`,
  `BreakpointsMeters`, pure `DistancesFromCm` union in meters).
- `game.mission` — `DifficultyName(index)`, `DifficultyIdx(state?)` and the
  UNSAFE/testing-only `SetDifficultyIdx(index)` (`SBZGameInstance:SetDifficulty`; affects
  newly spawned pawns only).
- `core.world` — `PruneValid(list, onLost)`: drops invalid objects with a per-entry
  callback, for tick-loop pruning before property reads.
- Tests — engine-free fengari suites under `tests/` (`tests/run_all.lua`) covering the pure
  parts of safe/world/classes/spawn/ai/weapons/mission.
- `docs/knowledge-base.md` — "Direct-spawned pawns and kill-hook mods" (native crash
  mechanism, isolation matrix, guidance) and "Dead ends" (cheat-manager spawn, assault
  director in the Shooting Range, missing script-class Lua globals, `LoadAsset` limits).

### Changed

- `core.safe` — `IsValid` prefers the UE4SS global `IsValid` when the build exposes it and
  falls back to the object method; docs call out that stale-handle property reads fault
  natively beyond `pcall` (validate before every read in tick loops).

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
