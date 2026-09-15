# pd3lib

Lua helper library for Payday 3 UE4SS mods. Split into `core` (generic UE4SS/UE helpers) and `game` (Payday 3 specific systems), plus a `selftest`.

Version: 1

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

### core.world
- `GetPlayerController()`, `GetPawn()`, `GetPlayerState()`, `GetWorld()`, `GetLevelName()`
- `FindAll(className)` (safe `FindAllOf`, always returns a table)
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

### Other hazards
- `FindAllOf` needs the exact short class name; blueprint classes end with `_C` (the package/asset name does not work).
- `FindAllOf("Actor")` is heavy — filter by class path substring and distance; prefer the per-class lists in `game.entities`.
- Hook value parameters (ints/bools) arrive as opaque `RemoteUnrealParam` — their values are not readable via Lua.
- Inside hook callbacks, property reads on the context object were observed returning `nil`; read state with your own helpers instead.

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
