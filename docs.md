# pd3lib

Lua helper library for Payday 3 UE4SS mods. Split into `core` (generic UE4SS/UE helpers) and `game` (Payday 3 specific systems), plus a `selftest`.

Version: 2

## Install

Copy `shared/pd3lib/` into your UE4SS `Mods/shared/` directory (same convention as `UEHelpers`).
From any mod:

```lua
local pd3 = require("pd3lib")
pd3.Init({ prefix = "[MyMod]", debug = false })
```

`Init` options:

| Option | Default | Meaning |
|---|---|---|
| `prefix` | `[pd3lib]` | log line prefix |
| `debug` | `false` | enables `pd3.log.Debug` |
| `enableSelftest` | `false` | bind selftest key |
| `selftestKey` | none | e.g. `Key.F10`, used only when `enableSelftest = true` |

```lua
pd3.keys.Bind(Key.F5, function() end, "my key")
pd3.hooks.HookLogged("/Script/Starbreeze.SBZInteractorComponent:Multicast_CompletedInteraction", function(ctx) end)
pd3.lifecycle.OnLevelInit(function(levelName) pd3.log.Info("level %s", tostring(levelName)) end)
pd3.timers.After(1000, function() end)
pd3.Unload() -- unhooks everything; keybind removal only if UE4SS supports it
```

## Modules

### core.log
`SetPrefix`, `SetDebug`, `Info`, `Warn`, `Err`, `Debug`, `Dump(table, depth)`. All `Info`-family calls accept `string.format` style args.

### core.safe
- `Call(fn, ...)` -> `ok, ...`
- `Get(obj, prop)` / `Set(obj, prop, value)` / `CallFn(obj, name, ...)`
- `IsValid(obj)`, `Describe(value)` (object full name + class; unwraps hook `:get()` wrappers)
- `Text(ftext)` (FText -> string, `KismetTextLibrary` fallback)
- `Count(obj, arrayProp)`, `Num(value, default)`

All helpers swallow errors via `pcall`; they never raise.

### core.safe (value resolution)
- `Resolve(value)` — unwraps UE4SS value wrappers: `RemoteUnrealParam`/`LocalUnrealParam` via `:get()`; `FString`/`FName`/`FText`/`FGuid` via `:ToString()` (returns a Lua string); UObject derivatives pass through unchanged (`GetFullName` guard); depth-capped to avoid wrapper loops.
- `String(value)` — `Resolve` then `tostring` for primitives, `Describe` fallback.
- `ArrayCount(value)` — `#`, then `GetArrayNum`, else nil (`TrivialObject` arrays support neither).
- `ToFName(text)` -> `FName` userdata, `index` — pre-builds FNames for UFunction arguments (see hazards: Lua string -> FName marshalling crashed this build). Returns nil if the name is not in the pool.

### core.maps
- `Size(map)`, `Find(map, key)`, `Contains(map, key)`
- `ForEach(map, fn)` — `fn(key, value)`; keys are resolved, callback errors logged per element.
- **This UE4SS build**: TMap callbacks must not return a value — a non-nil return aborts iteration with `attempt to call a nil value`. Early-stop is therefore unavailable; count/skip inside the closure. `pairs()` never works on TMaps.

### core.reflect
Introspection-driven dumpers that keep working across game updates (no hardcoded offsets).
- `SetDefaults{ MaxDepth=1, MaxArray=25, MaxString=200, MaxLines=400, Skip={ ModeArray, ModeDataArray } }` — per-call `opts` override, `MaxArray/MaxString/MaxLines = 0` mean unlimited.
- `DumpProperties(target, opts)` — all reflected properties with values + type tags; `opts.Filter` = name substring; truncation is always logged.
- `DumpStruct(value, structNameOrObject, opts)` — struct fields via its `UScriptStruct` (e.g. `"SBZChallengeData"`, `"SBZStatisticCriteriaData"`, `"SBZEndMissionResultData"`, `"SBZInternalStatData"`).
- `DumpClass(nameOrPath, opts)`, `DumpEnum(nameOrObject, opts)`, `PropertiesOf(target)`, `FunctionsOf(struct)`, `FindStruct(nameOrPath)`, `Format(value, opts, depth, property)`.
- Safe defaults: known-freeze props skipped, arrays capped, output budgeted, everything pcall'd.

