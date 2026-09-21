--- Equipped weapon loadout helpers: the actually equipped weapon config
--- (SBZLoadoutLibrary), its equipped attachments (FSBZEquippableConfig) and the
--- game-computed stat bars via a scratch SBZMainMenuWeaponStatsWidget instance.
---
--- The scratch widget is never added to the viewport; live game widgets are
--- only read, never mutated. Every engine call is pcall-guarded and failures
--- are reported through Safe.Verbose instead of raising.
---@class pd3.Loadout
local Loadout = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Maps = require("pd3lib.core.maps")
local Log = require("pd3lib.core.log")
local Weapons = require("pd3lib.game.weapons")

local Unpack = table.unpack or unpack

--- pcall wrapper that never hides the failure (logged when Safe.Verbose).
---@param What string
---@param Fn fun(...): ...
---@param ... any
---@return boolean ok
---@return any ...
local function Pcall(What, Fn, ...)
    local Results = { pcall(Fn, ...) }
    local Ok = table.remove(Results, 1)
    if not Ok and Safe.Verbose then
        Log.Debug("loadout: %s failed: %s", What, tostring(Results[1]))
    end
    return Ok, Unpack(Results)
end

--- ESBZEquippableLoadoutSlot values.
---@type table<string, integer>
Loadout.Slots = { PrimaryWeapon = 0, SecondaryWeapon = 1, OverkillWeapon = 2 }

--- Slot index -> short name.
---@type table<integer, string>
Loadout.SlotNames = { [0] = "Primary", [1] = "Secondary", [2] = "Overkill" }

--- ESBZFireType value -> name.
---@type table<integer, string>
Loadout.FireTypes = { [0] = "Semi", [1] = "Burst", [2] = "Auto", [3] = "Pump", [4] = "Bolt" }

--- CDO of the loadout function library.
---@type string
Loadout.LibraryPath = "/Script/Starbreeze.Default__SBZLoadoutLibrary"

--- Main-menu stats widget candidates (short class name -> package/class path).
---@type { Name: string, Package: string, Class: string }[]
Loadout.WidgetCandidates = {
    {
        Name = "WBP_UI_Widget_WeaponStats_C",
        Package = "/Game/UI/Widgets/Menus/Generic/WBP_UI_Widget_WeaponStats",
        Class = "/Game/UI/Widgets/Menus/Generic/WBP_UI_Widget_WeaponStats.WBP_UI_Widget_WeaponStats_C",
    },
    {
        Name = "WBP_WeaponStatsNew_C",
        Package = "/Game/DLCs/00223-PATCH3_5/UI/WBP_WeaponStatsNew",
        Class = "/Game/DLCs/00223-PATCH3_5/UI/WBP_WeaponStatsNew.WBP_WeaponStatsNew_C",
    },
}

--- Menu widgets that hold FSBZEquippableConfig as a live property; used when
--- the loadout library config carries no attachment arrays.
---@type { Name: string, Package: string, Class: string }[]
Loadout.ConfigWidgetCandidates = {
    {
        Name = "WBP_MainMenu_Loadout_WeaponCustomizationNew_C",
        Package = "/Game/UI/Widgets/StateMachine/Loadout/WeaponCustomization/WBP_MainMenu_Loadout_WeaponCustomizationNew",
        Class = "/Game/UI/Widgets/StateMachine/Loadout/WeaponCustomization/WBP_MainMenu_Loadout_WeaponCustomizationNew.WBP_MainMenu_Loadout_WeaponCustomizationNew_C",
    },
    {
        Name = "WBP_UI_WeaponModiferScreen_C",
        Package = "/Game/UI/Widgets/StateMachine/Inventory/WBP_UI_WeaponModiferScreen",
        Class = "/Game/UI/Widgets/StateMachine/Inventory/WBP_UI_WeaponModiferScreen.WBP_UI_WeaponModiferScreen_C",
    },
    {
        Name = "WBP_UI_LoadoutCustomization_WeaponSlotButton_C",
        Package = "/Game/UI/Widgets/StateMachine/Loadout/WBP_UI_LoadoutCustomization_WeaponSlotButton",
        Class = "/Game/UI/Widgets/StateMachine/Loadout/WBP_UI_LoadoutCustomization_WeaponSlotButton.WBP_UI_LoadoutCustomization_WeaponSlotButton_C",
    },
}

