# global core.world








---

## methods
---

### World.GetPlayerController
---
```lua
function World.GetPlayerController() -> controller APlayerController?
```





Local PlayerController. Prefers the local controller with a live pawn so
that a transition/menu or remote controller cached around a level change is
not pinned: a pawnless cache is re-resolved as soon as a local candidate
(pawned or not) exists. Falls back to "Controller" finds and the first
valid controller for menu/loading states.








### World.Reset
---
```lua
function World.Reset() ->  nil
```





Clears the cached PlayerController (call on level change / restart so the
next lookup re-resolves against the new level instead of a stale menu or
previous-level controller).








### World.GetPawn
---
```lua
function World.GetPawn() -> pawn APawn?
```





Pawn of the local PlayerController.








### World.GetPlayerState
---
```lua
function World.GetPlayerState() -> playerState APlayerState?
```





PlayerState of the local PlayerController.








### World.GetWorld
---
```lua
function World.GetWorld() -> world UWorld?
```





UWorld the local player is currently in.








### World.GetLevelName
---
```lua
function World.GetLevelName() -> levelName string?
```





Name of the currently loaded level (e.g. "Sky"), not the heist ref.








### World.FindAll
---
```lua
function World.FindAll(ClassName: string) -> objects UObject[]
```
@param `ClassName` - exact short class name; blueprint classes need the _C suffix






Safe FindAllOf; always returns a table (empty when the class is unknown).








### World.FindLive
---
```lua
function World.FindLive(ClassName: string)
 -> instance UObject?
 -> fullName string?

```
@param `ClassName` - exact short class name; blueprint classes need the _C suffix


@return `fullName` - full name of the found instance





Like FindFirstOf, but skips class default objects and invalid entries.








### World.LoadClass
---
```lua
function World.LoadClass(
  PackagePath: string,
  ClassPath: string
) -> class UObject?
```
@param `PackagePath` - e.g. "/Game/UI/Widgets/Misc/WBP_Tooltip"

@param `ClassPath` - e.g. "/Game/UI/Widgets/Misc/WBP_Tooltip.WBP_Tooltip_C"






Finds a class by object path, loading its package first when needed.








### World.PruneValid
---
```lua
function World.PruneValid(
  List: UObject[]?,
  OnLost: (fun(entry: any, index: integer))?
)
 -> survivors UObject[]
 -> lostCount integer

```





Drops entries that are no longer valid UObjects, calling OnLost(entry, index)
for each dropped one (callback errors are logged, not raised). The original
list is returned unchanged when nothing was lost. Iterate the survivor list
on the next tick and re-resolve, never keep reading properties of entries
that failed this check: stale handles crash natively inside UE4SS, beyond
pcall's reach (see Safe.IsValid).








### World.Distance
---
```lua
function World.Distance(
  From: any,
  To: any
) -> distance number?
```
@param `From` - actor or vector

@param `To` - actor or vector






Euclidean distance between two actors and/or vectors.








### World.ActorsInPath
---
```lua
function World.ActorsInPath(
  PathSubstring: string,
  Around: any,
  MaxDistance: number?
) -> entries { Actor: UObject, Distance: number? }[]
```
@param `PathSubstring` - class path substring, e.g. "SBZPlayerEscapeVolume"

@param `Around` - actor or vector used for Distance

@param `MaxDistance` - nil = unlimited






All actors whose class path contains PathSubstring, optionally within
MaxDistance of Around, sorted nearest-first. Heavy: iterates FindAllOf("Actor").








### World.HasAuthority
---
```lua
function World.HasAuthority(Actor: any) -> hasAuthority boolean?
```





Actor:HasAuthority(); nil when the call is unavailable.








### World.Owner
---
```lua
function World.Owner(Actor: any) -> owner UObject?
```





Actor:GetOwner().











