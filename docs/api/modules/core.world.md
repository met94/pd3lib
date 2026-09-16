# global core.world








---

## methods
---

### World.GetPlayerController
---
```lua
function World.GetPlayerController() -> controller APlayerController?
```





First valid local PlayerController (falls back to "Controller" find).








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











