--- Weapon data helpers: database enumeration, raw and hidden stat reads,
--- modular part inspection, attribute modifier curves (live CT_ModData_Default
--- with an offline fallback) and parent-attribute expansion.
---
--- All readers are reflection-driven and tolerate game updates: missing fields
--- resolve to nil instead of raising.
---@class pd3.Weapons
local Weapons = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Maps = require("pd3lib.core.maps")
local Reflect = require("pd3lib.core.reflect")
local Log = require("pd3lib.core.log")
local CurvesFallback = require("pd3lib.game.weapons_curves")

local Unpack = table.unpack or unpack

--- pcall wrapper that never hides the failure: logs it at Debug level
--- (enabled by Safe.Verbose / pd3.Init debug).
---@param What string
---@param Fn fun(...): ...
---@param ... any
---@return boolean ok
---@return any ...
local function Pcall(What, Fn, ...)
    local Results = { pcall(Fn, ...) }
    local Ok = table.remove(Results, 1)
    if not Ok and Safe.Verbose then
        Log.Debug("weapons: %s failed: %s", What, tostring(Results[1]))
    end
    return Ok, Unpack(Results)
end

--- Short class name of the weapon database assets.
---@type string
Weapons.DatabaseClass = "SBZWeaponDatabase"

--- Short class name of ranged weapon data assets.
---@type string
Weapons.RangedClass = "SBZRangedWeaponData"

--- Full object path of the attribute modifier curve table.
---@type string
Weapons.CurveTablePath = CurvesFallback.Source

--- CDO of the settings object holding the UI weapon stats asset path.
---@type string
Weapons.ModificationSettingsPath = "/Script/Starbreeze.Default__SBZWeaponModificationSettings"

--- Sentinel used by curve tables for "no default".
---@type number
Weapons.NoValue = 3.4028235e38

--- ESBZWeaponAttribute value -> name (ATTRIBUTE_START..MAX range).
---@type table<integer, string>
Weapons.AttributeNames = {
    [0] = "NONE",
    [1] = "VerticalRecoil",
    [2] = "HorizontalRecoil",
    [3] = "InitialRecoil",
    [4] = "OverallReloadPlayRate",
    [5] = "EquipPlayRate",
    [6] = "UnequipPlayRate",
    [7] = "SprintExitPlayRate",
    [8] = "DamageDistance",
    [9] = "CriticalDamageMultiplierDistance",
    [10] = "TargetingTransitionTime",
    [11] = "ArmorPenetration",
    [12] = "HipfireSpread",
    [13] = "TargetingSpread",
    [14] = "SpreadIncrement",
    [15] = "VerticalSpreadRadius",
    [16] = "HorizontalSpreadRadius",
    [17] = "VerticalGunkick",
    [18] = "HorizontalGunkick",
    [19] = "ScreenShakeAmplitude",
    [20] = "OverallPelletDeviation",
    [21] = "ViewKickRecoverySpeed",
    [22] = "ViewKickRecoveryDelay",
    [23] = "GunKickBackDistance",
    [24] = "HurtBuildup",
    [25] = "CriticalHurtBuildup",
    [26] = "HurtBuildupMultiplier",
    [27] = "EndCycleReloadPlayRate",
    [28] = "OverallDamage",
    [29] = "CriticalDamage",
    [30] = "LoadoutWeight",
    [31] = "OverallRecoil",
    [32] = "OverallSpread",
    [33] = "OverallGunkick",
    [34] = "OverallSwapSpeed",
    [35] = "OverallSpreadRadius",
    [36] = "OverallHurtBuildup",
}

--- Attribute name of a TMap key (number, string or enum wrapper).
---@param Key any
---@return string name
function Weapons.AttributeName(Key)
    local Resolved = Safe.Resolve(Key)
    if type(Resolved) == "number" then
        return Weapons.AttributeNames[Resolved] or ("Unknown(" .. Resolved .. ")")
    end
    local Text = Safe.String(Resolved)
    local Short = string.match(Text, "::([%w_]+)$") or Text
    return Short
end

--- Field names read from USBZWeaponFireData (curated for stability).
---@type string[]
local FireNumbers = {
    "RoundsPerMinute", "AmmoLoadedMax", "AmmoPerReload", "AmmoVisibleMax",
    "AmmoVisibleMaxPreviewOverride", "Range", "AdditionalPlayerRange",
    "MaximumPenetrationCount", "ProjectilesPerFiredRound", "BurstRoundCount",
    "ArmorPenetration", "ArmorPenetrationProjectile", "HealthDamageMultiplier",
    "ArmorDamageMultiplier", "OverHealDamageMultiplier", "FriendlyPlayerDamageScale",
    "InstigatorPlayerDamageScale", "FireBuildupIncrease", "FireBuildupShotIncrease",
    "FireBuildupDecrease", "StartFireBuildupIncrease", "StartFireBuildupShotIncrease",
    "StartFireBuildupDecrease", "StartFireMinBuildup", "Priority",
    "ClusterGrenadeSpawnDegrees", "GasTickSeconds", "GasDamagePerSecond",
    "GasRange", "GasDurationSeconds", "GasExplosionDelay", "GasPostMarkDuration",
    "GasRangeMultiplierIncrease",
}

--- Boolean fields read from USBZWeaponFireData.
---@type string[]
local FireBools = {
    "bCanHitEnvironmentAfterPenetration", "bCanPenetrateBlocked",
    "bIsFriendlyFireAllowed", "bIsEmptyAmmoEjected", "bIsEquippedAmmoLoadedTracked",
    "bIsChamberRotatedEachFiredRound", "bIsChamberRotatedEachReloadedRound",
    "bIsUsingRemoveMagazineCycle", "bIsUsingInsertMagazine",
    "bIsUsingInsertMagazineCycle", "bIsUsingInsertAmmoCycle1",
    "bIsUsingInsertAmmoCycle2", "bUseInstigatorPlayerDamageScale",
}

--- Enum fields read from USBZWeaponFireData.
---@type string[]
local FireEnums = { "FireMode", "FireType", "ImpactType", "AmmoVisibilityType" }

