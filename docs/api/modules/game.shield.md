# global game.shield








---

## methods
---

### Shield.StateName
---
```lua
function Shield.StateName(Value: any) -> name string
```

@return `name` - "Unknown(n)" when unmapped





Name for an ESBZHumanShieldInstigatorState value.








### Shield.InstigatorState
---
```lua
function Shield.InstigatorState(Pawn: any) -> state integer?
```
@param `Pawn` - SBZCharacter






The pawn's HumanShieldInstigatorState (3 Grabbing / 4 Choking when held).








### Shield.VictimFlags
---
```lua
function Shield.VictimFlags(Victim: any) -> flags { Allowed: boolean?, Valid: boolean? }
```
@param `Victim` - SBZCharacter






Surrender/shield flags of a potential victim.








### Shield.Grab
---
```lua
function Shield.Grab(
  Pawn: any,
  Victim: any,
  CompleteDelayMs: integer?
) -> ok boolean
```
@param `Pawn` - player pawn (SBZPlayerCharacter)

@param `Victim` - civilian SBZCharacter

@param `CompleteDelayMs` - default 500


@return `ok` - false when refs are invalid





Grabs a surrendered civilian as a human shield via the interaction system.
Uses the interactor's current InteractId/ModeIndex and completes after
CompleteDelayMs (default 500). Grab leads to state 3 (Grabbing) within ~1-2s.








### Shield.Release
---
```lua
function Shield.Release() -> cancelled integer
```

@return `cancelled` - number of ability instances cancelled





Releases the human shield by cancelling live GA_HumanShieldInstigator_C
instances (Default__ CDOs are skipped).











## fields
---

### Shield.AIInstigatorUnsupported
---
```lua
Shield.AIInstigatorUnsupported : boolean
```



True: AI-driven human shields crash the game. Do not trigger them.








### Shield.InstigatorStates
---
```lua
Shield.InstigatorStates : table<integer,string>
```



ESBZHumanShieldInstigatorState index -> name.








### Shield.AbilityClassName
---
```lua
Shield.AbilityClassName : string
```



Blueprint class name of the instigator ability.









