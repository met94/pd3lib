# pd3lib

Lua helper library for PAYDAY 3 UE4SS mods. Generic UE4SS/UE scaffolding (`core`), PAYDAY 3
specific helpers (`game`), a reflection toolkit that keeps working across game updates, and a
live selftest.

pd3lib is a dependency for other mods. It does nothing on its own — install it if a mod
requires it, or use it to build your own.

## Requirements

- PAYDAY 3 + [PD3 UE4SS V3.01 + Allow Pak Mods (BETA)](https://modworkshop.net/mod/47771)
  (UE4SS v3.0.1 Beta #0). Older UE4SS builds miss APIs the library relies on; the library is
  tested against this build.
- No other dependencies. Pure Lua 5.1-compatible code (runs on the UE4SS Lua runtime).

## Install

pd3lib is vendored into each mod. There is no shared/global install step and `Mods/shared` is
never used.

1. Copy `pd3lib.lua` and the `pd3lib/` folder from the download (or this repo) into your mod's
   `scripts` folder. Keep the folder named `pd3lib` — the library's internal
   `require("pd3lib.*")` calls depend on it.
2. Load it in your `main.lua`:

   ```lua
   local pd3 = require("pd3lib")
   ```

Resulting layout:

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

UE4SS searches a mod's own `Scripts` folder before `Mods/shared`, so the vendored copy always
wins and no other mod can overwrite it. See [Vendoring](#vendoring) for why this is the only
supported install.

### Git submodule (optional)

Add this repo as a git submodule and mirror `pd3lib.lua`, `core/`, `game/`, `selftest.lua`
and `LICENSE.md` into your mod's `scripts` folder from your deploy script.

## Quick start

```lua
local pd3 = require("pd3lib")
pd3.Init({ prefix = "[MyMod]", debug = false })

pd3.log.Info("hello from %s", "MyMod")
pd3.keys.Bind(Key.F5, function() end, "my key")
pd3.hooks.HookLogged("/Script/Starbreeze.SBZInteractorComponent:Multicast_CompletedInteraction",
    function(Context, ...) end)
pd3.lifecycle.OnLevelInit(function(LevelName)
    pd3.log.Info("level %s", tostring(LevelName))
end)
pd3.timers.After(1000, function() end)
pd3.Unload() -- unhooks everything; keybind removal only if the UE4SS build supports it
```

`Init` options:

| Option | Default | Meaning |
|---|---|---|
| `prefix` | `[pd3lib]` | log line prefix |
| `debug` | `false` | enables `pd3.log.Debug` |
| `enableSelftest` | `false` | bind the selftest key |
| `selftestKey` | none | e.g. `Key.F10`, used only when `enableSelftest = true` |

## Modules

### core.log
`SetPrefix`, `SetDebug`, `Info`, `Warn`, `Err`, `Debug`, `Dump(table, depth)`. All
`Info`-family calls accept `string.format` style args.

### core.safe
Error-tolerant accessors; every helper swallows errors via `pcall` and never raises.

- `Call(fn, ...)` -> `ok, ...`
- `Get(obj, prop)` / `Set(obj, prop, value)` / `CallFn(obj, name, ...)`
- `IsValid(obj)` — prefers the UE4SS global `IsValid` when the build has it, method `obj:IsValid()`
  as fallback. Validate every object before reading its members in tick loops: stale handles fault
  natively (`GetFunctionByNameInChain` / `auto_construct_object`) beyond `pcall`'s reach
- `Describe(value)` (object full name + class; unwraps hook `:get()` wrappers)
- `Text(ftext)` (FText -> string, `KismetTextLibrary` fallback)
- `TextOrNil(ftext)` — `Text` trimmed; nil for nil, empty, whitespace-only or `"nil"` results
  (menu FTexts can stringify to a single space in this build)
- `Count(obj, arrayProp)`, `Num(value, default)`
- `Resolve(value)` — unwraps UE4SS value wrappers: `RemoteUnrealParam`/`LocalUnrealParam` via
  `:get()`; `FString`/`FName`/`FText`/`FGuid` via `:ToString()` (returns a Lua string); UObject
  derivatives pass through unchanged (`GetFullName` guard); depth-capped to avoid wrapper loops.
  **Never call on FText property wrappers**: the `:get()` path crashed UE4SS marshalling
  (dump-verified access violation in `UE4SS.dll`); use `Text`/`TextOrNil` for text values.
- `String(value)` — `Resolve` then `tostring` for primitives, `Describe` fallback.
- `ArrayCount(value)` — `#`, then `GetArrayNum`, else nil (`TrivialObject` arrays support neither).
- `ToFName(text)` -> `FName` userdata, `index` — pre-builds FNames for UFunction arguments (Lua
  string -> FName marshalling crashed the tested UE4SS build). Returns nil if the name is not in
  the name pool.

### core.maps
- `Size(map)`, `Count(map)`, `Find(map, key)`, `Contains(map, key)`
- `ForEach(map, fn)` — `fn(key, value)`; keys are resolved, callback errors logged per element.
- `Count(map)` — `Size` when available, otherwise counts via `ForEach` (struct-property TMaps
  iterate fine while `#`/`Size` return nil).

**Tested UE4SS build**: TMap callbacks must not return a value — a non-nil return aborts
iteration. Early-stop is therefore unavailable; count/skip inside the closure. `pairs()` never
works on TMaps.

### core.classes
Class resolution with ordered fallbacks and an incremental, non-fatal load queue.

- `Variants(path)` — ordered resolver attempts: `LoadAsset(object)`, `StaticFindObject(object)`,
  `LoadAsset(package)`, `StaticFindObject(package)`
- `ClassFromObject(obj)` — class objects pass through; Blueprint assets unwrap to `GeneratedClass`
- `Ensure(path)` -> `class, variant` — one-shot resolve through all variants (game thread)
- `NewLoader({ BudgetPerTick = 2, MaxAttempts = 8, Resolve, Log })` -> loader with
  `Enqueue(paths)`, `Step()`, `Get(path)` (`class` / `false` gave up / `nil` pending),
  `RetryFailed()`, `Pending()`; budgeted by design so a bad class never aborts a roster.
  `Resolve` can be injected for unit tests

### core.reflect
Introspection-driven dumpers that keep working across game updates (no hardcoded offsets).

- `SetDefaults{ MaxDepth=1, MaxArray=25, MaxString=200, MaxLines=400, Skip={ ModeArray, ModeDataArray } }`
  — per-call `opts` override, `MaxArray/MaxString/MaxLines = 0` mean unlimited.
- `DumpProperties(target, opts)` — all reflected properties with values + type tags;
  `opts.Filter` = name substring; truncation is always logged.
- `DumpStruct(value, structNameOrObject, opts)` — struct fields via its `UScriptStruct`
  (e.g. `"SBZChallengeData"`, `"SBZStatisticCriteriaData"`, `"SBZEndMissionResultData"`,
  `"SBZInternalStatData"`).
- `DumpClass(nameOrPath, opts)`, `DumpEnum(nameOrObject, opts)`, `PropertiesOf(target)`,
  `FunctionsOf(struct)`, `FindStruct(nameOrPath)`, `Format(value, opts, depth, property)`.
- Safe defaults: known-freeze props skipped, arrays capped, output budgeted, everything pcall'd.

### core.world
- `GetPlayerController()`, `GetPawn()`, `GetPlayerState()`, `GetWorld()`, `GetLevelName()`
- `FindAll(className)` (safe `FindAllOf`, always returns a table)
- `FindLive(className)` — first non-`Default__` valid instance (plus full name)
- `LoadClass(packagePath, classPath)` — `StaticFindObject`, then `LoadAsset(package)` and retry
  (for blueprint classes such as `.../WBP_X.WBP_X_C`)
- `Distance(a, b)` (actors or vectors)
- `ActorsInPath(pathSubstring, aroundActor, maxDistance)` — iterates all actors, filters by class
  path substring, sorts by distance
- `PruneValid(list, onLost)` -> `survivors, lostCount` — drops invalid UObjects, calls
  `onLost(entry, index)` for each (returns the original list when nothing was lost)
- `HasAuthority(actor)`, `Owner(actor)`

### core.hooks
- `Hook(path, fn)` -> registers, logs, tracks; returns pre-hook id
- `HookLogged(path, fn)` — logs every fire (context + args) before invoking `fn`
- `Unhook(path, preId)`, `UnhookAll()`, `Count()`
- `LogFire(path, ctx, ...)` — formatted fire log

Hook callbacks run wrapped in `pcall`; callback errors are logged, not fatal.

### core.timers
`InGameThread(fn)`, `After(ms, fn)`, `Every(ms, fn)` (returns handle), `Cancel(handle)`.

### core.keys
`Bind(key, fn, description)`, `UnbindAll()`, `Count()`. `UnbindAll` warns if
`UnregisterKeyBind` is unavailable in the UE4SS build (it is absent from all known builds).

### core.lifecycle
`OnLevelInit(fn)`, `OnLevelRestart(fn)`, `OnMissionEnd(fn)`, `OnReturnToMenu(fn)`.
Registration is lazy: hooks are installed on first callback.

### game.entities
- `CivilianClasses`, `CrewClasses` (BP class short names, `_C` suffix required)
- `Civilians()`, `CrewPawns()`, `FindByClasses(list)`
- `CiviliansInRange(actor, maxDistance)`, `NearestCivilian(actor, maxDistance)`, `NearestCrew(...)`
- `InteractableOf(character)` -> `character.Interactable`
- `AIInteractorOf(pawn)` -> `pawn.AIInteractorComponent`
- `IsSurrendered(civilian)` -> `validHumanShield, humanShieldAllowed`

### game.interact
- `Modes` / `ModeName(i)` — `ESBZAICharacterInteractableMode` names
- `Actions` / `ActionName(i)` — `ESBZInteractionAction` names
- `PlayerInteractor(pawn)`
- `Start(interactor, interactable, modeIndex, id)`
- `Complete(interactor, interactable, id)`
- `Stop(interactor, interactable)`
- `StartWithComplete(interactor, interactable, modeIndex, id, completeDelayMs)`
- `State(interactor)` — `InteractId`, `ModeIndex`, `CurrentInteraction`, `Selected`
- `HookPaths` — known interaction + human shield state machine hook paths
- `EnableDiscoveryLogging()` — hooks every path in `HookPaths` with fire logging

### game.shield
- `Grab(pawn, victim, completeDelayMs)` — player human shield grab via the interaction system
- `Release()` — cancels `GA_HumanShieldInstigator_C` instances (skips `Default__`)
- `InstigatorState(pawn)`, `StateName(value)`, `VictimFlags(victim)`
- `AIInstigatorUnsupported = true` — do not attempt AI-driven human shields; the engine crashes

### game.challenge
- `Manager()`, `AchievementManager()` — live instances (`Default__` CDO skipped)
- `Achievements(manager)`, `AllChallenges(manager)` — the `AchievementMap` / `ChallengeMap` TMaps
- `StatusNames`, `StatusName(v)` — `0 INIT`, `1 INPROGRESS`, `2 COMPLETED`, `3 UNAVAILABLE`;
  `CompletedStatus = 2`
- `Find(manager, needle)` — summaries (key/id/name/status) whose id, name or key contains `needle`
- `IsCompleted(manager, needle)` -> `ok, summary`
- `CodeFor(challengeName)` — challenge FName -> AccelByte code (e.g. `ACH_*`)
- `Complete(achievementId)` — calls `SBZAchievementManager:CompleteAchievement(id)`

### game.mission
- `Get()` — live `SBZMissionState`
- `Difficulty(state)` -> `value, name`; `DifficultyNames`; `DifficultyName(index)` -> string
- `DifficultyIdx(state?)` — live `GetDifficultyIdx()` read (nil outside a mission)
- `SetDifficultyIdx(index)` -> `ok, err` — **UNSAFE/cheats**: `SBZGameInstance:SetDifficulty`,
  testing only; affects newly spawned pawns only, game thread only, may desync
  matchmaking/backend difficulty
- `HeistData(state)`, `HeistRef(state)` — heist token such as `penthouse`
- `Escape(state)` -> `{ TimeLeft, PlayersIn, PlayersRequired }`
- `Criterion(name)` — e.g. `Criterion("InsurancePolicy")`; nil outside a mission

### game.attributes
- `Values(set, field)` -> `current, base` — live `FGameplayAttributeData` reads from any
  attribute set (`SBZPawnAttributeSet`, player set, tank/shield sets). `FGameplayAttributeData`
  members resolve to `CurrentValue` / `BaseValue`, plain numeric properties return the number
  for both, missing fields return nil
- `Current(set, field)`, `Base(set, field)` — single-value shortcuts
- `Layout` — raw-memory layout reference for debugger work (build tag, struct size, base and
  current offsets); the reflection reads above do not depend on it

### game.weapons
- `Databases()`, `WeaponEntries(db)`, `All()`, `Find(query)`, `Resolve(value)`, `Ensure(query)` — weapon
  database (`SBZWeaponDatabase`) and `SBZRangedWeaponData` asset discovery; `Ensure` adds a
  `LoadAsset` fallback for path-like queries (game thread)
- `Subobjects(weapon)` — fire/spread/recoil/targeting/sway/tanking/wall-reaction/DOF/progression refs
- `Raw(weapon)` — plain-table stats: fire fields, spread fields, damage and
  penetration arrays, full recoil/gun-kick struct leaves, hidden swap data
  (`EquipNotifyTime`, `UnequipNotifyTime`, `SprintExitNotifyTime`, play rates, switch cooldown)
- `DamageAtDistance(raw, meters)`, `CritMultiplierAtDistance(raw, meters)` — native hit-time
  band semantics: damage uses the first `DamageDistanceArray` entry whose distance is >= the
  shot (else the last), the critical multiplier the first entry strictly beyond it (else the
  last); both take the `Raw` table and meters
- `EquippedFireDataLive()` — in-heist FireData of the currently equipped weapon via
  `PlayerController.Pawn.CurrentEquippableConfig.EquippableData.FireData` (fallback
  `.CurrentEquippable.EquippableConfig...`); nil with a reason for melee/throwable
- `DistanceFieldCm(obj, field)`, `BreakpointsCm(fire)`, `BreakpointsMeters(fire?)` — falloff
  breakpoints in cm/m; the meters list is the sorted, deduped union of
  `DamageDistanceArray` + `CriticalDamageMultiplierDistanceArray` (`DistancesFromCm` is the
  pure converter). With no argument it reads the live equipped weapon; empty table when
  unreadable, so callers can fall back to configured distances. AI weapon FireData often
  lacks the distance arrays
- `Parts(weapon)`, `PartInfo(part)` — modular slots, part `AttributeModifierMap`, part stats asset path
- `AttributeCurves(refresh?)`, `CurveValue(row, x)`, `AttributeValue(attribute, modifier)` —
  live `CT_ModData_Default` TMap read with generated `game.weapons_curves` fallback
- `AttributeParents(refresh?)`, `ModifierMultipliers(modifiers, curves?)` — parent attribute map
  from the settings CDO (`AttributeIdentifierMap`) with a static fallback, and expansion of
  `Overall*` modifiers into per-child curve multipliers
- `AttributeIdentifiers(refresh?)` — the game's own attribute labels (`DisplayName`, `Context`,
  `bIsParent`, child attributes) for human-readable modifier descriptions
- `UiStatsAsset()`, `UiWeights()`, `UiStats(weapon)` — `SBZUIWeaponStatsAsset` weights and the
  game's `SBZUIWeaponStatsBlueprint` bar arrays; in the cooked build the settings soft path is
  unset and UE4SS crashes wrapping that `TSoftObjectPtr`, so only already-loaded asset
  instances are used (returns a clean error otherwise)
- `BarsApprox(weapon, refresh?)`, `BarRanges(refresh?)` — approximate 0..100 bars when the
  game-computed widget values are unavailable: raw UI arrays are reduced (`BarReducers`) and
  normalized between the min/max across all loaded weapons, so deltas stay comparable
- `Dump(weapon, opts)`, `Json(value)`, `WriteJson(value, path)`

### game.loadout
- `Slots`, `SlotNames`, `FireTypes` — `ESBZEquippableLoadoutSlot` / `ESBZFireType` helpers
- `ActiveConfigIndex(worldContext, slot)` — the active player loadout's config slot index
  (`SBZLoadoutManager:GetPlayerLoadouts` + `GetActiveLoadoutIndex`; array elements are resolved
  before field reads)
- `EquippedConfig(slot?)` -> `config, info, err` — actually equipped weapon config
  (`FSBZEquippableConfig`) via `SBZLoadoutLibrary:GetWeaponConfigSlot(world, slot, activeIndex)`
  (direct returns only: this UE4SS build rejects trailing out-parameter tables), with live
  main-menu widget fallbacks and a clean error otherwise; the by-value library copy loses the
  attachment arrays, so the equipped `ModDataMap` comes from the runtime widget config
  (`Source = "loadout+widget"`), then the live loadout weapon slot button
  (`WBP_UI_LoadoutCustomization_WeaponSlotButton_C`, matched by `WeaponSlotIndex` + weapon path;
  `Source = "loadout+slotbutton"`), then live customization/mod screen configs. `info` carries
  both `EquippableData` (may be the runtime copy) and `BaseEquippableData` (the original asset)
- `WidgetConfig(slot, index)` -> `config, equippedData, originalData, err` — the scratch stats
  widget's `BaseEquippableConfig` after `SetBaseFromSlot`: the game's runtime config for that
  loadout slot, including the `ModDataMap`; works independently of which menu screen is open
- `WeaponData(config, dataOverride?)` — weapon data asset plus `DisplayName` / path / `IsRanged`
  (pass `dataOverride` to report the base asset when the config holds a runtime copy)
- `EquippedWeaponData(slot, index)` — the runtime (attachment-adjusted) weapon data of the
  equipped config plus the original base asset: after `SetBaseFromSlot` the config's
  `EquippableData` is a transient copy under the player state, so `Weapons.Raw()` on it yields
  the game-adjusted hidden stats (`OriginalEquippableData` still points at the base asset)
- `ConfigParts(config)` — equipped attachments from `ModDataMap` (+ `ModDataArray` extras) with
  slot/part display names (localized `DisplayName`, falling back to `PrettyName` of the asset
  name), `AttributeModifierMap` modifiers and curve-expanded multipliers
- `PrettyName(assetName, prefix)` — `"WPD_WAR45_Mag_Extended"` + `"WPD_"` ->
  `"WAR45 Mag Extended"`
- `ScratchWidget()`, `ConfigBars(config)`, `DataBars(equippableData)`, `EquippedBars(slot, index)` —
  a scratch `SBZMainMenuWeaponStatsWidget` instance (created once, never added to the viewport) is
  asked for the game's own `SetBaseFromEquippableConfig` / `SetBaseFromEquippableData` /
  `SetBaseFromSlot` computation, yielding the exact `BaseWeaponStats` bars, ammo and fire type
  normalized to 0..100 (all-zero results are rejected: the native setter silently refuses a
  config whose object references did not marshal); `DataBars` is the bare weapon without
  attachments, `EquippedBars` the equipped config including attachments; live game widgets are
  only ever read, never mutated

### game.heist
- `Watch(ref, { Enter = fn(ref), Exit = fn(ref, reason) })` -> id — fires `Enter` when the
  live mission's heist ref matches and `Exit` when leaving it; keep hooks/timers idle outside
  the heist
- `Unwatch(id)`, `Active()` -> ref|nil, `Probe()` (re-detect on the next tick)
- Exit reasons: `menu`, `restart`, `level` (heist changed), `unwatch`
- Detection runs once per level init (deferred out of hook context); no polling. A level
  restart fires `Exit`, the following level init re-arms. Mission end does not fire `Exit` —
  the mission state stays alive until the level changes

### game.spawn
Direct actor spawning for test rigs and training areas (game thread only).

- `Statics()` — cached `KismetMathLibrary` + `GameplayStatics` CDOs resolved with
  `StaticFindObject` (this UE4SS build has no Lua globals for script classes)
- `ActorFromClass(class, { X, Y, Z }, yawDeg, world?)` -> `actor, err` — `MakeVector` ->
  `MakeRotator(0, 0, yaw)` -> `MakeTransform` -> `BeginDeferredActorSpawnFromClass(world, class,
  transform, AlwaysSpawn, nil, TransformScale)` -> `FinishSpawningActor`; every step pcall'd
- `OffsetLocation(x, y, yawDeg, distanceCm)` -> `offsetX, offsetY`, `FacingYaw(playerYaw)`,
  `YawRadians(deg)` — pure placement math
- `Destroy(actor)` — `K2_DestroyActor` in protected mode
- Caveat: pawns spawned this way are not registered by the game's spawn pipeline; see the
  kill-hook hazard in `docs/knowledge-base.md` before letting them die next to
  damage/kill-hook mods

### game.ai
- `NeedsFreeze(lastReason, reason)` — dedupe predicate (true when the controller's last
  disabled reason differs)
- `FreezePawn(pawn, reason?)` -> `ok, detail` — `SBZAIController:SetAIEnabled(false, FName)`;
  deduped against `LastDisabledReason` and an in-memory cache, unsupported controllers (no
  `SetAIEnabled`, e.g. the Moon drone) are cached and logged once
- `ControllerOf(pawn)`, `IsFreezeUnsupported(pawn)`, `FrozenCount()`, `Reset()` (clear caches on
  level change)
- **Hard rule**: never register a UE4SS hook on `SetAIEnabled` in a mod that calls it — calling a
  hooked UFunction re-enters the hook and crashes

### game.chat
- `Available()` — true when `SBZChatInGame` exists in the level
- `Get()` — the live `SBZChatInGame` instance (or nil)
- `Send(text)` -> `ok, err` — one chat line through
  `SBZChatInGame:SendChatMessageToServer({PlayerState=…, Message=…})`
- `SendFmt(fmt, …)` — `string.format` wrapper over `Send`
- Works **solo / as host**: the server path executes locally and the message is multicasted back
  into the local feed (field-proven in solo; client-role multiplayer untested). Messages are not
  truncated — keep lines short.
- The feed renders the game's `DT_ChatRichTextStyles` rich-text tags: `default` (white 85%),
  `PlayerName` (light mint), `Object` / `Callout` (amber, outlined), `Good` (green),
  `Bad` / `Hostile` (red), `Hud_01` (light green), `Blue`, `Skills1` (orange, 15 pt),
  `StatDescription` (yellow), `Skill`, `Notation` (white, outlined). Example:
  `pd3.chat.Send("<Good>done</>")`

## Multi-mod use

pd3lib is designed to be loaded by several mods at once:

- Each UE4SS mod runs in its own Lua state, so every mod that requires pd3lib loads an
  independent copy. Module state (log prefix, debug flag, hook/key registries, selftest checks)
  is per mod — one mod cannot clobber another's settings.
- `pd3.Init` per mod is safe. `pd3.Unload()` from one mod unhooks only that mod's hooks.
- Hooks registered on the same engine function by two mods both fire; ordering is not guaranteed.
- Two mods binding the same key both get the callback. Prefer unique keys for global shortcuts.
- Each mod vendors its own pd3lib, so different versions cannot conflict — there is no shared
  folder to overwrite.
- `UnregisterKeyBind` does not exist in UE4SS; `pd3.keys.UnbindAll()` cannot remove bindings and
  logs a warning. Bindings only go away when the game (or mod) unloads.

## UE4SS marshalling quirks

Hard-won constraints of the PAYDAY 3 UE4SS build (all crash-dump or in-game verified):

- **FText property wrappers**: resolving one (`Value:get()`) crashes UE4SS marshalling
  (access violation in `UE4SS.dll`). Use `Safe.Text` / `Safe.TextOrNil`. Localized menu
  FTexts can also stringify to a single space — treat whitespace as missing.
- **By-value struct returns lose containers**: an `FSBZEquippableConfig` returned by a
  UFunction keeps `EquippableData` but its `ModDataArray`/`ModDataMap` read empty. Read
  from a live object property instead (e.g. a widget's struct property), which marshals
  correctly.
- **TArray access is inconsistent**: `#` and `GetArrayNum` can disagree; nested TArrays
  inside structs may report `0` from both even when the native code sees elements. Prefer
  iterating live-object properties; treat `0` with suspicion.
- **TMap `Size`/`#` can fail while `ForEach` works** — use `Maps.Count`/`Maps.ForEach`.
- **Out-parameter tables are not supported**: appending an out-table argument raises
  `UFunction expected N parameters, received N+1`; only direct returns work.
- **FName arguments**: pass the `Safe.ToFName` userdata; Lua strings crash marshalling.
- **UFunction members are userdata with `__call`** — call them; do not `type() == "function"`
  before calling.
- **`LoadAsset` only works on the game thread** — keybind callbacks run on the input thread and
  get `Function 'LoadAsset' can only be called from within the game thread`; defer with
  `pd3.timers.InGameThread(fn)` / `pd3.timers.After(ms, fn)`.

## Vendoring

Vendoring means shipping pd3lib inside your mod. It is the only supported install:

```
MyMod/
  scripts/
    main.lua
    pd3lib.lua        <- copy of this repo's pd3lib.lua
    pd3lib/
      core/
      game/
      selftest.lua
      LICENSE.md
```

`require("pd3lib")` resolves to `scripts/pd3lib.lua`, and the library's internal
`require("pd3lib.core.*")` calls resolve inside `scripts/pd3lib/`.

Why: a vendored mod keeps working forever — regardless of later pd3lib releases or other mods,
and even if its author leaves the scene. `release.ps1` builds the download zip in exactly this
layout.

## Selftest

```lua
pd3.Init({ enableSelftest = true, selftestKey = Key.F10 })
-- or call directly:
pd3.selftest.Run()
```

Runs PASS/FAIL checks against the live game state (world accessors, finders, interactor, hooks,
timers). Mods can add checks with `pd3.selftest.Add(name, fn)` where `fn` returns `ok, info`.

## Documentation

- [`docs/api/index.md`](docs/api/index.md) — per-class API reference generated from the LuaCATS
  annotations in the source.
- [`docs/knowledge-base.md`](docs/knowledge-base.md) — PAYDAY 3 notes: authority/topology,
  interaction flow, human shield, challenge/achievement internals, UE4SS data-type pitfalls and
  reference tables.

Regenerate the API reference after annotation changes:

```
cargo install emmylua_doc_cli --locked
emmylua_doc_cli . -f markdown -o docs/api --site-name pd3lib
```

The CLI writes into `docs/api/docs/` plus a generated `docs/api/mkdocs.yml`; move `index.md`,
`modules/` and `types/` up into `docs/api/` and delete the extra files to match the committed
layout.

## Versioning

`pd3.Version` is an integer major; repo tags follow `v<major>.<minor>.<patch>`. See
[CHANGELOG.md](CHANGELOG.md).

Compatibility policy:

- Within a major, changes are additive only. Existing public functions, fields, argument
  orders and return shapes are never removed, renamed or repurposed.
- Breaking changes bump the major. Released mods are unaffected — they vendor the version they
  shipped with — and old versions stay downloadable on ModWorkshop and GitHub.
- Because every mod carries its own copy, there is nothing to update in place and no way for a
  newer pd3lib to break an older mod.

## License

[MIT](LICENSE.md)