--- Loadout weapon slot buttons; their `WeaponSlot` struct is the reliable
--- source of the equipped ModDataMap (verified in game: the by-value library
--- config and ModDataArray lose the attachment arrays, the live button does
--- not).
---@type { Name: string, Package: string, Class: string }[]
Loadout.SlotButtonCandidates = {
    {
        Name = "WBP_UI_LoadoutCustomization_WeaponSlotButton_C",
        Package = "/Game/UI/Widgets/StateMachine/Loadout/WBP_UI_LoadoutCustomization_WeaponSlotButton",
        Class = "/Game/UI/Widgets/StateMachine/Loadout/WBP_UI_LoadoutCustomization_WeaponSlotButton.WBP_UI_LoadoutCustomization_WeaponSlotButton_C",
    },
}

--- Stat field order of FSBZWeaponStats.
---@type string[]
Loadout.StatFields = { "Damage", "Recoil", "Stability", "Accuracy", "Handling", "FireRate" }

---@param Path string
---@return UObject? cdo
local function FindCdo(Path)
    local Ok, Found = Pcall("StaticFindObject " .. Path, StaticFindObject, Path)
    if Ok and Safe.IsValid(Found) then return Found end
    return nil
end

---@param Value any
---@return number? value
local function NumOf(Value)
    local Resolved = Safe.Resolve(Value)
    if type(Resolved) == "number" then return Resolved end
    if type(Resolved) == "string" then return tonumber(Resolved) end
    return nil
end

---@param Value any
---@return UObject? object
local function AsObject(Value)
    local Resolved = Safe.Resolve(Value)
    if Safe.IsValid(Resolved) then return Resolved end
    return nil
end

--- "Class /Path.Name" -> "/Path.Name".
---@param Obj any
---@return string? path
local function ObjectPath(Obj)
    if Obj == nil then return nil end
    local Text = Safe.Describe(Obj)
    local _, Path = string.match(Text, "^(%S+)%s+(%S+)")
    return Path or Text
end

--- Last dot-separated segment of an object path.
---@param Obj any
---@return string name
local function ObjectName(Obj)
    local Path = ObjectPath(Obj) or Safe.String(Obj)
    return string.match(Path, "%.([^.]+)$") or string.match(Path, "([^/%.]+)$") or Path
end

--- World context for the loadout library calls.
---@return UObject? context
local function Context()
    local PC = World.GetPlayerController()
    return PC or World.GetWorld()
end

--- Trailing segment of an FSBZWeaponInventorySlot (or the slot itself).
---@param Value any
---@return any? config # FSBZEquippableConfig wrapper
local function SlotConfig(Value)
    local Slot = Safe.Resolve(Value)
    if Slot == nil then return nil end
    local Wcis = Safe.Resolve(Safe.Get(Slot, "WeaponConfigInventorySlot"))
    if Wcis == nil then Wcis = Slot end
    local Config = Safe.Get(Wcis, "EquippableConfig")
    if Config == nil then return nil end
    return Config
end

--- Config of the first entry of a returned slot array; nil when unreadable.
---@param Value any
---@return any? config
local function ArrayConfig(Value)
    local Count = Safe.ArrayCount(Value)
    if Count == nil or Count == 0 then return nil end
    local Ok, Element = Pcall("slot array element", function() return Value[1] end)
    if not Ok or Element == nil then return nil end
    return SlotConfig(Element)
end

