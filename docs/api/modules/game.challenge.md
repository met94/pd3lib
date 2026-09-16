# global game.challenge








---

## methods
---

### Challenge.Manager
---
```lua
function Challenge.Manager()
 -> challengeManager UObject?
 -> fullName string?

```





Live BP_ChallengeManager_C instance.








### Challenge.AchievementManager
---
```lua
function Challenge.AchievementManager()
 -> achievementManager UObject?
 -> fullName string?

```





Live SBZAchievementManager instance.








### Challenge.StatusName
---
```lua
function Challenge.StatusName(Value: any) -> name string
```
@param `Value` - non-numbers are tostring'ed as-is


@return `name` - "Unknown(n)" when unmapped





Name for an ESBZChallengeStatus value.








### Challenge.Achievements
---
```lua
function Challenge.Achievements(Manager: UObject?) -> map unknown
```
@param `Manager` - defaults to Challenge.Manager()






The AchievementMap (TMap<FName, FSBZChallengeData>) of a manager.








### Challenge.AllChallenges
---
```lua
function Challenge.AllChallenges(Manager: UObject?) -> map unknown
```
@param `Manager` - defaults to Challenge.Manager()






The ChallengeMap (TMap<FName, FSBZChallengeData>) of a manager.








### Challenge.RecordSummary
---
```lua
function Challenge.RecordSummary(
  Key: any,
  Value: any
) -> summary pd3.Challenge.RecordSummary {
    Key = string,
    ChallengeId = string,
    ChallengeName = string,
    Status = any,
    TotalProgress = any,
    TotalTarget = any,
    Record = any,
}
```
@param `Key` - map key wrapper

@param `Value` - FSBZChallengeData struct value













### Challenge.Find
---
```lua
function Challenge.Find(
  Manager: UObject?,
  Needle: string
) -> found pd3.Challenge.RecordSummary[]
```
@param `Manager` - defaults to Challenge.Manager()






Returns a list of summaries whose id/name/key contains Needle (case-insensitive).








### Challenge.IsCompleted
---
```lua
function Challenge.IsCompleted(
  Manager: UObject?,
  Needle: string
)
 -> completed boolean
 -> summary pd3.Challenge.RecordSummary?

```
@param `Manager` - defaults to Challenge.Manager()


@return `summary` - the completed entry





True when any entry matching Needle has status COMPLETED(2).








### Challenge.CodeFor
---
```lua
function Challenge.CodeFor(ChallengeName: string) -> code string?
```





Challenge FName -> AccelByte code (e.g. "ACH_*") via the settings CDO property.
Reading the property is safe; SBZChallengeToAchievementSettings:
GetChallengeToAchievementSettings() returns a TMap by value and holding that
copy is suspect (see docs: by-value returns). Match is case-insensitive.








### Challenge.Complete
---
```lua
function Challenge.Complete(AchievementId: any)
 -> ok boolean
 -> err any

```
@param `AchievementId` - string or pre-built FName


@return `err` - error detail when ok=false ("no achievement manager", "fname not in pool")





Calls the game's own completion path: SBZAchievementManager:CompleteAchievement.
AchievementId is typically the AchievementMap key (hashed FName), an
AccelByte code such as ACH_*, or a challenge name. Lua strings are
pre-converted with Safe.ToFName because this UE4SS build crashes argument
marshalling for Lua string -> FName.








### Challenge.DumpRecord
---
```lua
function Challenge.DumpRecord(
  Label: string,
  Record: any
) ->  nil
```
@param `Record` - FSBZChallengeData value (wrapper or table)






Logs a one-line summary of an FSBZChallengeData record (map value).








### Challenge.DumpStatMap
---
```lua
function Challenge.DumpStatMap(
  Manager: UObject?,
  MaxEntries: integer?,
  Opts: pd3.Reflect.Options?
) ->  nil
```
@param `Manager` - defaults to Challenge.Manager()

@param `MaxEntries` - default 25

@param `Opts` - forwarded to Reflect.DumpStruct






Dumps the current stat map (registered internal stats) using reflection.








### Challenge.DumpCaches
---
```lua
function Challenge.DumpCaches(Manager: UObject?) ->  nil
```
@param `Manager` - defaults to Challenge.Manager()






ChallengeRecordCaches wraps as an opaque TrivialObject on this build; this
reports what is readable instead of failing.











## fields
---

### Challenge.ManagerClassName
---
```lua
Challenge.ManagerClassName : string
```



Short class name of the challenge manager subclass.








### Challenge.AchievementManagerClassName
---
```lua
Challenge.AchievementManagerClassName : string
```



Short class name of the achievement manager.








### Challenge.SettingsClassPath
---
```lua
Challenge.SettingsClassPath : string
```



CDO path of the challenge -> achievement settings object.








### Challenge.StatusNames
---
```lua
Challenge.StatusNames : table<integer,string>
```



ESBZChallengeStatus index -> name.








### Challenge.CompletedStatus
---
```lua
Challenge.CompletedStatus : integer
```



ChallengeStatus value meaning COMPLETED.









