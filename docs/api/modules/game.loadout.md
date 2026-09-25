# global game.loadout








---

## methods
---

### Loadout.ActiveConfigIndex
---
```lua
function Loadout.ActiveConfigIndex(
  WorldContext: UObject,
  Slot: integer
) -> index integer
```

@return `index` - 0 when unavailable





Config slot index of the active player loadout for one equippable slot.
Array elements from GetPlayerLoadouts must be resolved before field reads.








### Loadout.ScratchWidget
---
```lua
function Loadout.ScratchWidget()
 -> widget UObject?
 -> err string?

```





Creates (once) a scratch stats widget; never added to the viewport.








### Loadout.ConfigBars
---
```lua
function Loadout.ConfigBars(Config: any)
 -> result table?
 -> err string?

```
@param `Config` - FSBZEquippableConfig wrapper


@return `result` - { Stats = {...}, Ammo = {...}, FireType = {...}, Source = "game" }





Game-computed FSBZWeaponStats for any equippable config, using a scratch
stats widget. The live game UI is untouched.








### Loadout.DataBars
---
```lua
function Loadout.DataBars(EquippableData: any)
 -> result table?
 -> err string?

```





Exact bars for a weapon data asset (no attachments), via the scratch widget.








### Loadout.EquippedBars
---
```lua
function Loadout.EquippedBars(
  Slot: integer,
  Index: integer
)
 -> result table?
 -> err string?

```
@param `Slot` - ESBZEquippableLoadoutSlot

@param `Index` - config slot index from Loadout.ActiveConfigIndex






Exact bars of the equipped config at one loadout slot index, via the
scratch widget's SetBaseFromSlot (includes attachments; verified in game:
differs from the bare weapon data by the attachment effects).








### Loadout.EquippedConfig
---
```lua
function Loadout.EquippedConfig(SlotNameOrIndex: (string|integer)?)
 -> config any
 -> info table?
 -> err string?

```
@param `SlotNameOrIndex` - "PrimaryWeapon" or ESBZEquippableLoadoutSlot; default primary


@return `config` - FSBZEquippableConfig wrapper

@return `info` - { Source, Slot, SlotName, Index, EquippableData, BaseEquippableData, Widget }





Equipped config for one loadout slot: the active loadout's config slot
index (SBZLoadoutManager) fetched through SBZLoadoutLibrary, with live menu
widget fallbacks. Attachment arrays come from a live widget config when the
by-value library config carries none.








### Loadout.WidgetConfig
---
```lua
function Loadout.WidgetConfig(
  Slot: integer,
  Index: integer
)
 -> config any
 -> equippedData UObject?
 -> originalData UObject?
 -> err string?

```
@param `Slot` - ESBZEquippableLoadoutSlot

@param `Index` - config slot index from Loadout.ActiveConfigIndex


@return `equippedData` - runtime (attachment-adjusted) copy

@return `originalData` - base asset





Config from the scratch stats widget after SetBaseFromSlot: the game's own
runtime config for that loadout slot, including the ModDataMap that
by-value library returns lose. Unlike the loadout weapon slot buttons this
works independently of which menu screen is open.








### Loadout.EquippedWeaponData
---
```lua
function Loadout.EquippedWeaponData(
  Slot: integer,
  Index: integer
)
 -> equippedData UObject?
 -> originalData UObject?
 -> err string?

```
@param `Slot` - ESBZEquippableLoadoutSlot

@param `Index` - config slot index from Loadout.ActiveConfigIndex






Runtime (attachment-adjusted) weapon data of the equipped config. When the
loadout is applied the game swaps the config's EquippableData for a
transient copy under the player state; SetBaseFromSlot resolves it, and
OriginalEquippableData still points at the base asset. Reading Raw() on the
returned object yields the game-adjusted hidden stats.








### Loadout.WeaponData
---
```lua
function Loadout.WeaponData(
  Config: any,
  DataOverride: UObject?
) -> weapon table?
```
@param `DataOverride` - use this data asset instead of the config's EquippableData


@return `weapon` - { Object, Path, Name, DisplayName, IsRanged }





Weapon data asset of a config plus display metadata.








### Loadout.PrettyName
---
```lua
function Loadout.PrettyName(
  Name: string?,
  Prefix: string?
) ->  string?
```





"WPD_WAR45_Mag_Extended" + "WPD_" -> "WAR45 Mag Extended"; used when the
asset carries no localized DisplayName (the menu parts often do not).








### Loadout.ConfigParts
---
```lua
function Loadout.ConfigParts(Config: any) -> parts table[]
```





Equipped attachments of a config. ModDataMap is the primary source (slot ->
part + config); ModDataArray entries missing from the map are appended.
Every entry carries the part modifiers and the curve expansion.











## fields
---

### Loadout.Slots
---
```lua
Loadout.Slots : table<string,integer>
```



ESBZEquippableLoadoutSlot values.








### Loadout.SlotNames
---
```lua
Loadout.SlotNames : table<integer,string>
```



Slot index -> short name.








### Loadout.FireTypes
---
```lua
Loadout.FireTypes : table<integer,string>
```



ESBZFireType value -> name.








### Loadout.LibraryPath
---
```lua
Loadout.LibraryPath : string
```



CDO of the loadout function library.








### Loadout.WidgetCandidates
---
```lua
Loadout.WidgetCandidates : { Class: string, Name: string, Package: string }[]
```



Main-menu stats widget candidates (short class name -> package/class path).








### Loadout.ConfigWidgetCandidates
---
```lua
Loadout.ConfigWidgetCandidates : { Class: string, Name: string, Package: string }[]
```



Menu widgets that hold FSBZEquippableConfig as a live property; used when
the loadout library config carries no attachment arrays.








### Loadout.SlotButtonCandidates
---
```lua
Loadout.SlotButtonCandidates : { Class: string, Name: string, Package: string }[]
```



Loadout weapon slot buttons; their `WeaponSlot` struct is the reliable
source of the equipped ModDataMap (verified in game: the by-value library
config and ModDataArray lose the attachment arrays, the live button does
not).








### Loadout.StatFields
---
```lua
Loadout.StatFields : string[]
```



Stat field order of FSBZWeaponStats.








### Loadout._ScratchWidget
---
```lua
Loadout._ScratchWidget : UObject?
```










### Loadout._ScratchClass
---
```lua
Loadout._ScratchClass : string?
```











