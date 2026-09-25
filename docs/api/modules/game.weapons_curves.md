# global game.weapons_curves








---



## fields
---

### CurvesData.Source
---
```lua
CurvesData.Source: string = "/Game/Gameplay/Weapons/CT_ModData_Default.CT_ModData_Default"
```



Full object path of the live curve table.








### CurvesData.Rows
---
```lua
CurvesData.Rows : table<string,{ DefaultValue: number, Keys: number[][] }>
```



Row name -> { Keys = { {Time, Value}, ... }, DefaultValue = number }.
X is the attribute modifier value (part AttributeModifierMap / skills),
Y the multiplier or delta the game applies to the weapon base value.