--- Field names read from USBZWeaponSpreadData.
---@type string[]
local SpreadNumbers = {
    "InnerClusterNumber", "InnerClusterSpreadMultiplier", "PieOcclusion",
    "FireSpreadStart", "FireSpreadIncrease", "FireSpreadResetTime",
    "FireSpreadDecayRate", "FireSpreadMinCap", "FireSpreadCap",
    "DeviationHipFireMultiplier", "DeviationTargetingFireMultiplier",
}

--- Field names read from USBZWeaponTargetingData.
---@type string[]
local TargetingNumbers = {
    "TargetingTransitionTime", "TargetingProgressTrigger", "TargetingXAxisOffset",
    "TargetingMagnification", "TargetingOnTopMagnification",
}

--- Struct fields of SBZRecoilData flattened into a raw stat map.
---@type string[]
local RecoilStructs = {
    "ViewKick", "ViewKickBack", "ViewKickBackTargeting",
    "GunKickXY", "GunKickBack", "GunKickBackTargeting",
}

--- Struct field names never flattened (curves and scatter plots).
---@type table<string, boolean>
local StructSkip = {
    EditorCurveData = true, DeflectCurve = true, RecoverCurve = true,
    GraphDisplacementList = true, ModeArray = true, ModeDataArray = true,
}

--- "Class /Path.Name" -> object path "/Path.Name".
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

--- Resolves a property wrapper to a valid UObject, else nil.
---@param Value any
---@return UObject? object
local function AsObject(Value)
    local Resolved = Safe.Resolve(Value)
    if Safe.IsValid(Resolved) then return Resolved end
    return nil
end

--- Resolves a property value to a number (wrappers and numeric strings included).
---@param Value any
---@return number? value
local function NumOf(Value)
    local Resolved = Safe.Resolve(Value)
    if type(Resolved) == "number" then return Resolved end
    if type(Resolved) == "string" then return tonumber(Resolved) end
    return nil
end

--- Resolves a property value to a boolean (UE4SS wrapper forms included).
---@param Value any
---@return boolean? value
local function BoolOf(Value)
    local Resolved = Safe.Resolve(Value)
    if type(Resolved) == "boolean" then return Resolved end
    if type(Resolved) == "number" then return Resolved ~= 0 end
    if type(Resolved) == "string" then
        local Text = string.lower(Resolved)
        if Text == "true" then return true end
        if Text == "false" then return false end
    end
    return nil
end

