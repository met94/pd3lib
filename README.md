# pd3lib

Lua helper library for PAYDAY 3 UE4SS mods. Generic UE4SS/UE scaffolding (`core`), PAYDAY 3
specific helpers (`game`), a reflection toolkit that keeps working across game updates, and a
live selftest.

pd3lib is a dependency for other mods. It does nothing on its own — install it if a mod
requires it, or use it to build your own.

## Requirements

- PAYDAY 3 + **PD3 UE4SS V3.01 + Allow Pak Mods (BETA)** (ModWorkshop mod 47771, UE4SS
  v3.0.1 Beta #0). Older UE4SS builds miss APIs the library relies on; the library is tested
  against this build.
- No other dependencies. Pure Lua 5.1-compatible code (runs on the UE4SS Lua runtime).

## Install

Copy this repository's contents into:

```
...\PAYDAY3\Binaries\Win64\ue4ss\Mods\shared\pd3lib
```

UE4SS puts `Mods/shared` on every Lua mod's `require` path, so mods load the library with
`require("pd3lib")`. Each mod gets its own copy — see [Multi-mod use](#multi-mod-use).

Developers: add this repo as a git submodule and mirror it into `Mods/shared/pd3lib` from
your deploy script.

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
- `IsValid(obj)`, `Describe(value)` (object full name + class; unwraps hook `:get()` wrappers)
- `Text(ftext)` (FText -> string, `KismetTextLibrary` fallback)
- `Count(obj, arrayProp)`, `Num(value, default)`
- `Resolve(value)` — unwraps UE4SS value wrappers: `RemoteUnrealParam`/`LocalUnrealParam` via
  `:get()`; `FString`/`FName`/`FText`/`FGuid` via `:ToString()` (returns a Lua string); UObject
  derivatives pass through unchanged (`GetFullName` guard); depth-capped to avoid wrapper loops.
- `String(value)` — `Resolve` then `tostring` for primitives, `Describe` fallback.
- `ArrayCount(value)` — `#`, then `GetArrayNum`, else nil (`TrivialObject` arrays support neither).
- `ToFName(text)` -> `FName` userdata, `index` — pre-builds FNames for UFunction arguments (Lua
  string -> FName marshalling crashed the tested UE4SS build). Returns nil if the name is not in
  the name pool.

### core.maps
- `Size(map)`, `Find(map, key)`, `Contains(map, key)`
- `ForEach(map, fn)` — `fn(key, value)`; keys are resolved, callback errors logged per element.

**Tested UE4SS build**: TMap callbacks must not return a value — a non-nil return aborts
iteration. Early-stop is therefore unavailable; count/skip inside the closure. `pairs()` never
works on TMaps.

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
- `Distance(a, b)` (actors or vectors)
- `ActorsInPath(pathSubstring, aroundActor, maxDistance)` — iterates all actors, filters by class
  path substring, sorts by distance
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
- `Difficulty(state)` -> `value, name`; `DifficultyNames`
- `HeistData(state)`, `HeistRef(state)` — heist token such as `penthouse`
- `Escape(state)` -> `{ TimeLeft, PlayersIn, PlayersRequired }`
- `Criterion(name)` — e.g. `Criterion("InsurancePolicy")`; nil outside a mission

### game.heist
- `Watch(ref, { Enter = fn(ref), Exit = fn(ref, reason) })` -> id — fires `Enter` when the
  live mission's heist ref matches and `Exit` when leaving it; keep hooks/timers idle outside
  the heist
- `Unwatch(id)`, `Active()` -> ref|nil, `Probe()` (re-detect on the next tick)
- Exit reasons: `menu`, `restart`, `level` (heist changed), `unwatch`
- Detection runs once per level init (deferred out of hook context); no polling. A level
  restart fires `Exit`, the following level init re-arms. Mission end does not fire `Exit` —
  the mission state stays alive until the level changes

## Multi-mod use

pd3lib is designed to be loaded by several mods at once:

- Each UE4SS mod runs in its own Lua state, so every mod that requires pd3lib loads an
  independent copy. Module state (log prefix, debug flag, hook/key registries, selftest checks)
  is per mod — one mod cannot clobber another's settings.
- `pd3.Init` per mod is safe. `pd3.Unload()` from one mod unhooks only that mod's hooks.
- Hooks registered on the same engine function by two mods both fire; ordering is not guaranteed.
- Two mods binding the same key both get the callback. Prefer unique keys for global shortcuts.
- `Mods/shared` holds exactly one pd3lib. If two mods ship different versions, the one deployed
  last wins — pin a compatible version and state the minimum `pd3.Version` you need.
- `UnregisterKeyBind` does not exist in UE4SS; `pd3.keys.UnbindAll()` cannot remove bindings and
  logs a warning. Bindings only go away when the game (or mod) unloads.

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

## Versioning

`pd3.Version` is an integer compatibility line, bumped on breaking API changes; additive changes
keep the number. Repo tags follow `v<Version>.<minor>.<patch>`. See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE.md)