### core.world
- `GetPlayerController()`, `GetPawn()`, `GetPlayerState()`, `GetWorld()`, `GetLevelName()`
- `FindAll(className)` (safe `FindAllOf`, always returns a table)
- `FindLive(className)` — first non-`Default__` valid instance (plus full name)
- `Distance(a, b)` (actors or vectors)
- `ActorsInPath(pathSubstring, aroundActor, maxDistance)` — iterates all actors, filters by class path substring, sorts by distance
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
`Bind(key, fn, description)`, `UnbindAll()`, `Count()`. `UnbindAll` warns if `UnregisterKeyBind` is unavailable in the UE4SS build.

### core.lifecycle
`OnLevelInit(fn)`, `OnLevelRestart(fn)`, `OnMissionEnd(fn)`, `OnReturnToMenu(fn)`. Registration is lazy: hooks are installed on first callback.

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
- `HookPaths` — table of known hook paths (interaction + human shield state machine)
- `EnableDiscoveryLogging()` — hooks every path in `HookPaths` with fire logging

### game.shield
- `Grab(pawn, victim, completeDelayMs)` — player human shield grab via interaction system
- `Release()` — cancels `GA_HumanShieldInstigator_C` instances (skips `Default__`)
- `InstigatorState(pawn)`, `StateName(value)`, `VictimFlags(victim)`
- `AIInstigatorUnsupported = true` — do not attempt AI-driven human shields; see below

### game.challenge
Challenge / achievement access.
- `Manager()`, `AchievementManager()` — live instances (`Default__` CDO skipped)
- `Achievements(manager)`, `AllChallenges(manager)` — the `AchievementMap` / `ChallengeMap` TMaps
- `StatusNames`, `StatusName(v)` — `0 INIT`, `1 INPROGRESS`, `2 COMPLETED`, `3 UNAVAILABLE`; `CompletedStatus = 2`
- `Find(manager, needle)` — summaries (key/id/name/status/progress) whose id, name or key contains `needle`
- `IsCompleted(manager, needle)` -> `ok, summary`
- `CodeFor(challengeName)` — challenge FName -> AccelByte code (e.g. `ACH_*`) via the settings CDO property
- `Complete(achievementId)` — calls `SBZAchievementManager:CompleteAchievement(id)`

### game.mission
Mission state snapshot.
- `Get()` — live `SBZMissionState`
- `Difficulty(state)` -> `value, name`; `DifficultyNames`
- `HeistData(state)`, `HeistRef(state)` — heist token such as `penthouse`
- `Escape(state)` -> `{ TimeLeft, PlayersIn, PlayersRequired }`
- `Criterion(name)` — e.g. `Criterion("InsurancePolicy")`; nil outside a mission

## Payday 3 knowledge base

### Authority / topology
- Offline solo mode runs with local authority: `Server_*` calls execute locally and multicast hooks fire.
- Online/solo-online: the game runs on a remote server. Client Lua can only affect the server through `Server_*` RPCs on player-owned actors (e.g. `SBZPlayerInteractorComponent`, `SBZPlayerState`). Calls on AI-owned objects do not route.
- Check with `pd3.world.HasAuthority(pawn)` / `Owner`.

### Interaction flow (how the game actually performs interactions)
1. Client: `interactor:Server_StartInteraction(interactable, id, modeIndex)`
2. Server: validates, runs the interaction; multicasts `Multicast_StartSimulatedInteraction` (animated interactions) and `Multicast_CompletedInteraction`.
3. Optional client `Server_CompleteInteraction(interactable, id)` — the server often completes by itself; extra call observed harmless.
4. `id` is the interactor's `InteractId`; reuse it for complete/stop.

Human shield grab for the player: `modeIndex` = interactor's `ModeIndex` (observed `0` on a surrendered civilian), then completion leads to `Multicast_HumanShieldInstigatorSlotReached` and `HumanShieldInstigatorState = 3 (Grabbing)` within ~1-2s.

### Mode index caveats
- `InModeIndex` semantics are not reliably enumerable at runtime: reading `SBZAICharacterInteractableComponent.ModeArray` (TArray of enums) and `ModeDataArray` froze the game thread. Do not read them.
- Empirically: `1` triggered the human shield path on a crew interaction; `0` behaved like a command/follow action. Do not assume the enum name-to-index mapping.
- The victim's `Interactable.ModeIndex` property shows the currently selected mode; the player interactor's `ModeIndex` is what the client itself passes.

### Human shield
- Player grab/release works and is implemented in `game.shield`.
- `TryActivateAbilityByClass(GA_HumanShieldInstigator_C)` alone does not perform a grab — the grab is interaction-driven.
- Release: cancel the granted ability instance via `K2_CancelAbility` (objects found with `FindAllOf`, skipping `Default__`).
- **AI instigator crashes the game.** With a crew `SBZAIInteractorComponent` and `modeIndex = 1`, the interaction starts and completes, then the engine crashes before `SlotReached`. Player pawn has the same zero `HumanShieldSlotParameters`, so this is a code-level assumption (player-only instigator path), not missing data. Never trigger it.

