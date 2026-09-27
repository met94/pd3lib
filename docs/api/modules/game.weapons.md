# global game.weapons








---

## methods
---

### Weapons.AttributeName
---
```lua
function Weapons.AttributeName(Key: any) -> name string
```





Attribute name of a TMap key (number, string or enum wrapper).








### Weapons.Databases
---
```lua
function Weapons.Databases() -> databases UObject[]
```





Weapon database assets currently loaded (Default__ CDOs excluded).








### Weapons.WeaponEntries
---
```lua
function Weapons.WeaponEntries(Database: UObject?) -> entries table[]
```
@param `Database` - defaults to all databases






Weapon entries of one database; entries are { Object, Name, Path }.








### Weapons.All
---
```lua
function Weapons.All() -> entries table[]
```





All weapons of all loaded databases.








### Weapons.Find
---
```lua
function Weapons.Find(Query: string)
 -> weapon UObject?
 -> entry table?

```





First weapon whose name or path contains Query (case-insensitive);
an exact path match wins.








### Weapons.Resolve
---
```lua
function Weapons.Resolve(Value: any) -> weapon UObject?
```





Accepts a weapon object, an entry or a query string.








### Weapons.Ensure
---
```lua
function Weapons.Ensure(Query: string) -> weapon UObject?
```





Resolve with a LoadAsset fallback for path-like queries (game thread only).








### Weapons.Subobjects
---
```lua
function Weapons.Subobjects(Weapon: any) ->  table<string,UObject?>
```





Sub-asset objects referenced by a ranged weapon.








### Weapons.Raw
---
```lua
function Weapons.Raw(Weapon: any) -> stats table?
```





Raw and hidden stats of one ranged weapon as plain numbers/booleans/tables.
Hidden values include the swap-speed notify times and play rates and the
full gun-kick numbers from the recoil asset.








### Weapons.EquippedFireDataLive
---
```lua
function Weapons.EquippedFireDataLive()
 -> fireData UObject?
 -> err string?

```





FireData of the currently equipped weapon, read from the live pawn chain
(in-heist path, unlike `Loadout.EquippedWeaponData` which goes through the
menu widgets):
  PlayerController.Pawn.CurrentEquippableConfig.EquippableData.FireData
  (fallback: .CurrentEquippable.EquippableConfig.EquippableData.FireData)
Nil (with a reason) when nothing suitable is equipped — melee/throwable
have no FireData at all. Game-thread safe (property reads only).








### Weapons.DistanceFieldCm
---
```lua
function Weapons.DistanceFieldCm(
  Obj: any,
  FieldName: string
) -> distancesCm number[]?
```





`Distance` values (cm) of an array-of-structs property. `#` is tried
first, then `GetArrayNum` (they disagree in this build); elements are
read 1-based via `el.Distance`. Nil when the array is missing/empty.








### Weapons.BreakpointsCm
---
```lua
function Weapons.BreakpointsCm(Fire: any)
 -> damageCm number[]?
 -> critCm number[]?

```





Raw damage and critical-multiplier breakpoints (cm) of a FireData object.








### Weapons.DistancesFromCm
---
```lua
function Weapons.DistancesFromCm(
  RawDamages: number[]?,
  RawCrits: number[]?
) -> meters number[]
```





Union of damage and crit breakpoints (cm) as a sorted, deduped list of
meters rounded to 2 decimals. Pure; nil-safe.








### Weapons.BreakpointsMeters
---
```lua
function Weapons.BreakpointsMeters(Fire: any) -> meters number[]
```
@param `Fire` - defaults to the equipped weapon's live FireData






Falloff breakpoints (meters) of a FireData object; with no argument it
reads the live equipped weapon (`EquippedFireDataLive`). Empty table when
unreadable, so callers can fall back to configured distances.
Caveat: AI weapon FireData often lacks the distance arrays entirely.








