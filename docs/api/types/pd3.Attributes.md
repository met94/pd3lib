# class Attributes



- namespace: pd3



Live GAS attribute values (FGameplayAttributeData members) from attribute
sets. All reads are reflection-driven, so missing fields resolve to nil
instead of raising; plain numeric properties on the same set are returned
as the current (and base) value.

Raw-memory reference for debugger work (verified on build 5.5.4, UE 5.5):
FGameplayAttributeData is 16 bytes with an 8-byte base, BaseValue at +8 and
CurrentValue at +12. Re-verify Attributes.Layout after every game update;
the reflection reads below do not depend on it.







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









