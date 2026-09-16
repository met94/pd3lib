# global game.mission








---

## methods
---

### Mission.Get
---
```lua
function Mission.Get()
 -> state UObject?
 -> fullName string?

```





Live SBZMissionState (nil in menus).








### Mission.Difficulty
---
```lua
function Mission.Difficulty(State: UObject?)
 -> value integer?
 -> name string?

```
@param `State` - defaults to Mission.Get()


@return `value` - ESBZDifficulty

@return `name` - "Unknown(n)" when unmapped





Mission difficulty value and display name.








### Mission.HeistData
---
```lua
function Mission.HeistData(State: UObject?) -> heistData UObject?
```
@param `State` - defaults to Mission.Get()






The mission's CurrentHeistData object.








### Mission.HeistRef
---
```lua
function Mission.HeistRef(State: UObject?) -> heistRef string?
```
@param `State` - defaults to Mission.Get()






Heist reference is a short token such as "penthouse"; the level name
("Sky") is different and comes from core.world.GetLevelName. Gate on this.








### Mission.Escape
---
```lua
function Mission.Escape(State: UObject?) -> escape pd3.Mission.Escape {
    TimeLeft = number,
    PlayersIn = number,
    PlayersRequired = number,
}
```
@param `State` - defaults to Mission.Get()






Current escape state (zeros outside an escape).








### Mission.Criterion
---
```lua
function Mission.Criterion(CriteriaName: string) -> criterion UObject?
```

@return `criterion` - SBZStatisticCriteriaData





Reads one entry of SBZMissionState.StatisticsCriteriaDataCollection,
e.g. Mission.Criterion("InsurancePolicy"). Returns nil outside a mission.








### Mission.DumpCriterion
---
```lua
function Mission.DumpCriterion(
  Criteria: any,
  Opts: pd3.Reflect.Options?
) ->  nil
```
@param `Criteria` - SBZStatisticCriteriaData; nil is a no-op






Reflection dumps for update-proof re-discovery.








### Mission.DumpHeistData
---
```lua
function Mission.DumpHeistData(
  HeistData: any,
  Opts: pd3.Reflect.Options?
) ->  nil
```
@param `HeistData` - nil is a no-op






Dumps a heist data object's reflected properties.








### Mission.DumpMissionResult
---
```lua
function Mission.DumpMissionResult(
  State: UObject?,
  Opts: pd3.Reflect.Options?
) ->  nil
```
@param `State` - defaults to Mission.Get()






Dumps the mission's CurrentMissionResultData (SBZEndMissionResultData).











## fields
---

### Mission.ClassName
---
```lua
Mission.ClassName : string
```



Short class name of the live mission state object.








### Mission.DifficultyNames
---
```lua
Mission.DifficultyNames : table<integer,string>
```



ESBZDifficulty index -> name.








### Mission.HeistStateNames
---
```lua
Mission.HeistStateNames : table<integer,string>
```



PD3 heist state index -> name.









