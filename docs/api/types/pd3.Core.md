# class Core



- namespace: pd3



Generic UE4SS/UE helper modules.







---



## fields
---

### Core.log
---
```lua
Core.log : pd3.Log {
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










### Core.safe
---
```lua
Core.safe : pd3.Safe {
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










### Core.world
---
```lua
Core.world : pd3.World {
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










### Core.hooks
---
```lua
Core.hooks : pd3.Hooks {
    Hook: function,
    Unhook: function,
    UnhookAll: function,
    Count: function,
    LogFire: function,
    HookLogged: function,
}
```










### Core.timers
---
```lua
Core.timers : pd3.Timers {
    InGameThread: function,
    After: function,
    Every: function,
    Cancel: function,
}
```










### Core.keys
---
```lua
Core.keys : pd3.Keys {
    Bind: function,
    Count: function,
    UnbindAll: function,
}
```










### Core.lifecycle
---
```lua
Core.lifecycle : pd3.Lifecycle {
    OnLevelInit: function,
    OnLevelRestart: function,
    OnMissionEnd: function,
    OnReturnToMenu: function,
    Register: function,
}
```










### Core.maps
---
```lua
Core.maps : pd3.Maps {
    Size: function,
    Find: function,
    Contains: function,
    ForEach: function,
}
```










### Core.reflect
---
```lua
Core.reflect : pd3.Reflect {
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