--- Numbers of an array-like value; nil when the array is unreadable.
---@param Value any
---@return number[]? values
local function NumberArray(Value)
    local Count = Safe.ArrayCount(Value)
    if Count == nil then return nil end
    local Result = {}
    for Index = 1, Count do
        local Ok, Element = Pcall("array element", function() return Value[Index] end)
        if Ok then
            local Number = NumOf(Element)
            if Number ~= nil then Result[#Result + 1] = Number end
        end
    end
    return Result
end

--- Reads a fixed field list as numbers into Out["Prefix.Field"].
---@param Obj any
---@param Prefix string
---@param Fields string[]
---@param Out table<string, number>
local function ReadNumbers(Obj, Prefix, Fields, Out)
    if Obj == nil then return end
    for _, Field in ipairs(Fields) do
        local Value = NumOf(Safe.Get(Obj, Field))
        if Value ~= nil then Out[Prefix .. Field] = Value end
    end
end

--- Reads a fixed field list as booleans into Out["Prefix.Field"].
---@param Obj any
---@param Prefix string
---@param Fields string[]
---@param Out table<string, boolean>
local function ReadBools(Obj, Prefix, Fields, Out)
    if Obj == nil then return end
    for _, Field in ipairs(Fields) do
        local Value = BoolOf(Safe.Get(Obj, Field))
        if Value ~= nil then Out[Prefix .. Field] = Value end
    end
end

--- Flattens a struct value's numeric leaves into "Prefix.Field" keys.
---@param Struct any # struct wrapper or table
---@param Prefix string
---@param Out table<string, number>
---@param Depth integer
local function FlattenStruct(Struct, Prefix, Out, Depth)
    if Struct == nil or Depth < 0 then return end
    for _, Property in ipairs(Reflect.PropertiesOf(Struct)) do
        local OkName, RawName = Pcall("property name", function() return Property:GetFName() end)
        local Name = OkName and Safe.String(RawName) or nil
        if Name ~= nil and not StructSkip[Name] then
            local Tag = Reflect.PropertyTag(Property)
            local Value = Safe.Get(Struct, Name)
            if Tag == "StructProperty" then
                if Depth > 0 then
                    FlattenStruct(Safe.Resolve(Value), Prefix .. Name .. ".", Out, Depth - 1)
                end
            elseif Tag ~= "ArrayProperty" and Tag ~= "MapProperty" and Tag ~= "SetProperty"
                and Tag ~= "ObjectProperty" and Tag ~= "SoftObjectProperty" and Tag ~= "TextProperty" then
                if type(Value) == "number" then Out[Prefix .. Name] = Value end
            end
        end
    end
end

--- Reads an array of structs as tables with the named fields.
---@param Obj any
---@param Field string
---@param StructFields string[]
---@return table[] entries
local function StructArray(Obj, Field, StructFields)
    local Result = {}
    local Array = Safe.Get(Obj, Field)
    local Count = Safe.ArrayCount(Array)
    if Count == nil then return Result end
    for Index = 1, Count do
        local Ok, Element = Pcall("array element", function() return Array[Index] end)
        if Ok and Element ~= nil then
            local Entry = {}
            for _, Name in ipairs(StructFields) do
                local Value = Safe.Resolve(Safe.Get(Element, Name))
                if type(Value) == "number" or type(Value) == "boolean" or type(Value) == "string" then
                    Entry[Name] = Value
                end
            end
            Result[#Result + 1] = Entry
        end
    end
    return Result
end

--- Reads an array of UObjects into a plain list.
---@param Obj any
---@param Field string
---@return UObject[] objects
local function ObjectArray(Obj, Field)
    local Result = {}
    local Array = Safe.Get(Obj, Field)
    local Count = Safe.ArrayCount(Array)
    if Count == nil then return Result end
    for Index = 1, Count do
        local Ok, Element = Pcall("array element", function() return Array[Index] end)
        if Ok then
            local Object = AsObject(Element)
            if Object ~= nil then Result[#Result + 1] = Object end
        end
    end
    return Result
end

--- Weapon database assets currently loaded (Default__ CDOs excluded).
---@return UObject[] databases
function Weapons.Databases()
    local Result = {}
    for _, Database in ipairs(World.FindAll(Weapons.DatabaseClass)) do
        if Safe.IsValid(Database) then
            local Path = ObjectPath(Database) or ""
            if not string.find(Path, "Default__", 1, true) then
                Result[#Result + 1] = Database
            end
        end
    end
    return Result
end

--- Weapon entries of one database; entries are { Object, Name, Path }.
---@param Database UObject? # defaults to all databases
---@return table[] entries
function Weapons.WeaponEntries(Database)
    local Result = {}
    local Databases = Database ~= nil and { Database } or Weapons.Databases()
    for _, Db in ipairs(Databases) do
        local Array = Safe.Get(Db, "Weapons")
        local Count = Safe.ArrayCount(Array)
        if Count ~= nil then
            for Index = 1, Count do
                local Ok, Weapon = Pcall("weapon entry", function() return Array[Index] end)
                if Ok then
                    local Object = AsObject(Weapon)
                    if Object ~= nil then
                        Result[#Result + 1] = {
                            Object = Object,
                            Name = ObjectName(Object),
                            Path = ObjectPath(Object),
                        }
                    end
                end
            end
        end
    end
    return Result
end

--- All weapons of all loaded databases.
---@return table[] entries
function Weapons.All()
    return Weapons.WeaponEntries(nil)
end

--- First weapon whose name or path contains Query (case-insensitive);
--- an exact path match wins.
---@param Query string
---@return UObject? weapon
---@return table? entry
function Weapons.Find(Query)
    if type(Query) ~= "string" then return nil, nil end
    local Lower = string.lower(Query)
    local Partial = nil
    for _, Entry in ipairs(Weapons.All()) do
        if Entry.Path == Query then return Entry.Object, Entry end
        if Partial == nil and string.find(string.lower(Entry.Path), Lower, 1, true) then
            Partial = Entry
        end
    end
    if Partial ~= nil then return Partial.Object, Partial end
    return nil, nil
end

--- Accepts a weapon object, an entry or a query string.
---@param Value any
---@return UObject? weapon
function Weapons.Resolve(Value)
    if Safe.IsValid(Value) then return Value end
    if type(Value) == "table" and Safe.IsValid(Value.Object) then return Value.Object end
    if type(Value) == "string" then return (Weapons.Find(Value)) end
    return nil
end

--- Resolve with a LoadAsset fallback for path-like queries (game thread only).
---@param Query string
---@return UObject? weapon
function Weapons.Ensure(Query)
    if type(Query) ~= "string" then return nil end
    local Found = Weapons.Find(Query)
    if Found ~= nil then return Found end
    if not string.find(Query, "/", 1, true) then return nil end

    local OkFind, Object = Pcall("StaticFindObject " .. tostring(Query), StaticFindObject, Query)
    if OkFind and Safe.IsValid(Object) then return Object end

    if string.match(Query, "^/Game/.+%.[%w_]+$") ~= nil and type(LoadAsset) == "function" then
        Pcall("LoadAsset " .. tostring(Query), LoadAsset, Query)
        local OkAgain, Again = Pcall("StaticFindObject " .. tostring(Query), StaticFindObject, Query)
        if OkAgain and Safe.IsValid(Again) then return Again end
    end
    return nil
end

--- Sub-asset objects referenced by a ranged weapon.
---@param Weapon any
---@return table<string, UObject?>
function Weapons.Subobjects(Weapon)
    local Live = Weapons.Resolve(Weapon)
    return {
        Fire = AsObject(Safe.Get(Live, "FireData")),
        OriginalFire = AsObject(Safe.Get(Live, "OriginalFireData")),
        Spread = AsObject(Safe.Get(Live, "SpreadData")),
        Recoil = AsObject(Safe.Get(Live, "RecoilData")),
        Targeting = AsObject(Safe.Get(Live, "TargetingData")),
        Sway = AsObject(Safe.Get(Live, "SwayData")),
        Tanking = AsObject(Safe.Get(Live, "TankingData")),
        WallReaction = AsObject(Safe.Get(Live, "WallReactionData")),
        DOF = AsObject(Safe.Get(Live, "DOFData")),
        Progression = AsObject(Safe.Get(Live, "ItemProgression")),
    }
end

--- Raw and hidden stats of one ranged weapon as plain numbers/booleans/tables.
--- Hidden values include the swap-speed notify times and play rates and the
--- full gun-kick numbers from the recoil asset.
---@param Weapon any
---@return table? stats
function Weapons.Raw(Weapon)
    local Live = Weapons.Resolve(Weapon)
    if Live == nil then return nil end

    local Sub = Weapons.Subobjects(Live)
    local Stats = {
        Name = ObjectName(Live),
        Path = ObjectPath(Live),
        Swap = {
            EquipNotifyTime = NumOf(Safe.Get(Live, "EquipNotifyTime")),
            UnequipNotifyTime = NumOf(Safe.Get(Live, "UnequipNotifyTime")),
            SprintExitNotifyTime = NumOf(Safe.Get(Live, "SprintExitNotifyTime")),
            ReloadEmptyNotifyTime = NumOf(Safe.Get(Live, "ReloadEmptyNotifyTime")),
            ReloadNotifyTime = NumOf(Safe.Get(Live, "ReloadNotifyTime")),
            SprintEnterPlayRate = NumOf(Safe.Get(Live, "SprintEnterPlayRate")),
            SprintExitPlayRate = NumOf(Safe.Get(Live, "SprintExitPlayRate")),
            WeaponDeselectionTimer = NumOf(Safe.Get(Live, "WeaponDeselectionTimer")),
            SwitchCooldown = BoolOf(Safe.Get(Live, "bShouldApplyWeaponSwitchCooldown")),
        },
        Fire = {},
        Spread = {},
        Recoil = {},
        Targeting = {},
        Damage = {},
    }

    ReadNumbers(Sub.Fire, "Fire.", FireNumbers, Stats.Fire)
    ReadBools(Sub.Fire, "Fire.", FireBools, Stats.Fire)
    ReadNumbers(Sub.Fire, "Fire.", FireEnums, Stats.Fire)

    ReadNumbers(Sub.Spread, "Spread.", SpreadNumbers, Stats.Spread)
    local Recovery = NumOf(Safe.Get(Sub.Spread, "SpreadRecoveryMode"))
    if Recovery ~= nil then Stats.Spread["Spread.SpreadRecoveryMode"] = Recovery end
    local Radius = Safe.Get(Sub.Spread, "SpreadRadiusMultipliers")
    for _, Axis in ipairs({ "X", "Y" }) do
        local Value = NumOf(Safe.Get(Radius, Axis))
        if Value ~= nil then Stats.Spread["Spread.SpreadRadiusMultipliers." .. Axis] = Value end
    end

    ReadNumbers(Sub.Targeting, "Targeting.", TargetingNumbers, Stats.Targeting)

    if Sub.Recoil ~= nil then
        ReadNumbers(Sub.Recoil, "Recoil.", { "DisplacementListMultiplier", "GunKickBackAlpha" }, Stats.Recoil)
        for _, Field in ipairs(RecoilStructs) do
            FlattenStruct(Safe.Resolve(Safe.Get(Sub.Recoil, Field)), "Recoil." .. Field .. ".", Stats.Recoil, 2)
        end
    end

    if Sub.Fire ~= nil then
        Stats.Damage = {
            DamageDistance = StructArray(Sub.Fire, "DamageDistanceArray", { "Damage", "Distance" }),
            DamageDistanceProjectile = StructArray(Sub.Fire, "DamageDistanceProjectileArray", { "Damage", "Distance" }),
            CriticalDamageMultiplierDistance = StructArray(Sub.Fire, "CriticalDamageMultiplierDistanceArray", { "Multiplier", "Distance" }),
            MaximumPenetrationCountDistance = StructArray(Sub.Fire, "MaximumPenetrationCountDistanceArray", { "Count", "Distance" }),
        }
    end

    return Stats
end

--- FireData of the currently equipped weapon, read from the live pawn chain
--- (in-heist path, unlike `Loadout.EquippedWeaponData` which goes through the
--- menu widgets):
---   PlayerController.Pawn.CurrentEquippableConfig.EquippableData.FireData
---   (fallback: .CurrentEquippable.EquippableConfig.EquippableData.FireData)
--- Nil (with a reason) when nothing suitable is equipped — melee/throwable
--- have no FireData at all. Game-thread safe (property reads only).
---@return UObject? fireData
---@return string? err
function Weapons.EquippedFireDataLive()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil, "no player controller" end

    local Pawn = Safe.Get(Controller, "Pawn")
    if not Safe.IsValid(Pawn) then return nil, "no pawn" end

    local Data = nil
    local Config = Safe.Resolve(Safe.Get(Pawn, "CurrentEquippableConfig"))
    if Config ~= nil then Data = Safe.Resolve(Safe.Get(Config, "EquippableData")) end
    if not Safe.IsValid(Data) then
        local Equippable = Safe.Resolve(Safe.Get(Pawn, "CurrentEquippable"))
        if Equippable ~= nil then
            local Config2 = Safe.Resolve(Safe.Get(Equippable, "EquippableConfig"))
            if Config2 ~= nil then Data = Safe.Resolve(Safe.Get(Config2, "EquippableData")) end
        end
    end
    if not Safe.IsValid(Data) then return nil, "no equippable data (melee/throwable?)" end

    local Fire = Safe.Resolve(Safe.Get(Data, "FireData"))
    if not Safe.IsValid(Fire) then return nil, "no FireData (melee/throwable or AI weapon?)" end
    return Fire
end

--- `Distance` values (cm) of an array-of-structs property. `#` is tried
--- first, then `GetArrayNum` (they disagree in this build); elements are
--- read 1-based via `el.Distance`. Nil when the array is missing/empty.
---@param Obj any
---@param FieldName string
---@return number[]? distancesCm
function Weapons.DistanceFieldCm(Obj, FieldName)
    local Array = Safe.Get(Obj, FieldName)
    if Array == nil then return nil end

    local Count = Safe.ArrayCount(Array)
    if Count == nil or Count <= 0 then
        local OkNum, Num = Pcall("GetArrayNum " .. FieldName, function() return Array:GetArrayNum() end)
        if OkNum and type(Num) == "number" and Num > 0 then Count = Num end
    end
    if Count == nil or Count <= 0 then return nil end

    local Result = {}
    for Index = 1, Count do
        local Ok, Element = Pcall("distance element", function() return Array[Index] end)
        if Ok and Element ~= nil then
            local Distance = NumOf(Safe.Get(Element, "Distance"))
            if Distance ~= nil then Result[#Result + 1] = Distance end
        end
    end

    if #Result == 0 then return nil end
    return Result
end

--- Raw damage and critical-multiplier breakpoints (cm) of a FireData object.
---@param Fire any
---@return number[]? damageCm
---@return number[]? critCm
function Weapons.BreakpointsCm(Fire)
    if Fire == nil then return nil, nil end
    return Weapons.DistanceFieldCm(Fire, "DamageDistanceArray"),
        Weapons.DistanceFieldCm(Fire, "CriticalDamageMultiplierDistanceArray")
end

--- Union of damage and crit breakpoints (cm) as a sorted, deduped list of
--- meters rounded to 2 decimals. Pure; nil-safe.
---@param RawDamages number[]?
---@param RawCrits number[]?
---@return number[] meters
function Weapons.DistancesFromCm(RawDamages, RawCrits)
    local Seen, List = {}, {}
    local function Add(Cm)
        if type(Cm) ~= "number" or Cm <= 0 then return end
        local Meters = math.floor(Cm / 100 * 100 + 0.5) / 100
        if Meters > 0 and not Seen[Meters] then
            Seen[Meters] = true
            List[#List + 1] = Meters
        end
    end

    for _, Value in ipairs(type(RawDamages) == "table" and RawDamages or {}) do Add(Value) end
    for _, Value in ipairs(type(RawCrits) == "table" and RawCrits or {}) do Add(Value) end
    table.sort(List)
    return List
end

--- Falloff breakpoints (meters) of a FireData object; with no argument it
--- reads the live equipped weapon (`EquippedFireDataLive`). Empty table when
--- unreadable, so callers can fall back to configured distances.
--- Caveat: AI weapon FireData often lacks the distance arrays entirely.
---@param Fire any? # defaults to the equipped weapon's live FireData
---@return number[] meters
function Weapons.BreakpointsMeters(Fire)
    if Fire == nil then
        Fire = Weapons.EquippedFireDataLive()
    end
    local DamageCm, CritCm = Weapons.BreakpointsCm(Fire)
    return Weapons.DistancesFromCm(DamageCm, CritCm)
end

--- Distance-band lookup over the raw FireData arrays (entries sorted ascending
--- by Distance in cm, fields as produced by Weapons.Raw).
--- Damage uses the native inclusive band (first entry with Distance >= query,
--- else the last one, matching FUN_144d16f68); the critical multiplier uses the
--- strict band (first entry with Distance > query, else the last one, matching
--- FUN_144d12fac).
---@param Entries table[]? # Weapon.Raw().Damage.DamageDistance or CriticalDamageMultiplierDistance
---@param Field string # "Damage" or "Multiplier"
---@param Meters number
---@param Strict boolean # true = first entry strictly beyond the distance
---@return number? value
local function BandAtDistance(Entries, Field, Meters, Strict)
    if type(Entries) ~= "table" or #Entries == 0 then return nil end
    local Distance = Meters * 100
    local Last = nil
    for _, Entry in ipairs(Entries) do
        local Value = NumOf(Entry[Field])
        local EntryDistance = NumOf(Entry.Distance)
        if Value ~= nil and EntryDistance ~= nil then
            Last = Value
            local Beyond = Strict and Distance < EntryDistance or not Strict and Distance <= EntryDistance
            if Beyond then return Value end
        end
    end
    return Last
end

--- Damage at a distance in meters using the native falloff band semantics
--- (first DamageDistanceArray entry whose distance is >= the shot, else the
--- last entry).
---@param Raw table? # Weapons.Raw() result
---@param Meters number
---@return number? damage
function Weapons.DamageAtDistance(Raw, Meters)
    if type(Meters) ~= "number" then return nil end
    local Entries = Raw ~= nil and Raw.Damage ~= nil and Raw.Damage.DamageDistance or nil
    return BandAtDistance(Entries, "Damage", Meters, false)
end

--- Critical-damage multiplier at a distance in meters using the native strict
--- band semantics (first CriticalDamageMultiplierDistanceArray entry whose
--- distance is strictly greater than the shot, else the last entry).
---@param Raw table? # Weapons.Raw() result
---@param Meters number
---@return number? multiplier
function Weapons.CritMultiplierAtDistance(Raw, Meters)
    if type(Meters) ~= "number" then return nil end
    local Entries = Raw ~= nil and Raw.Damage ~= nil and Raw.Damage.CriticalDamageMultiplierDistance or nil
    return BandAtDistance(Entries, "Multiplier", Meters, true)
end

--- Modular slots of a weapon; entries are
--- { Slot, SlotName, DefaultPart, UniqueParts, SharedParts }.
--- SharedParts flattens USBZSharedPartList assets into their part assets.
---@param Weapon any
---@return table[] slots
function Weapons.Parts(Weapon)
    local Live = Weapons.Resolve(Weapon)
    local Result = {}
    if Live == nil then return Result end
    local Config = Safe.Resolve(Safe.Get(Live, "ModularConfiguration"))
    if Config == nil then return Result end

    Maps.ForEach(Config, function(Slot, SlotConfig)
        local SlotData = Safe.Resolve(SlotConfig)
        local Entry = {
            Slot = Slot,
            SlotName = ObjectName(Slot),
            DefaultPart = AsObject(Safe.Get(SlotData, "DefaultPart")),
            UniqueParts = ObjectArray(SlotData, "UniqueModParts"),
            SharedParts = {},
        }
        for _, List in ipairs(ObjectArray(SlotData, "SharedParts")) do
            for _, Part in ipairs(ObjectArray(List, "SharedModParts")) do
                Entry.SharedParts[#Entry.SharedParts + 1] = Part
            end
        end
        Result[#Result + 1] = Entry
    end)
    return Result
end

--- Attribute modifiers of one weapon part asset.
---@param Part any
---@return table? info
function Weapons.PartInfo(Part)
    local Live = AsObject(Part)
    if Live == nil then return nil end
    local Info = {
        Name = ObjectName(Live),
        Path = ObjectPath(Live),
        Modifiers = {},
    }
    Maps.ForEach(Safe.Resolve(Safe.Get(Live, "AttributeModifierMap")), function(Key, Value)
        local Name = Weapons.AttributeName(Key)
        local Modifier = NumOf(Value)
        if Modifier ~= nil then
            Info.Modifiers[Name] = Modifier
        end
    end)
    return Info
end

--- Attribute curve rows: { Source, Live, Rows }. Rows[name] is
--- { Keys = { {Time, Value}, ... }, DefaultValue }. Prefers the live
--- CT_ModData_Default TMap and falls back to the generated table.
---@param Refresh? boolean # bypass the per-session cache
---@return table curves
function Weapons.AttributeCurves(Refresh)
    if Weapons._Curves ~= nil and not Refresh then return Weapons._Curves end

    local Rows, Live = nil, false
    local OkFind, Table = Pcall("StaticFindObject curve table", StaticFindObject, Weapons.CurveTablePath)
    if OkFind and Safe.IsValid(Table) then
        local Attempt = {}
        local Count = 0
        Maps.ForEach(Safe.Resolve(Safe.Get(Table, "RowMap")), function(Key, Value)
            local Name = Safe.String(Key)
            local Curve = Safe.Resolve(Value)
            local Keys = Safe.Get(Curve, "Keys")
            local KeyCount = Safe.ArrayCount(Keys)
            if Name ~= nil and Name ~= "nil" and KeyCount ~= nil and KeyCount > 0 then
                local Points = {}
                for Index = 1, KeyCount do
                    local OkKey, Element = Pcall("curve key", function() return Keys[Index] end)
                    if OkKey and Element ~= nil then
                        local Time = NumOf(Safe.Get(Element, "Time"))
                        local ValueAt = NumOf(Safe.Get(Element, "Value"))
                        if Time ~= nil and ValueAt ~= nil then
                            Points[#Points + 1] = { Time, ValueAt }
                        end
                    end
                end
                if #Points > 0 then
                    local Default = NumOf(Safe.Get(Curve, "DefaultValue"))
                    if Default == Weapons.NoValue then Default = nil end
                    Attempt[Name] = {
                        Keys = Points,
                        DefaultValue = Default,
                    }
                    Count = Count + 1
                end
            end
        end)
        if Count >= 10 then
            Rows, Live = Attempt, true
        end
    end

    Weapons._Curves = {
        Source = Weapons.CurveTablePath,
        Live = Live,
        Rows = Rows or CurvesFallback.Rows,
    }
    return Weapons._Curves
end

--- Linear interpolation over a curve row; constant extrapolation outside keys.
---@param RowNameOrRow string|table
---@param X number
---@param Curves? table # defaults to Weapons.AttributeCurves()
---@return number? value
function Weapons.CurveValue(RowNameOrRow, X, Curves)
    local Row = RowNameOrRow
    if type(RowNameOrRow) == "string" then
        Row = (Curves or Weapons.AttributeCurves()).Rows[RowNameOrRow]
    end
    if type(Row) ~= "table" or type(Row.Keys) ~= "table" or #Row.Keys == 0 then return nil end
    if type(X) ~= "number" then return nil end

    local Keys = Row.Keys
    if X <= Keys[1][1] then return Keys[1][2] end
    local Last = Keys[#Keys]
    if X >= Last[1] then return Last[2] end

    for Index = 1, #Keys - 1 do
        local A, B = Keys[Index], Keys[Index + 1]
        if X >= A[1] and X <= B[1] then
            local Span = B[1] - A[1]
            if Span == 0 then return B[2] end
            local Alpha = (X - A[1]) / Span
            return A[2] + (B[2] - A[2]) * Alpha
        end
    end
    if Row.DefaultValue ~= nil and Row.DefaultValue ~= Weapons.NoValue then
        return Row.DefaultValue
    end
    return nil
end

--- Curve output for one attribute at a modifier value, e.g.
--- Weapons.AttributeValue("OverallSwapSpeed", 40).
---@param Attribute string
---@param Modifier number
---@return number? value
function Weapons.AttributeValue(Attribute, Modifier)
    return Weapons.CurveValue(Attribute, Modifier)
end

--- Parent attribute -> child attributes. Used to expand attachment modifiers
--- such as OverallSwapSpeed into the concrete child attributes whose curves
--- are evaluated. Live map first (settings CDO), static fallback second.
---@type table<string, string[]>
Weapons.ParentFallback = {
    OverallRecoil = { "VerticalRecoil", "HorizontalRecoil", "InitialRecoil", "ViewKickRecoverySpeed", "ViewKickRecoveryDelay" },
    OverallSpread = { "HipfireSpread", "TargetingSpread", "SpreadIncrement", "VerticalSpreadRadius", "HorizontalSpreadRadius" },
    OverallGunkick = { "VerticalGunkick", "HorizontalGunkick", "ScreenShakeAmplitude", "GunKickBackDistance", "OverallPelletDeviation" },
    OverallSwapSpeed = { "EquipPlayRate", "UnequipPlayRate", "SprintExitPlayRate" },
    OverallSpreadRadius = { "VerticalSpreadRadius", "HorizontalSpreadRadius" },
    OverallHurtBuildup = { "HurtBuildup", "CriticalHurtBuildup", "HurtBuildupMultiplier" },
}

--- Attribute identifiers from SBZWeaponModificationSettings.Settings
--- (AttributeIdentifierMap): the game's own DisplayName / Context plus the
--- child attributes per attribute.
---@param Refresh? boolean
---@return table<string, table> identifiers # name -> { Attribute, Name, Context, DisplayName, IsParent, Children }
function Weapons.AttributeIdentifiers(Refresh)
    if Weapons._Identifiers ~= nil and not Refresh then return Weapons._Identifiers end

    local Result = {}
    local OkFind, Settings = Pcall("StaticFindObject settings", StaticFindObject, Weapons.ModificationSettingsPath)
    if OkFind and Safe.IsValid(Settings) then
        local Data = Safe.Resolve(Safe.Get(Settings, "Settings"))
        Maps.ForEach(Safe.Resolve(Safe.Get(Data, "AttributeIdentifierMap")), function(Key, Value)
            local Entry = Safe.Resolve(Value)
            local Name = Safe.String(Safe.Get(Entry, "Name"))
            if Name == nil or Name == "" or Name == "nil" then
                Name = Weapons.AttributeName(Key)
            end
            local Children = {}
            local Array = Safe.Get(Entry, "ChildAttributeArray")
            local Count = Safe.ArrayCount(Array)
            if Count ~= nil then
                for Index = 1, Count do
                    local Ok, Element = Pcall("array element", function() return Array[Index] end)
                    if Ok then Children[#Children + 1] = Weapons.AttributeName(Element) end
                end
            end
            Result[Name] = {
                Attribute = Weapons.AttributeName(Key),
                Name = Name,
                Context = Safe.String(Safe.Get(Entry, "Context")),
                DisplayName = Safe.Text(Safe.Get(Entry, "DisplayName")),
                IsParent = BoolOf(Safe.Get(Entry, "bIsParent")) == true,
                Children = Children,
            }
        end)
    end

    Weapons._Identifiers = Result
    return Result
end

--- Reads the parent attribute map from SBZWeaponModificationSettings.Settings
--- (AttributeIdentifierMap) and merges the static fallback for missing parents.
---@param Refresh? boolean
---@return table<string, string[]> parents
function Weapons.AttributeParents(Refresh)
    if Weapons._Parents ~= nil and not Refresh then return Weapons._Parents end

    local Result = {}
    for Name, Entry in pairs(Weapons.AttributeIdentifiers(Refresh)) do
        if #Entry.Children > 0 then Result[Name] = Entry.Children end
    end

    for Parent, Children in pairs(Weapons.ParentFallback) do
        if Result[Parent] == nil then Result[Parent] = Children end
    end

    Weapons._Parents = Result
    return Result
end

--- Expands attribute modifiers into per-child curve multipliers. Parent
--- attributes (Overall*) are expanded through AttributeParents; concrete
--- attributes evaluate their own curve.
---@param Modifiers table<string, number>
---@param Curves? table # defaults to Weapons.AttributeCurves()
---@return table<string, number> multipliers # child attribute -> multiplier
---@return table<string, table> details # attribute -> { Children, Multipliers, Product }
function Weapons.ModifierMultipliers(Modifiers, Curves)
    local Parents = Weapons.AttributeParents()
    local Result, Details = {}, {}

    for Attribute, Modifier in pairs(Modifiers or {}) do
        local Children = Parents[Attribute]
        local Entry = { Children = {}, Multipliers = {}, Product = 1 }
        if Children ~= nil then
            for _, Child in ipairs(Children) do
                local Value = Weapons.CurveValue(Child, Modifier, Curves)
                if Value ~= nil then
                    Entry.Children[#Entry.Children + 1] = Child
                    Entry.Multipliers[Child] = Value
                    Result[Child] = (Result[Child] or 1) * Value
                    Entry.Product = Entry.Product * Value
                end
            end
        else
            local Value = Weapons.CurveValue(Attribute, Modifier, Curves)
            if Value ~= nil then
                Entry.Children[1] = Attribute
                Entry.Multipliers[Attribute] = Value
                Result[Attribute] = (Result[Attribute] or 1) * Value
                Entry.Product = Value
            end
        end
        Details[Attribute] = Entry
    end

    return Result, Details
end

--- Loaded SBZUIWeaponStatsAsset instances. The cooked build leaves the
--- settings soft path unset and UE4SS crashes wrapping that TSoftObjectPtr,
--- so only already-loaded instances are considered (none by default).
---@return UObject? asset
---@return string? err
function Weapons.UiStatsAsset()
    if Safe.IsValid(Weapons._UiAsset) then return Weapons._UiAsset end

    for _, Asset in ipairs(World.FindAll("SBZUIWeaponStatsAsset")) do
        if Safe.IsValid(Asset) then
            local Path = ObjectPath(Asset) or ""
            if not string.find(Path, "Default__", 1, true) then
                Weapons._UiAsset = Asset
                return Asset
            end
        end
    end
    return nil, "no SBZUIWeaponStatsAsset loaded (unset in the cooked build)"
end

--- Raw normalization weights of the UI stats asset; one entry per stat bar
--- with the MeanInputArray / VarianceInputArray / WeightHiddenArray /
--- BiasHiddenArray / WeightOutputArray / BiasOutputArray arrays.
---@return table[]? weights
---@return string? err
function Weapons.UiWeights()
    local Asset, Err = Weapons.UiStatsAsset()
    if Asset == nil then return nil, Err end
    local Containers = Safe.Get(Asset, "StatWeightContainerArray")

    local IsArray = type(Containers) == "table" and Containers[1] ~= nil
    if not IsArray and Containers ~= nil then
        local OkNum, Num = pcall(function() return Containers:GetArrayNum() end)
        IsArray = OkNum and type(Num) == "number"
    end
    if not IsArray then
        return nil, "StatWeightContainerArray is an opaque struct array (weights unavailable)"
    end

    local Count = Safe.ArrayCount(Containers)
    if Count == nil then return nil, "StatWeightContainerArray unreadable" end

    local StatNames = { "Damage", "Recoil", "Stability", "Accuracy", "Handling", "FireRate" }
    local Fields = {
        "MeanInputArray", "VarianceInputArray", "WeightHiddenArray",
        "BiasHiddenArray", "WeightOutputArray", "BiasOutputArray",
    }
    local Result = {}
    for Index = 1, math.min(Count, 12) do
        local Ok, Element = Pcall("weight container", function() return Containers[Index] end)
        if Ok and Element ~= nil then
            local Entry = { Index = Index, Stat = StatNames[Index] }
            for _, Field in ipairs(Fields) do
                Entry[Field] = NumberArray(Safe.Get(Element, Field))
            end
            Result[#Result + 1] = Entry
        end
    end
    return Result
end

--- Calls the game's own SBZUIWeaponStatsBlueprint value-array getters, the
--- canonical 0..100 bar computation (includes hidden inputs).
---@param Weapon any
---@return table? bars # { Damage = {..}, Recoil = {..}, ... }, Mode = "blueprint"
---@return string? err
function Weapons.UiStats(Weapon)
    local Live = Weapons.Resolve(Weapon)
    if Live == nil then return nil, "weapon unresolved" end

    local Asset, Err = Weapons.UiStatsAsset()
    if Asset == nil then return nil, Err end

    local Class = AsObject(Safe.Get(Asset, "WeaponStatsBlueprintClass"))
    if Class == nil then return nil, "WeaponStatsBlueprintClass unset" end

    local ClassPath = ObjectPath(Class)
    local Package, ClassName = string.match(ClassPath or "", "^(.*)%.([^.]+)$")
    local Cdo = nil
    if Package ~= nil and ClassName ~= nil then
        local OkCdo, Found = Pcall("StaticFindObject blueprint CDO", StaticFindObject, Package .. ".Default__" .. ClassName)
        if OkCdo and Safe.IsValid(Found) then Cdo = Found end
    end
    if Cdo == nil then return nil, "blueprint CDO not found for " .. tostring(ClassPath) end

    local Getters = {
        { "Damage", "GetDamageValueArray" },
        { "Recoil", "GetRecoilValueArray" },
        { "Stability", "GetStabilityValueArray" },
        { "Accuracy", "GetAccuracyValueArray" },
        { "Handling", "GetHandlingValueArray" },
        { "FireRate", "GetFireRateValueArray" },
    }
    local Bars = { Mode = "blueprint" }
    local Any = false
    for _, Entry in ipairs(Getters) do
        local Out = {}
        local OkCall, Returned = Safe.CallFn(Cdo, Entry[2], Live, Out)
        local Values = NumberArray(Out)
        if (Values == nil or #Values == 0) and type(Returned) == "table" then
            Values = NumberArray(Returned)
        end
        if Values ~= nil and #Values > 0 then
            Bars[Entry[1]] = Values
            Any = true
        end
    end
    if not Any then return nil, "blueprint getters returned no values" end
    return Bars
end

--- Reducer per stat bar used by BarsApprox: "first", "last" or "max".
---@type table<string, string>
Weapons.BarReducers = {
    Damage = "max", Recoil = "max", Stability = "max",
    Accuracy = "max", Handling = "max", FireRate = "first",
}

---@param Values number[]?
---@param Reducer string
---@return number? value
local function ReduceValues(Values, Reducer)
    if Values == nil or #Values == 0 then return nil end
    if Reducer == "first" then return Values[1] end
    if Reducer == "last" then return Values[#Values] end
    local Best = Values[1]
    for Index = 2, #Values do
        if Values[Index] > Best then Best = Values[Index] end
    end
    return Best
end

--- Min/max of each reduced bar across all loaded weapons (cached per session).
---@param Refresh? boolean
---@return table<string, { Min: number, Max: number }> ranges
---@return integer samples # weapons whose UI stats were readable
function Weapons.BarRanges(Refresh)
    if Weapons._BarRanges ~= nil and not Refresh then return Weapons._BarRanges, Weapons._BarSamples end

    local Ranges, Samples = {}, 0
    for _, Entry in ipairs(Weapons.All()) do
        local Bars = Weapons.UiStats(Entry.Object)
        if Bars ~= nil then
            Samples = Samples + 1
            for Stat, Reducer in pairs(Weapons.BarReducers) do
                local Value = ReduceValues(Bars[Stat], Reducer)
                if Value ~= nil then
                    local Range = Ranges[Stat]
                    if Range == nil then
                        Ranges[Stat] = { Min = Value, Max = Value }
                    else
                        if Value < Range.Min then Range.Min = Value end
                        if Value > Range.Max then Range.Max = Value end
                    end
                end
            end
        end
    end

    Weapons._BarRanges = Ranges
    Weapons._BarSamples = Samples
    return Ranges, Samples
end

--- Approximate 0..100 bars used when the game-computed widget values are
--- unavailable: each raw UI array is reduced (BarReducers) and normalized
--- between the min and max across all loaded weapons. Deltas stay comparable
--- between weapons, absolute values only approximate the game's own bars.
---@param Weapon any
---@param Refresh? boolean
---@return table? bars # { Damage = number, ..., Raw = table, Source = "approx", Samples = integer }
---@return string? err
function Weapons.BarsApprox(Weapon, Refresh)
    local Live = Weapons.Resolve(Weapon)
    if Live == nil then return nil, "weapon unresolved" end

    local Ui, Err = Weapons.UiStats(Live)
    if Ui == nil then return nil, Err end

    local Ranges, Samples = Weapons.BarRanges(Refresh)
    local Bars = { Raw = {}, Source = "approx", Samples = Samples }
    local Any = false
    for Stat, Reducer in pairs(Weapons.BarReducers) do
        local Value = ReduceValues(Ui[Stat], Reducer)
        if Value ~= nil then
            Bars.Raw[Stat] = Value
            local Range = Ranges[Stat]
            if Range ~= nil and Range.Max > Range.Min then
                local Percent = 100 * (Value - Range.Min) / (Range.Max - Range.Min)
                Bars[Stat] = math.max(0, math.min(100, Percent))
                Any = true
            end
        end
    end
    if not Any then return nil, "no comparable bar ranges (UI stats asset not loaded?)" end
    return Bars
end

--- Reflection dump of the weapon and its key sub-assets.
---@param Weapon any
---@param Opts? pd3.Reflect.Options
function Weapons.Dump(Weapon, Opts)
    local Live = Weapons.Resolve(Weapon)
    if Live == nil then return end
    Reflect.DumpProperties(Live, Opts)
    local Sub = Weapons.Subobjects(Live)
    for _, Name in ipairs({ "Fire", "Spread", "Recoil", "Targeting", "Sway", "Tanking", "WallReaction", "DOF" }) do
        local Object = Sub[Name]
        if Object ~= nil then
            Reflect.DumpProperties(Object, Opts)
        end
    end
end

--- Encodes a plain Lua value (numbers, strings, booleans, nested tables) as JSON.
---@param Value any
---@param Indent? integer
---@return string json
function Weapons.Json(Value, Indent)
    Indent = Indent or 0
    local Pad = string.rep("  ", Indent)
    local NextPad = string.rep("  ", Indent + 1)

    if type(Value) == "number" then
        if Value ~= Value or Value == math.huge or Value == -math.huge then return "null" end
        return tostring(Value)
    end
    if type(Value) == "string" then
        return string.format("%q", Value)
    end
    if type(Value) == "boolean" or Value == nil then
        return tostring(Value)
    end
    if type(Value) ~= "table" then
        return string.format("%q", Safe.String(Value))
    end

    local Count = #Value
    local IsArray = Count > 0
    if IsArray then
        local Seen = 0
        for Key in pairs(Value) do
            if type(Key) ~= "number" or Key < 1 or Key ~= math.floor(Key) then
                IsArray = false
                break
            end
            Seen = Seen + 1
        end
        if IsArray and Seen ~= Count then IsArray = false end
    elseif next(Value) == nil then
        return "[]"
    end

    local Parts = {}
    if IsArray then
        for _, Element in ipairs(Value) do
            Parts[#Parts + 1] = NextPad .. Weapons.Json(Element, Indent + 1)
        end
        if #Parts == 0 then return "[]" end
        return "[\n" .. table.concat(Parts, ",\n") .. "\n" .. Pad .. "]"
    end

    local Keys = {}
    for Key in pairs(Value) do Keys[#Keys + 1] = Key end
    table.sort(Keys, function(A, B) return tostring(A) < tostring(B) end)
    for _, Key in ipairs(Keys) do
        Parts[#Parts + 1] = string.format("%s%q: %s", NextPad, tostring(Key), Weapons.Json(Value[Key], Indent + 1))
    end
    if #Parts == 0 then return "{}" end
    return "{\n" .. table.concat(Parts, ",\n") .. "\n" .. Pad .. "}"
end

--- Writes Value as JSON to Path (absolute or writable relative path).
---@param Value any
---@param Path string
---@return boolean ok
---@return string? err
function Weapons.WriteJson(Value, Path)
    local File, Err = io.open(Path, "w")
    if File == nil then return false, tostring(Err) end
    File:write(Weapons.Json(Value, 0))
    File:close()
    return true
end

return Weapons
