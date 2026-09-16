# global game.entities








---

## methods
---

### Entities.FindByClasses
---
```lua
function Entities.FindByClasses(ClassNames: string[]) -> actors UObject[]
```
@param `ClassNames` - exact short names, _C suffix required for blueprints






Finds all valid live instances of the given class names.








### Entities.Civilians
---
```lua
function Entities.Civilians() -> civilians UObject[]
```





All live civilian characters.








### Entities.CrewPawns
---
```lua
function Entities.CrewPawns() -> crewPawns UObject[]
```





All live crew AI pawns.








### Entities.InRange
---
```lua
function Entities.InRange(
  Actors: UObject[],
  Around: any,
  MaxDistance: number
) -> entries { Actor: UObject, Distance: number? }[]
```
@param `Around` - actor or vector






Filters Actors to those within MaxDistance of Around, sorted nearest-first.








### Entities.CiviliansInRange
---
```lua
function Entities.CiviliansInRange(
  Around: any,
  MaxDistance: number
) -> entries { Actor: UObject, Distance: number? }[]
```
@param `Around` - actor or vector






Civilians within MaxDistance of Around, sorted nearest-first.








### Entities.NearestCivilian
---
```lua
function Entities.NearestCivilian(
  Around: any,
  MaxDistance: number?
) -> civilian UObject?
```
@param `Around` - actor or vector






Nearest live civilian within MaxDistance (or anywhere when nil).








### Entities.NearestCrew
---
```lua
function Entities.NearestCrew(
  Around: any,
  MaxDistance: number?
) -> crewPawn UObject?
```
@param `Around` - actor or vector






Nearest live crew pawn within MaxDistance (or anywhere when nil).








### Entities.InteractableOf
---
```lua
function Entities.InteractableOf(Character: any) -> interactable UObject?
```
@param `Character` - SBZCharacter






The character's interaction target component (SBZAICharacterInteractableComponent
or SBZCharacterInteractableComponent).








### Entities.AIInteractorOf
---
```lua
function Entities.AIInteractorOf(Pawn: any) -> interactor UObject?
```
@param `Pawn` - SBZAICharacter






The pawn's AI interactor component (SBZAIInteractorComponent).








### Entities.IsSurrendered
---
```lua
function Entities.IsSurrendered(Civilian: any)
 -> validHumanShield boolean
 -> humanShieldAllowed boolean

```
@param `Civilian` - SBZCharacter


@return `validHumanShield` - bIsValidHumanShield

@return `humanShieldAllowed` - bIsHumanShieldAllowed





Surrender/shield flags of a civilian.











## fields
---

### Entities.CivilianClasses
---
```lua
Entities.CivilianClasses : string[]
```



Blueprint class short names for civilians (_C suffix required by FindAllOf).








### Entities.CrewClasses
---
```lua
Entities.CrewClasses : string[]
```



Blueprint class short names for crew AI pawns (_C suffix required by FindAllOf).