--- Config slot index of the active player loadout for one equippable slot.
--- Array elements from GetPlayerLoadouts must be resolved before field reads.
---@param WorldContext UObject
---@param Slot integer
---@return integer index # 0 when unavailable
function Loadout.ActiveConfigIndex(WorldContext, Slot)
    local ManagerCdo = FindCdo("/Script/Starbreeze.Default__SBZLoadoutManager")
    if ManagerCdo == nil then return 0 end
    local OkManager, Manager = Safe.CallFn(ManagerCdo, "GetLoadoutManager", WorldContext)
    if not OkManager or not Safe.IsValid(Manager) then return 0 end

    local ActiveIndex = 0
    local OkActive, Active = Safe.CallFn(Manager, "GetActiveLoadoutIndex")
    local ActiveValue = Safe.Resolve(Active)
    if type(ActiveValue) == "number" then ActiveIndex = ActiveValue end

    local OkLoadouts, Loadouts = Safe.CallFn(Manager, "GetPlayerLoadouts")
    if not OkLoadouts then return 0 end
    local Resolved = Safe.Resolve(Loadouts)
    local Array = Safe.Get(Resolved, "PlayerLoadoutConfigArray")
    if Array == nil then Array = Resolved end
    local Count = Safe.ArrayCount(Array)
    if Count == nil or ActiveIndex + 1 > Count then return 0 end

    local OkEntry, RawEntry = Pcall("loadout entry", function() return Array[ActiveIndex + 1] end)
    if not OkEntry or RawEntry == nil then return 0 end
    local Entry = Safe.Resolve(RawEntry)
    local Field = Slot == 0 and "PrimaryWeaponConfigSlotIndex"
        or (Slot == 1 and "SecondaryWeaponConfigSlotIndex" or "OverkillWeaponConfigSlotIndex")
    local Value = Safe.Resolve(Safe.Get(Entry, Field))
    if type(Value) == "number" then return Value end
    return 0
end

--- Reads BaseWeaponStats / ammo / fire type from any stats widget via the
--- game's own getters; live widgets are only read.
---@param Widget any
---@return table? stats # { Stats = {...}, Ammo = { Mag, Reserve }, FireType = { Value, Name } }
local function ReadWidgetStats(Widget)
    local Stats = Safe.Get(Widget, "BaseWeaponStats")
    if Stats == nil then return nil, "BaseWeaponStats missing" end

    local Bars = {}
    local Any = false
    for _, Field in ipairs(Loadout.StatFields) do
        local Value = NumOf(Safe.Get(Stats, Field))
        if Value ~= nil then
            Bars[Field] = Value
            Any = true
        end
    end
    if not Any then return nil, "BaseWeaponStats unreadable" end

    local FireValue = NumOf(Safe.Get(Widget, "BaseFireType"))
    local Info = {
        Stats = Bars,
        Ammo = {
            Mag = NumOf(Safe.Get(Widget, "BaseAmmoLoadedMax")),
            Reserve = NumOf(Safe.Get(Widget, "BaseAmmoInventoryMax")),
        },
        FireType = {
            Value = FireValue,
            Name = FireValue ~= nil and Loadout.FireTypes[FireValue] or nil,
        },
    }
    return Info
end

--- Normalizes widget stats to 0..100. BaseWeaponStats arrives as 0..1 ratios
--- (verified in game); all-zero means the native setter refused the config and
--- must be treated as unavailable.
---@param Stats table<string, number>
---@return table? normalized
---@return string? err
local function NormalizeBars(Stats)
    local Max = 0
    for _, Value in pairs(Stats) do
        if Value > Max then Max = Value end
    end
    if Max <= 0 then return nil, "all-zero stats (config rejected)" end
    if Max <= 1.5 then
        for Field, Value in pairs(Stats) do Stats[Field] = Value * 100 end
    end
    return Stats
end

--- True when a config carries a non-empty attachment array/map.
---@param Config any
---@return boolean
local function HasMods(Config)
    local Count = Safe.ArrayCount(Safe.Get(Config, "ModDataArray"))
    if Count ~= nil and Count > 0 then return true end
    return Maps.Count(Safe.Get(Config, "ModDataMap")) > 0
end

--- Config from a live menu widget property (the reliable source for equipped
--- attachment arrays; by-value returns lose them).
---@return any? config
---@return string? dataPath
---@return string? widgetName
local function ConfigWidgetConfig()
    for _, Candidate in ipairs(Loadout.ConfigWidgetCandidates) do
        for _, Instance in ipairs(World.FindAll(Candidate.Name)) do
            if Safe.IsValid(Instance) then
                local Config = Safe.Get(Instance, "EquippableConfig")
                local Data = AsObject(Safe.Get(Config, "EquippableData"))
                if Config ~= nil and Data ~= nil then
                    return Config, ObjectPath(Data), Candidate.Name
                end
            end
        end
    end
    return nil, nil, nil
end

