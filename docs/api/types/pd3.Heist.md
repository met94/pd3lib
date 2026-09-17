# class Heist



- namespace: pd3



Heist-scoped activation callbacks. `Watch` fires Enter when the live mission's
heist ref matches and Exit when leaving the heist, so mods can keep hooks and
timers idle outside their heist. Detection runs once per level init (deferred
out of hook context); there is no continuous polling.







---

## methods
---

### Heist.Watch
---
```lua
function Heist.Watch(
  Ref: string,
  Callbacks: pd3.Heist.Callbacks {
    Enter = (fun(ref: string))?,
    Exit = (fun(ref: string, reason: string))?,
}
) -> id integer?
```
@param `Ref` - heist ref token such as "penthouse"


@return `id` - pass to Heist.Unwatch; nil when arguments are invalid





Watches a heist ref and invokes callbacks when it becomes/stops being the
live mission. Detection runs on level init and once at Watch time; a level
restart fires Exit and the following level init re-arms. Mission end does
not fire Exit: the mission state stays alive until the level changes, so
watchers that unlock things on mission end keep working.








### Heist.Unwatch
---
```lua
function Heist.Unwatch(Id: integer) -> ok boolean
```

@return `ok` - false when no watcher has the id





Removes a watcher; fires its Exit when it was the active session.








### Heist.Active
---
```lua
function Heist.Active() -> ref string?
```





Heist ref currently active for this mod, or nil.








### Heist.Probe
---
```lua
function Heist.Probe() ->  nil
```





Re-runs detection on the next tick (debug/testing).











## fields
---

### Heist.ExitReasons
---
```lua
Heist.ExitReasons : table<string,string>
```



Reasons passed to Exit callbacks.









