# global core.safe








---

## methods
---

### Safe.Call
---
```lua
function Safe.Call(
  Fn: fun(...) -> unknown,
  ...: any
)
 -> ok boolean
 ->  any ...

```
@param `...` - forwarded to Fn


@return `ok` - false when Fn raised

@return  - Fn's return values, or the error message when ok=false





Calls Fn in protected mode.








### Safe.Get
---
```lua
function Safe.Get(
  Obj: any,
  Name: string
) -> value any
```





Reads Obj[Name], returning nil on error.








### Safe.Set
---
```lua
function Safe.Set(
  Obj: any,
  Name: string,
  Value: any
)
 -> ok boolean
 -> err string?

```

@return `err` - only when Obj is nil or the write raised





Writes Obj[Name] = Value in protected mode.








### Safe.CallFn
---
```lua
function Safe.CallFn(
  Obj: any,
  Name: string,
  ...: any
)
 -> ok boolean
 ->  any ...

```
@param `...` - forwarded to the method


@return  - method return values





Calls Obj:Name(...) in protected mode.








### Safe.IsValid
---
```lua
function Safe.IsValid(Value: any) ->  boolean
```





Returns true only when Value is a valid UObject.








### Safe.Describe
---
```lua
function Safe.Describe(Value: any) ->  string
```





Human-readable description: "FullName [Class]" for objects, tostring otherwise.
Unwraps hook :get() wrappers; never invokes object methods on unknown
wrappers (calling e.g. GetFullName on a name/param wrapper crashes UE4SS).








### Safe.Text
---
```lua
function Safe.Text(Value: any) ->  string
```





FText -> Lua string via :ToString(), falling back to KismetTextLibrary
Conv_TextToString and finally Safe.Describe.








### Safe.Resolve
---
```lua
function Safe.Resolve(
  Value: any,
  Depth: integer?
) -> resolved any
```
@param `Depth` - internal recursion guard, max 3; omit when calling






Unwraps UE4SS value wrappers to the underlying value:
  * RemoteUnrealParam / LocalUnrealParam -> :get()
  * FString / FName / FText / FGuid     -> :ToString() (Lua string)
  * UObject derivatives and unknown wrappers pass through unchanged
Never invokes object methods on unknown wrappers: calling e.g. GetFullName
on a name/param wrapper crashes UE4SS marshalling (push_nameproperty).








### Safe.String
---
```lua
function Safe.String(Value: any) ->  string
```





Resolve then tostring for primitives; Safe.Describe fallback. Never nil.








### Safe.ArrayCount
---
```lua
function Safe.ArrayCount(Value: any) -> count integer?
```





Element count of array-like values. Arrays of structs may come back as
opaque "TrivialObject" wrappers that support neither # nor GetArrayNum;
callers must handle nil.








### Safe.ToFName
---
```lua
function Safe.ToFName(Text: string?)
 -> name FName?
 -> index integer?

```
@param `Text` - must already exist in the global name pool


@return `index` - comparison index, 0 means "not in pool"





Pre-builds an FName from a Lua string. This UE4SS build crashed argument
marshalling (push_nameproperty) when Lua strings were passed where FName
parameters were expected; pass the FName userdata returned here instead.








### Safe.Count
---
```lua
function Safe.Count(
  Obj: any,
  Name: string
) -> count integer?
```





Counts elements of Obj[Name] with #, returning nil on error.








### Safe.Num
---
```lua
function Safe.Num(
  Value: any,
  Default: any
) ->  any
```





Returns Value when it is a number, Default otherwise.