### UE4SS Lua data-type pitfalls
- Property/param values arrive as wrappers; unwrap with `pd3.safe.Resolve` or `pd3.safe.String`:
  - `FString` / `FName` / `FText` / `FGuid` -> `:ToString()`
  - `RemoteUnrealParam` / `LocalUnrealParam` -> `:get()`
  - UObject derivatives -> keep as-is; `Describe`/`GetFullName` works directly.
  - Unwrapped names otherwise print as `FString: 0x...`, `FNameUserdata: 0x...`.
- `pairs()` does not work on `TMap`; use `:ForEach` (see `core.maps`). A callback that returns a value aborts iteration in this build.
- Arrays of structs can come back as opaque `TrivialObject` wrappers with no `#` and no `GetArrayNum` (e.g. `SBZAchievementManager.CompletedChallenges`). Read status through the challenge/achievement maps instead.
- Lua strings are accepted where `FName`/`FString` parameters are expected; conversion is automatic.
- Hook callback parameters are wrappers too; resolve before logging (resolved ints/bools stay opaque — no `:get()` value access for value types).

### Achievements and challenges
- `BP_ChallengeManager_C` (subclass of `USBZChallengeManager`) and `SBZAchievementManager` live on `PD3_GameInstance_C` (transient engine objects), findable with `FindAllOf` (skip `Default__`). `game.challenge` wraps this.
- `AchievementMap` (TMap<FName, FSBZChallengeData>) keys are hashed FNames; `ChallengeName` is human-readable, e.g. `Achievement Steam Penthouse Human Shield Extract`.
- `SBZChallengeToAchievementSettings` (CDO at `/Script/Starbreeze.Default__SBZChallengeToAchievementSettings`) maps challenge FName -> AccelByte code (`ACH_PH_HUMAN_SHIELD_EXTRACT`). Platform variants (Steam/XBox/PlayStation/Epic) share one AccelByte code but have distinct hashed keys.
- Completion: `SBZAchievementManager:CompleteAchievement(FName)` — accepts the map key or the `ACH_*` code (try both; verify via map status flipping to `COMPLETED(2)`). Fallback lever: `AchievementWriteCallbackProxy:WriteAchievementProgress`.
- Native criteria live in `SBZStatisticCriteriaData` assets (`/Game/Gameplay/Data/StatisticData/DA_*`, e.g. `DA_InsurancePolicy`): `StatisticCode` is a kebab-case stat id (`penthouse-human-shield-extract`), `LowestDifficulty`, `MinPassableState`/`MaxPassableState`, `HeistDataArray`. Live read: `pd3.mission.Criterion("InsurancePolicy")` (a copy exists on `SBZMissionState.StatisticsCriteriaDataCollection`).
- Achievements are evaluated server/backend side from stats; there is no client-side criteria re-check, so a forced `CompleteAchievement` call bypasses the stat requirement entirely (persistence depends on the backend accepting the client write).

### Mission, difficulty, escape
- `SBZMissionState.Difficulty` — `0 Normal`, `1 Hard`, `2 VeryHard`, `3 Overkill`.
- `CurrentHeistData:GetHeistReferenceText()` -> heist token (`penthouse`); the *level* name (`Sky` for Touch The Sky) is different — gate on the heist ref, not the level.
- `EscapeTimeLeft`, `PlayersInEscapeVolume`, `PlayersRequiredInEscapeVolume`; `Multicast_SetEscapeVolumeData(PlayersIn, Total)` fires on changes. Escape volumes are `ASBZPlayerEscapeVolume : ASBZPlayerTriggerVolume : ATriggerVolume` (`EncompassesPoint` usable).

### Reflection dumping (game update workflow)
- After a patch, re-discover instead of trusting old field names:
  1. `pd3.reflect.DumpProperties(liveObject, { Filter = "..." })` for objects (class + function lists via `DumpClass`).
  2. `pd3.reflect.DumpStruct(value, "StructName")` for records — struct names drop the `F` prefix: `FSBZChallengeData` -> `SBZChallengeData`, `FSBZEndMissionResultData` -> `SBZEndMissionResultData`.
  3. `pd3.reflect.DumpEnum("EnumName")` for enums.
- Curated dumpers built on it: `pd3.challenge.DumpRecord/DumpStatMap/DumpCaches`, `pd3.mission.DumpCriterion/DumpHeistData/DumpMissionResult`; `InsurancePolicyMod` binds `F9` to a combined reflection dump.
- Output is budgeted and truncation is logged (`MaxArray/MaxLines/MaxDepth/MaxString`, `0` = unlimited); known-freeze properties are skipped by default.

