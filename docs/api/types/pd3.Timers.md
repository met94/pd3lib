# class Timers



- namespace: pd3



Game-thread scheduling wrappers over UE4SS Execute* functions.







---

## methods
---

### Timers.InGameThread
---
```lua
function Timers.InGameThread(Fn: fun()) ->  nil
```





Runs Fn on the next game thread tick.








### Timers.After
---
```lua
function Timers.After(
  Milliseconds: integer,
  Fn: fun()
) ->  nil
```





Runs Fn on the game thread after Milliseconds have passed.








### Timers.Every
---
```lua
function Timers.Every(
  Milliseconds: integer,
  Fn: fun()
) -> handle any
```

@return `handle` - pass to Timers.Cancel





Repeats Fn every Milliseconds on the game thread.








### Timers.Cancel
---
```lua
function Timers.Cancel(Handle: any) ->  nil
```





Cancels a handle returned by Timers.Every (safe on nil/garbage handles).