--- Config of the live loadout weapon slot button matching a config slot index
--- and weapon data path. This is where the equipped ModDataMap is readable
--- (the library's by-value config copy loses it).
---@param Slot integer
---@param Index integer
---@param WeaponPath string?
---@return any? config
---@return string? weaponPath
---@return string? widgetName
local function SlotButtonConfig(Slot, Index, WeaponPath)
    for _, Candidate in ipairs(Loadout.SlotButtonCandidates) do
        for _, Instance in ipairs(World.FindAll(Candidate.Name)) do
            if Safe.IsValid(Instance) then
                local SlotIndex = NumOf(Safe.Get(Instance, "WeaponSlotIndex"))
                if SlotIndex == Index then
                    local WeaponSlot = Safe.Get(Instance, "WeaponSlot")
                    local Wcis = Safe.Resolve(Safe.Get(WeaponSlot, "WeaponConfigInventorySlot"))
                    local Config = Safe.Get(Wcis, "EquippableConfig")
                    local Data = AsObject(Safe.Get(Config, "EquippableData"))
                    local DataPath = ObjectPath(Data)
                    if Data ~= nil and (WeaponPath == nil or DataPath == WeaponPath) then
                        Log.Debug("loadout: slot button %s idx=%s weapon=%s", Candidate.Name, tostring(Index),
                            tostring(DataPath))
                        return Config, DataPath, Candidate.Name
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

---@type UObject?
Loadout._ScratchWidget = nil

---@type string?
Loadout._ScratchClass = nil

--- Creates (once) a scratch stats widget; never added to the viewport.
---@return UObject? widget
---@return string? err
function Loadout.ScratchWidget()
    if Safe.IsValid(Loadout._ScratchWidget) then return Loadout._ScratchWidget end

    local Library = FindCdo("/Script/UMG.Default__WidgetBlueprintLibrary")
    if Library == nil then return nil, "WidgetBlueprintLibrary CDO missing" end

    local PC = World.GetPlayerController()
    local WorldContext = PC or World.GetWorld()
    if WorldContext == nil then return nil, "no world context" end

    local LastErr = "no widget class available"
    for _, Candidate in ipairs(Loadout.WidgetCandidates) do
        local Class = World.LoadClass(Candidate.Package, Candidate.Class)
        if Class ~= nil then
            local OkCreate, Widget = Safe.CallFn(Library, "Create", WorldContext, Class, PC)
            if OkCreate and Safe.IsValid(Widget) then
                Loadout._ScratchWidget = Widget
                Loadout._ScratchClass = Candidate.Class
                Log.Debug("loadout: scratch widget created from %s", Candidate.Class)
                return Widget
            end
            LastErr = "Create failed for " .. Candidate.Class .. " (" .. tostring(Safe.Resolve(Widget)) .. ")"
        else
            LastErr = "class not found: " .. Candidate.Class
        end
    end
    return nil, LastErr
end

--- Game-computed FSBZWeaponStats for any equippable config, using a scratch
--- stats widget. The live game UI is untouched.
---@param Config any # FSBZEquippableConfig wrapper
---@return table? result # { Stats = {...}, Ammo = {...}, FireType = {...}, Source = "game" }
---@return string? err
function Loadout.ConfigBars(Config)
    if Config == nil then return nil, "nil config" end

    local Widget, WidgetErr = Loadout.ScratchWidget()
    if Widget == nil then return nil, WidgetErr end

    local OkSet, Err = Safe.CallFn(Widget, "SetBaseFromEquippableConfig", Config)
    if not OkSet then return nil, "SetBaseFromEquippableConfig failed: " .. tostring(Safe.Resolve(Err)) end

    local Info, ReadErr = ReadWidgetStats(Widget)
    if Info == nil then return nil, ReadErr end
    local Bars, BarsErr = NormalizeBars(Info.Stats)
    if Bars == nil then return nil, BarsErr end
    Info.Stats = Bars
    Info.Source = "game"
    return Info
end

--- Exact bars for a weapon data asset (no attachments), via the scratch widget.
---@param EquippableData any
---@return table? result
---@return string? err
function Loadout.DataBars(EquippableData)
    if EquippableData == nil then return nil, "nil weapon data" end

    local Widget, WidgetErr = Loadout.ScratchWidget()
    if Widget == nil then return nil, WidgetErr end

    local OkSet, Err = Safe.CallFn(Widget, "SetBaseFromEquippableData", EquippableData)
    if not OkSet then return nil, "SetBaseFromEquippableData failed: " .. tostring(Safe.Resolve(Err)) end

    local Info, ReadErr = ReadWidgetStats(Widget)
    if Info == nil then return nil, ReadErr end
    local Bars, BarsErr = NormalizeBars(Info.Stats)
    if Bars == nil then return nil, BarsErr end
    Info.Stats = Bars
    Info.Source = "game"
    return Info
end

--- Exact bars of the equipped config at one loadout slot index, via the
--- scratch widget's SetBaseFromSlot (includes attachments; verified in game:
--- differs from the bare weapon data by the attachment effects).
---@param Slot integer # ESBZEquippableLoadoutSlot
---@param Index integer # config slot index from Loadout.ActiveConfigIndex
---@return table? result
---@return string? err
function Loadout.EquippedBars(Slot, Index)
    if type(Slot) ~= "number" or type(Index) ~= "number" then return nil, "slot/index required" end

    local Widget, WidgetErr = Loadout.ScratchWidget()
    if Widget == nil then return nil, WidgetErr end

    local OkSet, Err = Safe.CallFn(Widget, "SetBaseFromSlot", Slot, Index)
    if not OkSet then return nil, "SetBaseFromSlot failed: " .. tostring(Safe.Resolve(Err)) end

    local Info, ReadErr = ReadWidgetStats(Widget)
    if Info == nil then return nil, ReadErr end
    local Bars, BarsErr = NormalizeBars(Info.Stats)
    if Bars == nil then return nil, BarsErr end
    Info.Stats = Bars
    Info.Source = "game"
    return Info
