# class Lifecycle



- namespace: pd3



Level/mission lifecycle callbacks. Registration is lazy: the underlying
hooks are installed on the first registered callback.







---

## methods
---

### Lifecycle.OnLevelInit
---
```lua
function Lifecycle.OnLevelInit(Fn: fun(LevelName: string?)) ->  nil
```
@param `Fn` - level name may be nil if lookup failed






Registers a callback for playable level init.








### Lifecycle.OnLevelRestart
---
```lua
function Lifecycle.OnLevelRestart(Fn: fun()) ->  nil
```





Registers a callback for level restart (no arguments).








### Lifecycle.OnMissionEnd
---
```lua
function Lifecycle.OnMissionEnd(Fn: fun()) ->  nil
```





Registers a callback for mission end requests (no arguments).








### Lifecycle.OnReturnToMenu
---
```lua
function Lifecycle.OnReturnToMenu(Fn: fun()) ->  nil
```





Registers a callback for return-to-main-menu requests (no arguments).








### Lifecycle.Register
---
```lua
function Lifecycle.Register() ->  nil
```





Installs the four SBZ engine hooks once; repeat calls are no-ops.











