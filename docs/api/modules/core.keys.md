# global core.keys








---

## methods
---

### Keys.Bind
---
```lua
function Keys.Bind(
  KeyCode: integer,
  Fn: fun(),
  Description: string?
) -> ok boolean
```
@param `KeyCode` - Key.* constant, e.g. Key.F5

@param `Fn` - invoked by UE4SS on the input thread

@param `Description` - used in log lines only


@return `ok` - false when RegisterKeyBind raised





Binds KeyCode to Fn and tracks the binding for UnbindAll.








### Keys.Count
---
```lua
function Keys.Count() ->  integer
```





Number of tracked bindings.








### Keys.UnbindAll
---
```lua
function Keys.UnbindAll() -> ok boolean
```

@return `ok` - false when UnregisterKeyBind is unavailable (bindings stay active)





Unregisters every tracked binding when UE4SS exposes UnregisterKeyBind.











