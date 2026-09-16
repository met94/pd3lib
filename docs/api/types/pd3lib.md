# class pd3lib





pd3lib entry point. Require, Init, then use the pd3.* aliases.

```lua
local pd3 = require("pd3lib")
pd3.Init({ prefix = "[MyMod]", debug = false })
```







---

## methods
---

### pd3lib.Init
---
```lua
function pd3lib.Init(Options: pd3lib.InitOptions?) -> pd3 pd3lib {
    Version = integer,
    core = pd3.Core,
    game = pd3.Game,
    selftest = pd3.SelfTest,
    log = pd3.Log,
    safe = pd3.Safe,
    world = pd3.World,
    hooks = pd3.Hooks,
    timers = pd3.Timers,
    keys = pd3.Keys,
    lifecycle = pd3.Lifecycle,
    maps = pd3.Maps,
    reflect = pd3.Reflect,
    entities = pd3.Entities,
    interact = pd3.Interact,
    shield = pd3.Shield,
    challenge = pd3.Challenge,
    mission = pd3.Mission,
    Init = function,
    Unload = function,
}
```

@return `pd3` - this module, for chaining





Applies options (prefix, debug, selftest key) and logs the load line.








### pd3lib.Unload
---
```lua
function pd3lib.Unload() ->  nil
```





Unhooks everything and unbinds keys (keybind removal only when the UE4SS
build exposes UnregisterKeyBind).











## fields
---

### pd3lib.Version
---
```lua
pd3lib.Version : integer
```



library version








### pd3lib.core
---
```lua
pd3lib.core : pd3.Core {
    log: pd3.Log,
    safe: pd3.Safe,
    world: pd3.World,
    hooks: pd3.Hooks,
    timers: pd3.Timers,
    keys: pd3.Keys,
    lifecycle: pd3.Lifecycle,
    maps: pd3.Maps,
    reflect: pd3.Reflect,
}
```



module table (pd3lib.core.*)








### pd3lib.game
---
```lua
pd3lib.game : pd3.Game {
    entities: pd3.Entities,
    interact: pd3.Interact,
    shield: pd3.Shield,
    challenge: pd3.Challenge,
    mission: pd3.Mission,
}
```



module table (pd3lib.game.*)








### pd3lib.selftest
---
```lua
pd3lib.selftest : pd3.SelfTest {
    Add: function,
    Run: function,
}
```










### pd3lib.log
---
```lua
pd3lib.log : pd3.Log {
    SetPrefix: function,
    GetPrefix: function,
    SetDebug: function,
    Info: function,
    Warn: function,
    Err: function,
    Debug: function,
    Dump: function,
}
```










### pd3lib.safe
---
```lua
pd3lib.safe : pd3.Safe {
    Call: function,
    Get: function,
    Set: function,
    CallFn: function,
    IsValid: function,
    Describe: function,
    Text: function,
    Resolve: function,
    String: function,
    ArrayCount: function,
    ToFName: function,
    Count: function,
    ...(+1)
}
```










### pd3lib.world
---
```lua
pd3lib.world : pd3.World {
    GetPlayerController: function,
    GetPawn: function,
    GetPlayerState: function,
    GetWorld: function,
    GetLevelName: function,
    FindAll: function,
    FindLive: function,
    Distance: function,
    ActorsInPath: function,
    HasAuthority: function,
    Owner: function,
}
```










### pd3lib.hooks
---
```lua
pd3lib.hooks : pd3.Hooks {
    Hook: function,
    Unhook: function,
    UnhookAll: function,
    Count: function,
    LogFire: function,
    HookLogged: function,
}
```










### pd3lib.timers
---
```lua
pd3lib.timers : pd3.Timers {
    InGameThread: function,
    After: function,
    Every: function,
    Cancel: function,
}
```










### pd3lib.keys
---
```lua
pd3lib.keys : pd3.Keys {
    Bind: function,
    Count: function,
    UnbindAll: function,
}
```










### pd3lib.lifecycle
---
```lua
pd3lib.lifecycle : pd3.Lifecycle {
    OnLevelInit: function,
    OnLevelRestart: function,
    OnMissionEnd: function,
    OnReturnToMenu: function,
    Register: function,
}
```










### pd3lib.maps
---
```lua
pd3lib.maps : pd3.Maps {
    Size: function,
    Find: function,
    Contains: function,
    ForEach: function,
}
```










### pd3lib.reflect
---
```lua
pd3lib.reflect : pd3.Reflect {
    Defaults: pd3.Reflect.Options,
    SetDefaults: function,
    Format: function,
    PropertyTag: function,
    PropertiesOf: function,
    FunctionsOf: function,
    FindStruct: function,
    DumpProperties: function,
    DumpStruct: function,
    DumpClass: function,
    DumpEnum: function,
}
```










### pd3lib.entities
---
```lua
pd3lib.entities : pd3.Entities {
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










### pd3lib.interact
---
```lua
pd3lib.interact : pd3.Interact {
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










### pd3lib.shield
---
```lua
pd3lib.shield : pd3.Shield {
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










### pd3lib.challenge
---
```lua
pd3lib.challenge : pd3.Challenge {
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










### pd3lib.mission
---
```lua
pd3lib.mission : pd3.Mission {
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