### Weapons.DamageAtDistance
---
```lua
function Weapons.DamageAtDistance(
  Raw: table?,
  Meters: number
) -> damage number?
```
@param `Raw` - Weapons.Raw() result






Damage at a distance in meters using the native falloff band semantics
(first DamageDistanceArray entry whose distance is >= the shot, else the
last entry).








### Weapons.CritMultiplierAtDistance
---
```lua
function Weapons.CritMultiplierAtDistance(
  Raw: table?,
  Meters: number
) -> multiplier number?
```
@param `Raw` - Weapons.Raw() result






Critical-damage multiplier at a distance in meters using the native strict
band semantics (first CriticalDamageMultiplierDistanceArray entry whose
distance is strictly greater than the shot, else the last entry).








### Weapons.Parts
---
```lua
function Weapons.Parts(Weapon: any) -> slots table[]
```





Modular slots of a weapon; entries are
{ Slot, SlotName, DefaultPart, UniqueParts, SharedParts }.
SharedParts flattens USBZSharedPartList assets into their part assets.








### Weapons.PartInfo
---
```lua
function Weapons.PartInfo(Part: any) -> info table?
```





Attribute modifiers of one weapon part asset.








### Weapons.AttributeCurves
---
```lua
function Weapons.AttributeCurves(Refresh: boolean?) -> curves table
```
@param `Refresh` - bypass the per-session cache






Attribute curve rows: { Source, Live, Rows }. Rows[name] is
{ Keys = { {Time, Value}, ... }, DefaultValue }. Prefers the live
CT_ModData_Default TMap and falls back to the generated table.








### Weapons.CurveValue
---
```lua
function Weapons.CurveValue(
  RowNameOrRow: (table|string),
  X: number,
  Curves: table?
) -> value number?
```
@param `Curves` - defaults to Weapons.AttributeCurves()






Linear interpolation over a curve row; constant extrapolation outside keys.








### Weapons.AttributeValue
---
```lua
function Weapons.AttributeValue(
  Attribute: string,
  Modifier: number
) -> value number?
```





Curve output for one attribute at a modifier value, e.g.
Weapons.AttributeValue("OverallSwapSpeed", 40).








### Weapons.AttributeIdentifiers
---
```lua
function Weapons.AttributeIdentifiers(Refresh: boolean?) -> identifiers table<string,table>
```

@return `identifiers` - name -> { Attribute, Name, Context, DisplayName, IsParent, Children }





Attribute identifiers from SBZWeaponModificationSettings.Settings
(AttributeIdentifierMap): the game's own DisplayName / Context plus the
child attributes per attribute.








### Weapons.AttributeParents
---
```lua
function Weapons.AttributeParents(Refresh: boolean?) -> parents table<string,string[]>
```





Reads the parent attribute map from SBZWeaponModificationSettings.Settings
(AttributeIdentifierMap) and merges the static fallback for missing parents.








### Weapons.ModifierMultipliers
---
```lua
function Weapons.ModifierMultipliers(
  Modifiers: table<string,number>,
  Curves: table?
)
 -> multipliers table<string,number>
 -> details table<string,table>

```
@param `Curves` - defaults to Weapons.AttributeCurves()


@return `multipliers` - child attribute -> multiplier

@return `details` - attribute -> { Children, Multipliers, Product }





Expands attribute modifiers into per-child curve multipliers. Parent
attributes (Overall*) are expanded through AttributeParents; concrete
attributes evaluate their own curve.








### Weapons.UiStatsAsset
---
```lua
function Weapons.UiStatsAsset()
 -> asset UObject?
 -> err string?

```





Loaded SBZUIWeaponStatsAsset instances. The cooked build leaves the
settings soft path unset and UE4SS crashes wrapping that TSoftObjectPtr,
so only already-loaded instances are considered (none by default).








### Weapons.UiWeights
---
```lua
function Weapons.UiWeights()
 -> weights table[]?
 -> err string?

```





