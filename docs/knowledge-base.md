# PAYDAY 3 knowledge base

Engine notes gathered while building pd3lib. Module/API summary lives in the
[README](../README.md); this page is the "why" behind the crash workarounds and the reference
tables used by the `game.*` modules.

## Authority / topology

- Offline solo mode runs with local authority: `Server_*` calls execute locally and multicast
  hooks fire.
- Online/solo-online: the game runs on a remote server. Client Lua can only affect the server
  through `Server_*` RPCs on player-owned actors (e.g. `SBZPlayerInteractorComponent`,
  `SBZPlayerState`). Calls on AI-owned objects do not route.
- Check with `pd3.world.HasAuthority(pawn)` / `Owner`.

## Interaction flow (how the game actually performs interactions)

1. Client: `interactor:Server_StartInteraction(interactable, id, modeIndex)`
2. Server: validates, runs the interaction; multicasts `Multicast_StartSimulatedInteraction`
   (animated interactions) and `Multicast_CompletedInteraction`.
3. Optional client `Server_CompleteInteraction(interactable, id)` — the server often completes by
   itself; extra call observed harmless.
4. `id` is the interactor's `InteractId`; reuse it for complete/stop.

Human shield grab for the player: `modeIndex` = interactor's `ModeIndex` (observed `0` on a
surrendered civilian), then completion leads to `Multicast_HumanShieldInstigatorSlotReached` and
`HumanShieldInstigatorState = 3 (Grabbing)` within ~1-2s.

## Mode index caveats

- `InModeIndex` semantics are not reliably enumerable at runtime: reading
  `SBZAICharacterInteractableComponent.ModeArray` (TArray of enums) and `ModeDataArray` froze the
  game thread. Do not read them.
- Empirically: `1` triggered the human shield path on a crew interaction; `0` behaved like a
  command/follow action. Do not assume the enum name-to-index mapping.
- The victim's `Interactable.ModeIndex` property shows the currently selected mode; the player
  interactor's `ModeIndex` is what the client itself passes.

## Human shield

- Player grab/release works and is implemented in `game.shield`.
- `TryActivateAbilityByClass(GA_HumanShieldInstigator_C)` alone does not perform a grab — the
  grab is interaction-driven.
- Release: cancel the granted ability instance via `K2_CancelAbility` (objects found with
  `FindAllOf`, skipping `Default__`).
- **AI instigator crashes the game.** With a crew `SBZAIInteractorComponent` and `modeIndex = 1`,
  the interaction starts and completes, then the engine crashes before `SlotReached`. Player pawn
  has the same zero `HumanShieldSlotParameters`, so this is a code-level assumption
  (player-only instigator path), not missing data. Never trigger it.

## UE4SS Lua data-type pitfalls

- Property/param values arrive as wrappers; unwrap with `pd3.safe.Resolve` or `pd3.safe.String`:
  - `FString` / `FName` / `FText` / `FGuid` -> `:ToString()`
  - `RemoteUnrealParam` / `LocalUnrealParam` -> `:get()`
  - UObject derivatives -> keep as-is; `Describe`/`GetFullName` works directly.
  - Unwrapped names otherwise print as `FString: 0x...`, `FNameUserdata: 0x...`.
- `pairs()` does not work on `TMap`; use `:ForEach` (see `core.maps`). A callback that returns a
  value aborts iteration in the tested build.
- Arrays of structs can come back as opaque `TrivialObject` wrappers with no `#` and no
  `GetArrayNum` (e.g. `SBZAchievementManager.CompletedChallenges`). Read status through the
  challenge/achievement maps instead.
- Lua strings are accepted where `FName`/`FString` parameters are expected; conversion is
  automatic — except where it crashed this build (see `core.safe.ToFName`).
- Hook callback parameters are wrappers too; resolve before logging (resolved ints/bools stay
  opaque — no `:get()` value access for value types).

## Achievements and challenges

- `BP_ChallengeManager_C` (subclass of `USBZChallengeManager`) and `SBZAchievementManager` live on
  `PD3_GameInstance_C` (transient engine objects), findable with `FindAllOf` (skip `Default__`).
  `game.challenge` wraps this.