end

--- Equipped config for one loadout slot: the active loadout's config slot
--- index (SBZLoadoutManager) fetched through SBZLoadoutLibrary, with live menu
--- widget fallbacks. Attachment arrays come from a live widget config when the
--- by-value library config carries none.
---@param SlotNameOrIndex? string|integer # "PrimaryWeapon" or ESBZEquippableLoadoutSlot; default primary
---@return any? config # FSBZEquippableConfig wrapper
---@return table? info # { Source, Slot, SlotName, Index, EquippableData, BaseEquippableData, Widget }
---@return string? err
function Loadout.EquippedConfig(SlotNameOrIndex)
    local Slot = SlotNameOrIndex
    if type(Slot) == "string" then Slot = Loadout.Slots[Slot] end
    if type(Slot) ~= "number" then Slot = Loadout.Slots.PrimaryWeapon end

    local Library = FindCdo(Loadout.LibraryPath)
    local WorldContext = Context()
    local LastErr = "loadout library unavailable"
    local Source = "loadout"

    if Library ~= nil and WorldContext ~= nil then
        local Index = Loadout.ActiveConfigIndex(WorldContext, Slot)
        local OkDirect, Direct = Safe.CallFn(Library, "GetWeaponConfigSlot", WorldContext, Slot, Index)
        local Config = OkDirect and SlotConfig(Direct) or nil
        if Config == nil and Index ~= 0 then
            local OkZero, Zero = Safe.CallFn(Library, "GetWeaponConfigSlot", WorldContext, Slot, 0)
            Config = OkZero and SlotConfig(Zero) or nil
            Index = 0
        end
        if Config == nil then
            local OkList, List = Safe.CallFn(Library, "GetWeaponConfigSlotsForEquippable", WorldContext, Slot)
            if OkList then Config = ArrayConfig(List) end
        end
        if Config ~= nil then
            local Data = AsObject(Safe.Get(Config, "EquippableData"))
            if Data == nil then
                LastErr = "loadout config has no resolvable weapon data"
            else
                local DataPath = ObjectPath(Data)
                local BaseData = Data
                if not HasMods(Config) then
                    local RuntimeConfig, _, RuntimeOriginal = Loadout.WidgetConfig(Slot, Index)
                    local RuntimeOriginalPath = ObjectPath(RuntimeOriginal)
                    if RuntimeConfig ~= nil and HasMods(RuntimeConfig)
                        and (RuntimeOriginalPath == nil or RuntimeOriginalPath == DataPath) then
                        Log.Debug("loadout: attachments from runtime widget config (idx=%s)", tostring(Index))
                        Config = RuntimeConfig
                        Source = "loadout+widget"
                        if RuntimeOriginal ~= nil then BaseData = RuntimeOriginal end
                    end
                end
                if not HasMods(Config) then
                    local ButtonConfig, ButtonDataPath, ButtonName = SlotButtonConfig(Slot, Index, DataPath)
                    if ButtonConfig ~= nil and HasMods(ButtonConfig) then
                        Log.Debug("loadout: attachments from slot button %s (idx=%s)", tostring(ButtonName),
                            tostring(Index))
                        Config = ButtonConfig
                        Source = "loadout+slotbutton"
                    else
                        local WidgetConfig, WidgetDataPath, WidgetName = ConfigWidgetConfig()
                        if WidgetConfig ~= nil and (WidgetDataPath == DataPath or ButtonDataPath == WidgetDataPath)
                            and HasMods(WidgetConfig) then
                            Log.Debug("loadout: attachments from live widget %s", tostring(WidgetName))
                            Config = WidgetConfig
                            Source = "loadout+menumods"
                        end
                    end
                end
                return Config, {
                    Source = Source,
                    Slot = Slot,
                    SlotName = Loadout.SlotNames[Slot],
                    Index = Index,
                    EquippableData = Safe.Get(Config, "EquippableData"),
                    BaseEquippableData = BaseData,
                }
            end
        else
            LastErr = "loadout library returned no config"
        end
    end

    local WidgetConfig, _, WidgetName = ConfigWidgetConfig()
    if WidgetConfig ~= nil then
        return WidgetConfig, {
            Source = "widget",
            Slot = Slot,
            SlotName = Loadout.SlotNames[Slot],
            Index = 0,
            EquippableData = Safe.Get(WidgetConfig, "EquippableData"),
            BaseEquippableData = AsObject(Safe.Get(WidgetConfig, "EquippableData")),
            Widget = WidgetName,
        }
    end

    for _, Candidate in ipairs(Loadout.WidgetCandidates) do
        for _, Instance in ipairs(World.FindAll(Candidate.Name)) do
            if Safe.IsValid(Instance) then
                local Config = Safe.Get(Instance, "BaseEquippableConfig")
                if Config ~= nil and AsObject(Safe.Get(Config, "EquippableData")) ~= nil then
                    return Config, {
                        Source = "widget",
                        Slot = Slot,
                        SlotName = Loadout.SlotNames[Slot],
                        Index = 0,
                        EquippableData = Safe.Get(Config, "EquippableData"),
                        BaseEquippableData = AsObject(Safe.Get(Config, "EquippableData")),
                        Widget = Candidate.Name,
                    }
                end
            end
        end
    end

    return nil, nil, LastErr .. "; no live menu config found"
