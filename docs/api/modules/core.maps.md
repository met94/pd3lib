# global core.maps








---

## methods
---

### Maps.Size
---
```lua
function Maps.Size(Map: unknown) -> size integer?
```





Entry count of a TMap, or nil when the map type does not support #.








### Maps.Find
---
```lua
function Maps.Find(
  Map: unknown,
  Key: any
) -> value any
```





Looks up Key via Map:Find; nil when missing or unsupported.








### Maps.Contains
---
```lua
function Maps.Contains(
  Map: unknown,
  Key: any
) ->  boolean
```





True when Map:Contains(Key) reports true.








### Maps.ForEach
---
```lua
function Maps.ForEach(
  Map: unknown,
  Fn: fun(Key: any, Value: any)
)
 -> ok boolean
 -> err string?

```

@return `err` - "nil map" / "ForEach unavailable" / iteration error





Iterates a TMap. Fn receives (resolvedKey, rawValueWrapper); a callback
error is logged and iteration continues. The callback must not return a
value (see class remarks).