- `AchievementMap` (TMap<FName, FSBZChallengeData>) keys are hashed FNames; `ChallengeName` is
  human-readable, e.g. `Achievement Steam Penthouse Human Shield Extract`.
- `SBZChallengeToAchievementSettings` (CDO at
  `/Script/Starbreeze.Default__SBZChallengeToAchievementSettings`) maps challenge FName ->
  AccelByte code (`ACH_PH_HUMAN_SHIELD_EXTRACT`). Platform variants (Steam/XBox/PlayStation/Epic)
  share one AccelByte code but have distinct hashed keys.
- Completion: `SBZAchievementManager:CompleteAchievement(FName)` — accepts the map key or the
  `ACH_*` code (try both; verify via map status flipping to `COMPLETED(2)`). Fallback lever:
  `AchievementWriteCallbackProxy:WriteAchievementProgress`.
- Native criteria live in `SBZStatisticCriteriaData` assets
  (`/Game/Gameplay/Data/StatisticData/DA_*`, e.g. `DA_InsurancePolicy`): `StatisticCode` is a
  kebab-case stat id (`penthouse-human-shield-extract`), `LowestDifficulty`,
  `MinPassableState`/`MaxPassableState`, `HeistDataArray`. Live read:
  `pd3.mission.Criterion("InsurancePolicy")` (a copy exists on
  `SBZMissionState.StatisticsCriteriaDataCollection`).
- Achievements are evaluated server/backend side from stats; there is no client-side criteria
  re-check, so a forced `CompleteAchievement` call bypasses the stat requirement entirely
  (persistence depends on the backend accepting the client write).

## Mission, difficulty, escape

- `SBZMissionState.Difficulty` — `0 Normal`, `1 Hard`, `2 VeryHard`, `3 Overkill`.
- `CurrentHeistData:GetHeistReferenceText()` -> heist token (`penthouse`); the *level* name
  (`Sky` for Touch The Sky) is different — gate on the heist ref, not the level.
- `EscapeTimeLeft`, `PlayersInEscapeVolume`, `PlayersRequiredInEscapeVolume`;
  `Multicast_SetEscapeVolumeData(PlayersIn, Total)` fires on changes. Escape volumes are
  `ASBZPlayerEscapeVolume : ASBZPlayerTriggerVolume : ATriggerVolume` (`EncompassesPoint` usable).

## Reflection dumping (game update workflow)

- After a patch, re-discover instead of trusting old field names:
  1. `pd3.reflect.DumpProperties(liveObject, { Filter = "..." })` for objects (class + function
     lists via `DumpClass`).
  2. `pd3.reflect.DumpStruct(value, "StructName")` for records — struct names drop the `F` prefix:
     `FSBZChallengeData` -> `SBZChallengeData`, `FSBZEndMissionResultData` ->
     `SBZEndMissionResultData`.
  3. `pd3.reflect.DumpEnum("EnumName")` for enums.
- Curated dumpers built on it: `pd3.challenge.DumpRecord/DumpStatMap/DumpCaches`,
  `pd3.mission.DumpCriterion/DumpHeistData/DumpMissionResult`.
- Output is budgeted and truncation is logged (`MaxArray/MaxLines/MaxDepth/MaxString`, `0` =
  unlimited); known-freeze properties are skipped by default.

## Session vs platform state

- Forced achievement unlocks do not flip local `ChallengeMap` status mid-session: a postcheck
  reading `unlocked=false` right after a successful unlock is expected. The platform UI
  (Steam/console) is authoritative; map status refreshes after re-login/backend resync.

## Other hazards

- `FindAllOf` needs the exact short class name; blueprint classes end with `_C` (the package/asset
  name does not work).
- `FindAllOf("Actor")` is heavy — filter by class path substring and distance; prefer the per-class
  lists in `game.entities`.
- Hook value parameters (ints/bools) arrive as opaque `RemoteUnrealParam` — their values are not
  readable via Lua.
