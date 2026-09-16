# class Interact



- namespace: pd3



Interaction system helpers (SBZInteractorComponent RPCs).

Flow: client calls Server_StartInteraction(interactable, id, modeIndex); the
server validates and multicasts start/complete. id is the interactor's
InteractId - reuse it for Complete/Stop. On online/solo-online only
player-owned actors route to the server.







---

## methods
---

### Interact.ModeName
---
```lua
function Interact.ModeName(Index: any) -> name string
```

@return `name` - "Unknown(n)" when unmapped





Mode name for an ESBZAICharacterInteractableMode index.








### Interact.ActionName
---
```lua
function Interact.ActionName(Index: any) -> name string
```

@return `name` - "Unknown(n)" when unmapped





Name for an ESBZInteractionAction index.








### Interact.PlayerInteractor
---
```lua
function Interact.PlayerInteractor(Pawn: any) -> interactor UObject?
```
@param `Pawn` - SBZPlayerCharacter






The pawn's player interactor component (SBZPlayerInteractorComponent).








### Interact.Start
---
```lua
function Interact.Start(
  InteractorRef: any,
  Interactable: any,
  ModeIndex: integer?,
  Id: integer?
) -> ok boolean
```
@param `InteractorRef` - SBZPlayerInteractorComponent / SBZAIInteractorComponent

@param `Interactable` - target's Interactable component

@param `ModeIndex` - default 0; do not assume enum name-to-index mapping

@param `Id` - default 1; usually the interactor's InteractId


@return `ok` - false when refs are invalid or the call raised





Client-side RPC: Server_StartInteraction(interactable, id, modeIndex).








### Interact.Complete
---
```lua
function Interact.Complete(
  InteractorRef: any,
  Interactable: any,
  Id: integer?
) -> ok boolean
```
@param `Id` - default 1; must match the Start id






Client-side RPC: Server_CompleteInteraction(interactable, id). The server
often completes by itself; an extra call has been observed harmless.








### Interact.Stop
---
```lua
function Interact.Stop(
  InteractorRef: any,
  Interactable: any
) -> ok boolean
```





Client-side RPC: Server_StopInteraction(interactable).








### Interact.StartWithComplete
---
```lua
function Interact.StartWithComplete(
  InteractorRef: any,
  Interactable: any,
  ModeIndex: integer?,
  Id: integer?,
  CompleteDelayMs: integer?
) -> ok boolean
```
@param `CompleteDelayMs` - nil = start only


@return `ok` - Start result





Start, then Complete after CompleteDelayMs (skipped when delay is nil).








### Interact.State
---
```lua
function Interact.State(InteractorRef: any) -> state pd3.Interact.State {
    InteractId = any,
    ModeIndex = any,
    CurrentInteraction = any,
    Selected = any,
}
```





Reads the interactor's current interaction state.








### Interact.EnableDiscoveryLogging
---
```lua
function Interact.EnableDiscoveryLogging() -> registered integer
```

@return `registered` - number of hooks installed successfully





Hooks every path in Interact.HookPaths with full fire logging.











## fields
---

### Interact.Modes
---
```lua
Interact.Modes : table<integer,string>
```



ESBZAICharacterInteractableMode index -> name. Index semantics are not
reliably enumerable at runtime; do not read ModeArray/ModeDataArray.








### Interact.Actions
---
```lua
Interact.Actions : table<integer,string>
```



ESBZInteractionAction index -> name.








### Interact.HookPaths
---
```lua
Interact.HookPaths : table<string,string>
```



Known interaction/state-machine UFunction paths for discovery logging.









