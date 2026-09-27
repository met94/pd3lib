# global core.classes








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











