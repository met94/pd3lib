# global game.attributes








---

## methods
---

### Attributes.Values
---
```lua
function Attributes.Values(
  AttributeSet: any,
  Field: string
)
 -> current number?
 -> base number?

```
@param `AttributeSet` - attribute set object

@param `Field` - property name, e.g. "Health" or "Armor"






Current and base value of one attribute-set field.
FGameplayAttributeData members resolve to their `CurrentValue` / `BaseValue`;
plain numeric properties return the number for both; missing fields return nil.








### Attributes.Current
---
```lua
function Attributes.Current(
  AttributeSet: any,
  Field: string
) -> current number?
```





Current value only (nil when the field is missing or unreadable).








### Attributes.Base
---
```lua
function Attributes.Base(
  AttributeSet: any,
  Field: string
) -> base number?
```





Base value only (nil when the field is missing or unreadable).











## fields
---

### Attributes.Layout
---
```lua
Attributes.Layout : table<string,(string|integer)>
```



FGameplayAttributeData layout constant used by raw-memory tooling.









