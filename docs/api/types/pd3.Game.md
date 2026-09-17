# class Game



- namespace: pd3



Payday 3 specific modules.







---



## fields
---

### Game.entities
---
```lua
Game.entities : pd3.Entities {
    CivilianClasses: string[],
    CrewClasses: string[],
    FindByClasses: function,
    Civilians: function,
    CrewPawns: function,
    InRange: function,
    CiviliansInRange: function,
    NearestCivilian: function,
    NearestCrew: function,
    InteractableOf: function,
    AIInteractorOf: function,
    IsSurrendered: function,
    ...(+0)
}
```










### Game.interact
---
```lua
Game.interact : pd3.Interact {
    Modes: table<integer,string>,
    Actions: table<integer,string>,
    HookPaths: table<string,string>,
    ModeName: function,
    ActionName: function,
    PlayerInteractor: function,
    Start: function,
    Complete: function,
    Stop: function,
    StartWithComplete: function,
    State: function,
    EnableDiscoveryLogging: function,
    ...(+0)
}
```










### Game.shield
---
```lua
Game.shield : pd3.Shield {
    AIInstigatorUnsupported: boolean,
    InstigatorStates: table<integer,string>,
    AbilityClassName: string,
    StateName: function,
    InstigatorState: function,
    VictimFlags: function,
    Grab: function,
    Release: function,
}
```










### Game.challenge
---
```lua
Game.challenge : pd3.Challenge {
    ManagerClassName: string,
    AchievementManagerClassName: string,
    SettingsClassPath: string,
    StatusNames: table<integer,string>,
    CompletedStatus: integer,
    Manager: function,
    AchievementManager: function,
    StatusName: function,
    Achievements: function,
    AllChallenges: function,
    RecordSummary: function,
    Find: function,
    ...(+6)
}
```










### Game.mission
---
```lua
Game.mission : pd3.Mission {
    ClassName: string,
    DifficultyNames: table<integer,string>,
    HeistStateNames: table<integer,string>,
    Get: function,
    Difficulty: function,
    HeistData: function,
    HeistRef: function,
    Escape: function,
    Criterion: function,
    DumpCriterion: function,
    DumpHeistData: function,
    DumpMissionResult: function,
    ...(+0)
}
```










### Game.heist
---
```lua
Game.heist : pd3.Heist {
    ExitReasons: table<string,string>,
    Watch: function,
    Unwatch: function,
    Active: function,
    Probe: function,
}
```