- Inside hook callbacks, property reads on the context object were observed returning `nil`; read
  state with your own helpers instead.
- `SBZChallengeManager:GetStatProgress(statId)` froze the game thread (same hazard class as
  `ModeArray`). Do not call it; read criteria assets/stat codes instead.
- UFunction getters that return `TMap`/`TArray` **by value** (`SBZChallengeToAchievementSettings:
  GetChallengeToAchievementSettings`, `GetAchievementObjectiveStatCodeArray`) are suspect: one
  probe ended in an engine crash right after such calls. Read the backing UPROPERTY instead.
- **Hook callbacks**: never call UFunctions (or rich converters that may call them) from inside a
  hook pre-callback. Calling a UFunction you also hook re-enters your own callback; this crashed
  UE4SS in `push_nameproperty` (null name-property deref). Defer work with
  `pd3.timers.After/InGameThread`, or unhook first. Hook params are wrappers: only
  `Safe.Resolve/String` (which uses `:get()`/`:ToString()` exclusively) are safe on them.
- `Safe.Resolve` never invokes object methods on unknown wrappers on purpose: calling
  `GetFullName`/`GetClass` on FName/FString/param values crashes UE4SS marshalling.
  `Safe.Describe` gates the object path behind `type()`/member checks.
- **Native hook removal is lazy.** Lua `UnregisterHook` only marks the hook
  (`scheduled_for_removal` in `LuaMod.cpp`): the Lua callback stops firing immediately (the
  pre-hook skips it), but the engine unhook and the verbose `Unregistering native pre-hook
  (...)` log happen when the hooked function is next invoked. Cleanup log lines therefore
  appear at the next fire, not at unhook time — they do not mean hooks leaked.

## Reference tables

Civilians: `CH_Civilian_01_C`, `CH_Civilian_Female_01_C`, `CH_Civilian_Employee_Male_01_C`,
`CH_Civilian_Employee_Female_01_C`, `CH_Civilian_ArtGallery_Manager_male_01_C`

Crew: `CH_CrewAI_Dallas_C`, `CH_CrewAI_Hoxton_C`, `CH_CrewAI_Wolf_C`, `CH_CrewAI_Chains_C`

Interactor / interactable:

- Player: `SBZPlayerCharacter.Interactor` (`SBZPlayerInteractorComponent`)
- AI: `SBZAICharacter.AIInteractorComponent` (`SBZAIInteractorComponent`)
- Target: `SBZCharacter.Interactable` (`SBZAICharacterInteractableComponent` /
  `SBZCharacterInteractableComponent`)

Ability: `/Game/Gameplay/Abilities/GA_HumanShieldInstigator.GA_HumanShieldInstigator_C`

Useful RPCs / functions:

- `SBZInteractorComponent:Server_StartInteraction / Server_CompleteInteraction / Server_StopInteraction`
- `SBZCharacter:Server_HumanShieldInstigatorSlotReached`
- `SBZPlayerState:Server_DebugConsoleCommand(command, context, locallyControlledOnly, executedOnAll, playerIndex)`
- `SBZCheatManager:InteractAITarget(action, playerIndex)` — AI actions: `None`, `GetDown`,
  `HogTie`, `Follow`, `TradeHostage`
- `SBZShoutoutComponent:Server_SendPing(location)`

`ESBZAICharacterInteractableMode`: `0 PickUp`, `1 HumanShield`, `2 AnswerPager`,
`3 OrderDownOnGround`, `4 TieHands`, `5 OrderFollow`, `6 TradeHostage`, `7 KillHumanShield`,
`8 PickUpKilledHumanShield`, `9 HackerGlitchProtocol`, `10 None`

`ESBZInteractionAction`: `0 None`, `1 GetDown`, `2 HogTie`, `3 Follow`, `4 TradeHostage`

`ESBZHumanShieldInstigatorState`: `0 None`, `1 ReachingSlot`, `2 EnterGrabbing`, `3 Grabbing`,
`4 Choking`, `5 Exiting`