Raw normalization weights of the UI stats asset; one entry per stat bar
with the MeanInputArray / VarianceInputArray / WeightHiddenArray /
BiasHiddenArray / WeightOutputArray / BiasOutputArray arrays.








### Weapons.UiStats
---
```lua
function Weapons.UiStats(Weapon: any)
 -> bars table?
 -> err string?

```

@return `bars` - { Damage = {..}, Recoil = {..}, ... }, Mode = "blueprint"





Calls the game's own SBZUIWeaponStatsBlueprint value-array getters, the
canonical 0..100 bar computation (includes hidden inputs).








### Weapons.BarRanges
---
```lua
function Weapons.BarRanges(Refresh: boolean?)
 -> ranges table<string,{ Max: number, Min: number }>
 -> samples integer

```

@return `samples` - weapons whose UI stats were readable





Min/max of each reduced bar across all loaded weapons (cached per session).








### Weapons.BarsApprox
---
```lua
function Weapons.BarsApprox(
  Weapon: any,
  Refresh: boolean?
)
 -> bars table?
 -> err string?

```

@return `bars` - { Damage = number, ..., Raw = table, Source = "approx", Samples = integer }





Approximate 0..100 bars used when the game-computed widget values are
unavailable: each raw UI array is reduced (BarReducers) and normalized
between the min and max across all loaded weapons. Deltas stay comparable
between weapons, absolute values only approximate the game's own bars.








### Weapons.Dump
---
```lua
function Weapons.Dump(
  Weapon: any,
  Opts: pd3.Reflect.Options?
) ->  nil
```





Reflection dump of the weapon and its key sub-assets.








### Weapons.Json
---
```lua
function Weapons.Json(
  Value: any,
  Indent: integer?
) -> json string
```





Encodes a plain Lua value (numbers, strings, booleans, nested tables) as JSON.








### Weapons.WriteJson
---
```lua
function Weapons.WriteJson(
  Value: any,
  Path: string
)
 -> ok boolean
 -> err string?

```





Writes Value as JSON to Path (absolute or writable relative path).











## fields
---

### Weapons.DatabaseClass
---
```lua
Weapons.DatabaseClass : string
```



Short class name of the weapon database assets.








### Weapons.RangedClass
---
```lua
Weapons.RangedClass : string
```



Short class name of ranged weapon data assets.








### Weapons.CurveTablePath
---
```lua
Weapons.CurveTablePath : string
```



Full object path of the attribute modifier curve table.








### Weapons.ModificationSettingsPath
---
```lua
Weapons.ModificationSettingsPath : string
```



CDO of the settings object holding the UI weapon stats asset path.








### Weapons.NoValue
---
```lua
Weapons.NoValue : number
```



Sentinel used by curve tables for "no default".








### Weapons.AttributeNames
---
```lua
Weapons.AttributeNames : table<integer,string>
```



ESBZWeaponAttribute value -> name (ATTRIBUTE_START..MAX range).








### Weapons._Curves
---
```lua
Weapons._Curves: table
```










### Weapons.ParentFallback
---
```lua
Weapons.ParentFallback : table<string,string[]>
```



Parent attribute -> child attributes. Used to expand attachment modifiers
such as OverallSwapSpeed into the concrete child attributes whose curves
are evaluated. Live map first (settings CDO), static fallback second.








### Weapons._Identifiers
---
```lua
Weapons._Identifiers: table
```










### Weapons._Parents
---
```lua
Weapons._Parents: table
```










### Weapons._UiAsset
---
```lua
Weapons._UiAsset : any
```










### Weapons.BarReducers
---
```lua
Weapons.BarReducers : table<string,string>
```



Reducer per stat bar used by BarsApprox: "first", "last" or "max".








### Weapons._BarRanges
---
```lua
Weapons._BarRanges: table
```










### Weapons._BarSamples
---
```lua
Weapons._BarSamples : integer
```