### Session vs platform state
- Forced achievement unlocks do not flip local `ChallengeMap` status mid-session: `unlock postcheck: unlocked=false` right after a successful unlock is expected. The platform UI (Steam/console) is authoritative; map status refreshes after re-login/backend resync.

### Other hazards
- `FindAllOf` needs the exact short class name; blueprint classes end with `_C` (the package/asset name does not work).
- `FindAllOf("Actor")` is heavy — filter by class path substring and distance; prefer the per-class lists in `game.entities`.
- Hook value parameters (ints/bools) arrive as opaque `RemoteUnrealParam` — their values are not readable via Lua.
- Inside hook callbacks, property reads on the context object were observed returning `nil`; read state with your own helpers instead.
- `SBZChallengeManager:GetStatProgress(statId)` froze the game thread (same hazard class as `ModeArray`). Do not call it; read criteria assets/stat codes instead.
- UFunction getters that return `TMap`/`TArray` **by value** (`SBZChallengeToAchievementSettings:GetChallengeToAchievementSettings`, `GetAchievementObjectiveStatCodeArray`) are suspect: one F2 probe ended in an engine crash right after such calls. Read the backing UPROPERTY instead.
- **Hook callbacks**: never call UFunctions (or rich converters that may call them) from inside a hook pre-callback. Calling a UFunction you also hook re-enters your own callback; this crashed UE4SS in `push_nameproperty` (null name-property deref). Defer work with `pd3.timers.After/InGameThread`, or unhook first. Hook params are wrappers: only `Safe.Resolve/String` (which uses `:get()`/`:ToString()` exclusively) are safe on them.
- `Safe.Resolve` never invokes object methods on unknown wrappers on purpose: calling `GetFullName`/`GetClass` on FName/FString/param values crashes UE4SS marshalling. `Safe.Describe` gates the object path behind `type()`/member checks.

### Reference tables

Civilians: `CH_Civilian_01_C`, `CH_Civilian_Female_01_C`, `CH_Civilian_Employee_Male_01_C`, `CH_Civilian_Employee_Female_01_C`, `CH_Civilian_ArtGallery_Manager_male_01_C`

Crew: `CH_CrewAI_Dallas_C`, `CH_CrewAI_Hoxton_C`, `CH_CrewAI_Wolf_C`, `CH_CrewAI_Chains_C`

Interactor / interactable:
- Player: `SBZPlayerCharacter.Interactor` (`SBZPlayerInteractorComponent`)
- AI: `SBZAICharacter.AIInteractorComponent` (`SBZAIInteractorComponent`)
- Target: `SBZCharacter.Interactable` (`SBZAICharacterInteractableComponent` / `SBZCharacterInteractableComponent`)

Ability: `/Game/Gameplay/Abilities/GA_HumanShieldInstigator.GA_HumanShieldInstigator_C`

Useful RPCs / functions:
- `SBZInteractorComponent:Server_StartInteraction / Server_CompleteInteraction / Server_StopInteraction`
- `SBZCharacter:Server_HumanShieldInstigatorSlotReached`
- `SBZPlayerState:Server_DebugConsoleCommand(command, context, locallyControlledOnly, executedOnAll, playerIndex)`
- `SBZCheatManager:InteractAITarget(action, playerIndex)` — AI actions: `None`, `GetDown`, `HogTie`, `Follow`, `TradeHostage`
- `SBZShoutoutComponent:Server_SendPing(location)`

`ESBZAICharacterInteractableMode`: `0 PickUp`, `1 HumanShield`, `2 AnswerPager`, `3 OrderDownOnGround`, `4 TieHands`, `5 OrderFollow`, `6 TradeHostage`, `7 KillHumanShield`, `8 PickUpKilledHumanShield`, `9 HackerGlitchProtocol`, `10 None`

`ESBZInteractionAction`: `0 None`, `1 GetDown`, `2 HogTie`, `3 Follow`, `4 TradeHostage`

`ESBZHumanShieldInstigatorState`: `0 None`, `1 ReachingSlot`, `2 EnterGrabbing`, `3 Grabbing`, `4 Choking`, `5 Exiting`

## Selftest

```lua
pd3.Init({ enableSelftest = true, selftestKey = Key.F10 })
-- or call directly:
pd3.selftest.Run()
```

Runs PASS/FAIL checks against live game state (world accessors, finders, interactor, hooks, timers). Mods can add checks with `pd3.selftest.Add(name, fn)` where `fn` returns `ok, info`.
