# class Callbacks



- namespace: pd3.Heist



Callbacks for Heist.Watch.







---



## fields
---

### Callbacks.Enter
---
```lua
Callbacks.Enter : (fun(ref: string))?
```



heist ref matched; the session is now active








### Callbacks.Exit
---
```lua
Callbacks.Exit : (fun(ref: string, reason: string))?
```



session over; reason is a Heist.ExitReasons value









