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










### Game.attributes
---
```lua
Game.attributes : pd3.Attributes {
    Layout: table<string,(string|integer)>,
    Values: function,
    Current: function,
    Base: function,
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
    DifficultyName: function,
    DifficultyIdx: function,
    SetDifficultyIdx: function,
    HeistData: function,
    HeistRef: function,
    Escape: function,
    Criterion: function,
    ...(+3)
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










### Game.weapons
---
```lua
Game.weapons : pd3.Weapons {
    DatabaseClass: string,
    RangedClass: string,
    CurveTablePath: string,
    ModificationSettingsPath: string,
    NoValue: number,
    AttributeNames: table<integer,string>,
    _Curves: { Source = string, Live = boolean, Rows = any },
    ParentFallback: table<string,string[]>,
    _Identifiers: table,
    _Parents: table,
    _UiAsset: any,
    BarReducers: table<string,string>,
    AttributeName: function,
    ...(+34)
}
```










### Game.loadout
---
```lua
Game.loadout : pd3.Loadout {
    Slots: table<string,integer>,
    SlotNames: table<integer,string>,
    FireTypes: table<integer,string>,
    LibraryPath: string,
    WidgetCandidates: { Class: string, Name: string, Package: string }[],
    ConfigWidgetCandidates: { Class: string, Name: string, Package: string }[],
    SlotButtonCandidates: { Class: string, Name: string, Package: string }[],
    StatFields: string[],
    _ScratchWidget: UObject?,
    _ScratchClass: string?,
    ActiveConfigIndex: function,
    ScratchWidget: function,
    ...(+9)
}
```










### Game.spawn
---
```lua
Game.spawn : pd3.Spawn {
    AlwaysSpawn: integer,
    TransformScale: integer,
    KismetPath: string,
    GameplayStaticsPath: string,
    YawRadians: function,
    FacingYaw: function,
    OffsetLocation: function,
    Statics: function,
    ActorFromClass: function,
    Destroy: function,
}
```










### Game.ai
---
```lua
Game.ai : pd3.AI {
    NeedsFreeze: function,
    ControllerOf: function,
    FreezePawn: function,
    IsFreezeUnsupported: function,
    FrozenCount: function,
    Reset: function,
}
```










### Game.chat
---
```lua
Game.chat : unknown
```











