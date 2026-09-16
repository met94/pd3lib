# class RecordSummary



- namespace: pd3.Challenge



Flattened view of one FSBZChallengeData map entry. Record fields are plain
struct copies; string wrappers are resolved.







---



## fields
---

### RecordSummary.Key
---
```lua
RecordSummary.Key : string
```



map key (hashed FName, resolved)








### RecordSummary.ChallengeId
---
```lua
RecordSummary.ChallengeId : string
```










### RecordSummary.ChallengeName
---
```lua
RecordSummary.ChallengeName : string
```



human-readable, e.g. "Achievement Steam Penthouse Human Shield Extract"








### RecordSummary.Status
---
```lua
RecordSummary.Status : any
```



ESBZChallengeStatus value (number wrapper until read via StatusName)








### RecordSummary.TotalProgress
---
```lua
RecordSummary.TotalProgress : any
```










### RecordSummary.TotalTarget
---
```lua
RecordSummary.TotalTarget : any
```










### RecordSummary.Record
---
```lua
RecordSummary.Record : any
```



the raw FSBZChallengeData value