end

--- Config from the scratch stats widget after SetBaseFromSlot: the game's own
--- runtime config for that loadout slot, including the ModDataMap that
--- by-value library returns lose. Unlike the loadout weapon slot buttons this
--- works independently of which menu screen is open.
---@param Slot integer # ESBZEquippableLoadoutSlot
---@param Index integer # config slot index from Loadout.ActiveConfigIndex
---@return any? config
---@return UObject? equippedData # runtime (attachment-adjusted) copy
---@return UObject? originalData # base asset
---@return string? err
function Loadout.WidgetConfig(Slot, Index)
    if type(Slot) ~= "number" or type(Index) ~= "number" then
        return nil, nil, nil, "slot/index required"
    end

    local Widget, WidgetErr = Loadout.ScratchWidget()
    if Widget == nil then return nil, nil, nil, WidgetErr end

    local OkSet, Err = Safe.CallFn(Widget, "SetBaseFromSlot", Slot, Index)
    if not OkSet then return nil, nil, nil, "SetBaseFromSlot failed: " .. tostring(Safe.Resolve(Err)) end

    local Config = Safe.Get(Widget, "BaseEquippableConfig")
    if Config == nil then return nil, nil, nil, "BaseEquippableConfig missing" end

    return Config, AsObject(Safe.Get(Config, "EquippableData")), AsObject(Safe.Get(Config, "OriginalEquippableData")), nil
end

--- Runtime (attachment-adjusted) weapon data of the equipped config. When the
--- loadout is applied the game swaps the config's EquippableData for a
--- transient copy under the player state; SetBaseFromSlot resolves it, and
--- OriginalEquippableData still points at the base asset. Reading Raw() on the
--- returned object yields the game-adjusted hidden stats.
---@param Slot integer # ESBZEquippableLoadoutSlot
---@param Index integer # config slot index from Loadout.ActiveConfigIndex
---@return UObject? equippedData
---@return UObject? originalData
---@return string? err
function Loadout.EquippedWeaponData(Slot, Index)
    local _, Equipped, Original, Err = Loadout.WidgetConfig(Slot, Index)
    if Equipped == nil then return nil, nil, Err or "runtime weapon data unresolved" end
    return Equipped, Original, nil
