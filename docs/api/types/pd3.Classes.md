# class Classes



- namespace: pd3



Class resolution with ordered fallbacks and an incremental, non-fatal load
queue. Blueprint classes are commonly not loaded yet when a mod looks for
them, and a single bad path must never abort a roster: callers enqueue
paths, call `loader:Step()` once per tick (budget 1-2), retry on later
ticks and treat `false` as permanently gave up.

A resolved class that died with a previous level is reported as unresolved
again by `Get` (and dropped from the cache), so callers re-enqueue and
`Step` re-resolves it against the new level. `Reset` clears everything at
once for level transitions.

Resolution variants, in order:
  1. `LoadAsset(object path)`  2. `StaticFindObject(object path)`
  3. `LoadAsset(package path)` 4. `StaticFindObject(package path)`
Blueprint assets unwrap to their `GeneratedClass`.







---

## methods
---

### Classes.Variants
---
```lua
function Classes.Variants(Path: string) -> variants { Arg: string, Kind: ("LoadAsset"|"FindObject"), Label: string }[]
```





Ordered resolution variants for one object path. Paths without a dot have a
single unique argument, so only the two kinds remain.








### Classes.ClassFromObject
---
```lua
function Classes.ClassFromObject(Obj: any) -> class UObject?
```





Resolves a raw object to a UClass: class objects pass through, Blueprint
assets unwrap to their GeneratedClass, everything else is rejected.








### Classes.Ensure
---
```lua
function Classes.Ensure(Path: string)
 -> class UObject?
 -> variant string?

```

@return `variant` - label of the variant that succeeded





Resolves one class path through all variants (single shot, no retry).
`LoadAsset` only works on the game thread.








### Classes.NewLoader
---
```lua
function Classes.NewLoader(Opts: { BudgetPerTick: integer?, MaxAttempts: integer?, Resolve: (fun(path: string) -> multi<...>)? }?) -> loader pd3.Classes.Loader {
    BudgetPerTick = integer,
    MaxAttempts = integer,
}
```





Creates a loader. `Opts.Resolve(path)` may be injected for tests; it must
return a class object or nil. The default resolver runs `Classes.Ensure`
(game thread only).











