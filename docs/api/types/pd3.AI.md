# class AI



- namespace: pd3



AI controller helpers. `FreezePawn` disables AI via
`SBZAIController:SetAIEnabled(false, FName)` — proven to stop both movement
and shooting instantly (CrewLab) — with dedupe so a per-tick guard does not
re-call it, and a per-class unsupported cache for controllers that have no
`SetAIEnabled` (e.g. the Moon drone).

HARD RULE: never register a UE4SS hook on `SetAIEnabled` in a mod that
calls it. Calling a hooked UFunction from Lua re-enters the hook and crashes
(`push_nameproperty`); observation-only hooks on that function are safe, the
call is not.







---

## methods
---

### AI.NeedsFreeze
---
```lua
function AI.NeedsFreeze(
  LastReason: string?,
  Reason: string?
) -> needsFreeze boolean
```





True when the controller's last disabled reason differs from ours (ours
was overridden by the game and should be re-applied).








### AI.ControllerOf
---
```lua
function AI.ControllerOf(Pawn: any) -> controller UObject?
```





Controller of a pawn: the `Controller` property first, `GetController()`
second. Nil when neither resolves to a valid object.








### AI.FreezePawn
---
```lua
function AI.FreezePawn(
  Pawn: any,
  Reason: string?
)
 -> ok boolean
 -> detail string

```
@param `Reason` - FName text; must exist in the name pool (default "pd3lib")






Disables AI on a pawn's controller, once. Returns true when the controller
is (or was already) frozen, false when it has no usable `SetAIEnabled`
(logged once per controller class).

Reading `LastDisabledReason` drives the dedupe:
  * unreadable -> the in-memory frozen cache is used
  * equal to Reason -> no call
  * different -> re-apply (the game or another mod changed it)








### AI.IsFreezeUnsupported
---
```lua
function AI.IsFreezeUnsupported(Pawn: any) -> unsupported boolean
```





True when the pawn's controller class previously failed to freeze.








### AI.FrozenCount
---
```lua
function AI.FrozenCount() -> count integer
```





Number of controllers frozen through this module (weak-keyed cache).








### AI.Reset
---
```lua
function AI.Reset() ->  nil
```





Clears the frozen and unsupported caches (call on level change / restart).











