# global core.hooks








---

## methods
---

### Hooks.Hook
---
```lua
function Hooks.Hook(
  Path: string,
  Callback: fun(Context: any, ...) -> any
) -> preId integer?
```
@param `Path` - full UFunction path, e.g. "/Script/Starbreeze.SBZCharacter:Multicast_...:"

@param `Callback` - Context is the owning object; args are wrappers


@return `preId` - hook id for Hooks.Unhook; nil when registration failed





Registers a pre-hook on Path and tracks it for Unhook/UnhookAll.








### Hooks.Unhook
---
```lua
function Hooks.Unhook(
  Path: string,
  PreId: integer
) -> ok boolean
```

@return `ok` - false when no matching entry exists





Unregisters the tracked hook matching Path + preId.








### Hooks.UnhookAll
---
```lua
function Hooks.UnhookAll() ->  nil
```





Unregisters every tracked hook.








### Hooks.Count
---
```lua
function Hooks.Count() ->  integer
```





Number of tracked hooks.








### Hooks.LogFire
---
```lua
function Hooks.LogFire(
  Path: string,
  Context: any,
  ...: any
) ->  nil
```
@param `...` - hook arguments (wrappers)






Logs a formatted hook fire line (context + described args).








### Hooks.HookLogged
---
```lua
function Hooks.HookLogged(
  Path: string,
  Callback: (fun(Context: any, ...) -> any)?
) -> preId integer?
```
@param `Callback` - nil = log only






Hook + LogFire on every invocation, then forwards to Callback.











