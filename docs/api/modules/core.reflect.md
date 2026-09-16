# global core.reflect








---

## methods
---

### Reflect.SetDefaults
---
```lua
function Reflect.SetDefaults(Overrides: pd3.Reflect.Options?) ->  nil
```





Merges Overrides into Reflect.Defaults (shallow; Skip is replaced whole).








### Reflect.Format
---
```lua
function Reflect.Format(
  Value: any,
  Options: pd3.Reflect.Options {
    MaxDepth = integer?,
    MaxArray = integer?,
    MaxString = integer?,
    MaxLines = integer?,
    Filter = string?,
    Skip = table<string,boolean>?,
},
  Depth: integer?,
  Property: UObject?
) ->  string
```
@param `Depth` - recursion budget; <= 0 stops struct/array expansion

@param `Property` - FProperty carrying the struct/array schema













### Reflect.PropertyTag
---
```lua
function Reflect.PropertyTag(Property: UObject?) -> tag string
```
@param `Property` - FProperty


@return `tag` - "Property" when the class is unknown, "?" when nil












### Reflect.PropertiesOf
---
```lua
function Reflect.PropertiesOf(Target: any) -> properties UObject[]
```





All FProperty objects of a UObject, UScriptStruct or UScriptClass
(anything exposing ForEachProperty or GetClass).








### Reflect.FunctionsOf
---
```lua
function Reflect.FunctionsOf(Struct: any) -> functionNames string[]
```
@param `Struct` - UScriptStruct/UScriptClass






Names of all UFunctions of a UScriptStruct/UScriptClass.








### Reflect.FindStruct
---
```lua
function Reflect.FindStruct(NameOrPath: any) -> schema UObject?
```
@param `NameOrPath` - struct name, full path, or an existing object






Resolves a UScriptStruct by name or path. Non-string arguments pass through.
Struct names drop the F prefix: "FSBZChallengeData" -> "SBZChallengeData".








### Reflect.DumpProperties
---
```lua
function Reflect.DumpProperties(
  Target: any,
  Opts: pd3.Reflect.Options?
) -> lines string[]
```
@param `Target` - live UObject; nil yields a single "<nil target>" line

@param `Opts` - per-call overrides; opts.Filter = name substring


@return `lines` - lines are also logged via pd3.log.Info





Dumps all reflected properties of a live UObject with values and type tags.








### Reflect.DumpStruct
---
```lua
function Reflect.DumpStruct(
  Value: any,
  Struct: any,
  Opts: pd3.Reflect.Options?
) -> lines string[]
```
@param `Value` - struct value; nil yields a single "<nil value>" line

@param `Struct` - name ("SBZChallengeData"), path, or UScriptStruct object


@return `lines` - lines are also logged via pd3.log.Info





Dumps a struct value (wrapper or table) using reflection from its UScriptStruct.








### Reflect.DumpClass
---
```lua
function Reflect.DumpClass(
  NameOrPath: any,
  Opts: pd3.Reflect.Options?
) -> lines string[]
```
@param `NameOrPath` - live object/class, class short name, or full object path


@return `lines` - lines are also logged via pd3.log.Info





Dumps a class/struct: property list then function list.








### Reflect.DumpEnum
---
```lua
function Reflect.DumpEnum(
  EnumOrName: any,
  Opts: pd3.Reflect.Options?
) -> lines string[]
```
@param `EnumOrName` - enum name (tried under /Script/Starbreeze first), path, or UEnum object


@return `lines` - lines are also logged via pd3.log.Info





Dumps an enum's names and values.











## fields
---

### Reflect.Defaults
---
```lua
Reflect.Defaults : pd3.Reflect.Options {
    MaxDepth: integer?,
    MaxArray: integer?,
    MaxString: integer?,
    MaxLines: integer?,
    Filter: string?,
    Skip: table<string,boolean>?,
}
```



global defaults used when a call passes no Opts