end

--- Weapon data asset of a config plus display metadata.
---@param Config any
---@param DataOverride? UObject # use this data asset instead of the config's EquippableData
---@return table? weapon # { Object, Path, Name, DisplayName, IsRanged }
function Loadout.WeaponData(Config, DataOverride)
    local Data = AsObject(DataOverride) or AsObject(Safe.Get(Config, "EquippableData"))
    if Data == nil then return nil end

    local Path = ObjectPath(Data) or ""
    local ClassPath = ""
    local OkClass, ClassObj = Pcall("weapon data class", function() return Data:GetClass() end)
    if OkClass and Safe.IsValid(ClassObj) then
        ClassPath = ObjectPath(ClassObj) or ""
    end

    return {
        Object = Data,
        Path = Path,
        Name = ObjectName(Data),
        DisplayName = Safe.Text(Safe.Get(Data, "DisplayName")),
        IsRanged = string.find(ClassPath, "SBZRangedWeaponData", 1, true) ~= nil,
    }
end

--- "WPD_WAR45_Mag_Extended" + "WPD_" -> "WAR45 Mag Extended"; used when the
--- asset carries no localized DisplayName (the menu parts often do not).
---@param Name string?
---@param Prefix string?
---@return string?
function Loadout.PrettyName(Name, Prefix)
    if type(Name) ~= "string" or Name == "" then return nil end
    local Text = Name
    if Prefix ~= nil and Prefix ~= "" and string.sub(Text, 1, #Prefix) == Prefix then
        Text = string.sub(Text, #Prefix + 1)
    end
    Text = string.gsub(Text, "_", " ")
    return Text
end

--- Equipped attachments of a config. ModDataMap is the primary source (slot ->
--- part + config); ModDataArray entries missing from the map are appended.
--- Every entry carries the part modifiers and the curve expansion.
---@param Config any
---@return table[] parts
function Loadout.ConfigParts(Config)
    local Result = {}
    if Config == nil then return Result end

    local Seen = {}
    local function Add(SlotObject, PartObject)
        local Part = AsObject(PartObject)
        local SlotAsset = AsObject(SlotObject)
        local SlotName = SlotAsset ~= nil and ObjectName(SlotAsset) or nil
        local PartName = Part ~= nil and ObjectName(Part) or nil
        local Entry = {
            Slot = SlotAsset,
            SlotName = SlotName or "Unknown",
            SlotDisplay = (SlotAsset ~= nil and Safe.TextOrNil(Safe.Get(SlotAsset, "DisplayName")))
                or Loadout.PrettyName(SlotName, "SLOT_"),
            Part = Part,
            PartName = PartName,
        }
        if Part ~= nil then
            local Path = ObjectPath(Part) or PartName
            if Seen[Path] then return end
            Seen[Path] = true
            Entry.PartDisplay = Safe.TextOrNil(Safe.Get(Part, "DisplayName")) or Loadout.PrettyName(PartName, "WPD_")
            Entry.Description = Safe.TextOrNil(Safe.Get(Part, "ShortDescriptionText"))
            local Info = Weapons.PartInfo(Part)
            if Info ~= nil then
                Entry.Modifiers = Info.Modifiers
                local _, Details = Weapons.ModifierMultipliers(Info.Modifiers)
                Entry.Expansion = Details
            end
        end
        Result[#Result + 1] = Entry
    end

    Maps.ForEach(Safe.Get(Config, "ModDataMap"), function(Key, ValueWrapper)
        local Group = Safe.Resolve(ValueWrapper)
        Add(Key, Safe.Get(Group, "Part"))
    end)

    local Mods = Safe.Get(Config, "ModDataArray")
    local Count = Safe.ArrayCount(Mods)
    if Count ~= nil then
        for Index = 1, Count do
            local Ok, Part = Pcall("mod array element", function() return Mods[Index] end)
            if Ok and Part ~= nil then
                local Path = ObjectPath(AsObject(Part) or Part) or tostring(Index)
                if not Seen[Path] then
                    Add(nil, Part)
                end
            end
        end
    end

    return Result
end

return Loadout
