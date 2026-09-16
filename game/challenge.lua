--- Challenge / achievement access (BP_ChallengeManager_C, SBZAchievementManager).
---
--- Status flips do not refresh in the local ChallengeMap mid-session; the
--- platform (Steam/console) is authoritative. Forced completion bypasses the
--- stat requirement entirely. Do not call GetStatProgress - it freezes the
--- game thread for unknown stat ids (read criteria assets instead).
---@class pd3.Challenge
local Challenge = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local Maps = require("pd3lib.core.maps")
local World = require("pd3lib.core.world")
local Reflect = require("pd3lib.core.reflect")

--- Short class name of the challenge manager subclass.
---@type string
Challenge.ManagerClassName = "BP_ChallengeManager_C"
--- Short class name of the achievement manager.
---@type string
Challenge.AchievementManagerClassName = "SBZAchievementManager"
--- CDO path of the challenge -> achievement settings object.
---@type string
Challenge.SettingsClassPath = "/Script/Starbreeze.Default__SBZChallengeToAchievementSettings"

--- ESBZChallengeStatus index -> name.
---@type table<integer, string>
Challenge.StatusNames = {
    [0] = "INIT",
    [1] = "INPROGRESS",
    [2] = "COMPLETED",
    [3] = "UNAVAILABLE",
}
--- ChallengeStatus value meaning COMPLETED.
---@type integer
Challenge.CompletedStatus = 2

--- FindAllOf can include the class default object; skip it.
---@param ClassName string
---@return UObject? instance
---@return string? fullName
local function FindLive(ClassName)
    return World.FindLive(ClassName)
end

--- Live BP_ChallengeManager_C instance.
---@return UObject? challengeManager
---@return string? fullName
function Challenge.Manager()
    return FindLive(Challenge.ManagerClassName)
end

--- Live SBZAchievementManager instance.
---@return UObject? achievementManager
---@return string? fullName
function Challenge.AchievementManager()
    return FindLive(Challenge.AchievementManagerClassName)
end

--- Name for an ESBZChallengeStatus value.
---@param Value any # non-numbers are tostring'ed as-is
---@return string name # "Unknown(n)" when unmapped
function Challenge.StatusName(Value)
    if type(Value) ~= "number" then return tostring(Value) end
    return Challenge.StatusNames[Value] or ("Unknown(" .. Value .. ")")
end

--- Reads and resolves one manager map property.
---@param Manager UObject?
---@param PropertyName string
---@return any map # TMap wrapper or nil
local function ReadMap(Manager, PropertyName)
    if Manager == nil then return nil end
    return Safe.Resolve(Safe.Get(Manager, PropertyName))
end

--- The AchievementMap (TMap<FName, FSBZChallengeData>) of a manager.
---@param Manager? UObject # defaults to Challenge.Manager()
---@return TMap<any, any>? map
function Challenge.Achievements(Manager)
    return ReadMap(Manager or Challenge.Manager(), "AchievementMap")
end

--- The ChallengeMap (TMap<FName, FSBZChallengeData>) of a manager.
---@param Manager? UObject # defaults to Challenge.Manager()
---@return TMap<any, any>? map
function Challenge.AllChallenges(Manager)
    return ReadMap(Manager or Challenge.Manager(), "ChallengeMap")
end

--- Flattened view of one FSBZChallengeData map entry. Record fields are plain
--- struct copies; string wrappers are resolved.
---@class pd3.Challenge.RecordSummary
---@field Key string # map key (hashed FName, resolved)
---@field ChallengeId string
---@field ChallengeName string # human-readable, e.g. "Achievement Steam Penthouse Human Shield Extract"
---@field Status any # ESBZChallengeStatus value (number wrapper until read via StatusName)
---@field TotalProgress any
---@field TotalTarget any
---@field Record any # the raw FSBZChallengeData value

--- Converts a map entry into a pd3.Challenge.RecordSummary.
---@param Key any # map key wrapper
---@param Value any # FSBZChallengeData struct value
---@return pd3.Challenge.RecordSummary summary
local function RecordSummary(Key, Value)
    local Record = Safe.Resolve(Value)
    return {
        Key = Safe.String(Key),
        ChallengeId = Safe.String(Safe.Get(Record, "ChallengeId")),
        ChallengeName = Safe.String(Safe.Get(Record, "ChallengeName")),
        Status = Safe.Get(Record, "ChallengeStatus"),
        TotalProgress = Safe.Get(Record, "TotalProgress"),
        TotalTarget = Safe.Get(Record, "TotalTarget"),
        Record = Record,
    }
end

Challenge.RecordSummary = RecordSummary

--- Case-insensitive substring match over id/name/key.
---@param Summary pd3.Challenge.RecordSummary
---@param Needle string
---@return boolean
local function Matches(Summary, Needle)
    local Lower = string.lower(Needle)
    return string.find(string.lower(Summary.ChallengeId), Lower, 1, true) ~= nil
        or string.find(string.lower(Summary.ChallengeName), Lower, 1, true) ~= nil
        or string.find(string.lower(Summary.Key), Lower, 1, true) ~= nil
end

--- Returns a list of summaries whose id/name/key contains Needle (case-insensitive).
---@param Manager? UObject # defaults to Challenge.Manager()
---@param Needle string
---@return pd3.Challenge.RecordSummary[] found
function Challenge.Find(Manager, Needle)
    local Map = Challenge.Achievements(Manager)
    local Found = {}
    if Map == nil then return Found end
    Maps.ForEach(Map, function(Key, Value)
        local Summary = RecordSummary(Key, Value)
        if Matches(Summary, Needle) then Found[#Found + 1] = Summary end
    end)
    return Found
end

--- True when any entry matching Needle has status COMPLETED(2).
---@param Manager? UObject # defaults to Challenge.Manager()
---@param Needle string
---@return boolean completed
---@return pd3.Challenge.RecordSummary? summary # the completed entry
function Challenge.IsCompleted(Manager, Needle)
    for _, Summary in ipairs(Challenge.Find(Manager, Needle)) do
        if Summary.Status == Challenge.CompletedStatus then
            return true, Summary
        end
    end
    return false, nil
end

--- Challenge FName -> AccelByte code (e.g. "ACH_*") via the settings CDO property.
--- Reading the property is safe; SBZChallengeToAchievementSettings:
--- GetChallengeToAchievementSettings() returns a TMap by value and holding that
--- copy is suspect (see docs: by-value returns). Match is case-insensitive.
---@param ChallengeName string
---@return string? code
function Challenge.CodeFor(ChallengeName)
    local OkFind, Settings = pcall(StaticFindObject, Challenge.SettingsClassPath)
    if not OkFind or not Safe.IsValid(Settings) then return nil end

    local Map = Safe.Resolve(Safe.Get(Settings, "ChallengeToAchievementMap"))
    if Map == nil then return nil end

    local Target = string.lower(ChallengeName)
    local Found = nil
    Maps.ForEach(Map, function(Key, Value)
        if Found == nil and string.lower(Safe.String(Key)) == Target then
            Found = Safe.String(Value)
        end
    end)
    return Found
end

--- Calls the game's own completion path: SBZAchievementManager:CompleteAchievement.
--- AchievementId is typically the AchievementMap key (hashed FName), an
--- AccelByte code such as ACH_*, or a challenge name. Lua strings are
--- pre-converted with Safe.ToFName because this UE4SS build crashes argument
--- marshalling for Lua string -> FName.
---@param AchievementId any # string or pre-built FName
---@return boolean ok
---@return any err # error detail when ok=false ("no achievement manager", "fname not in pool")
function Challenge.Complete(AchievementId)
    local Manager = Challenge.AchievementManager()
    if Manager == nil then
        Log.Warn("challenge.Complete: no live %s", Challenge.AchievementManagerClassName)
        return false, "no achievement manager"
    end

    local Id = AchievementId
    if type(Id) == "string" then
        local FName = Safe.ToFName(Id)
        if FName == nil then
            Log.Warn("challenge.Complete: '%s' is not in the FName pool", Id)
            return false, "fname not in pool"
        end
        Id = FName
    end

    local Ok, Err = Safe.CallFn(Manager, "CompleteAchievement", Id)
    Log.Info("challenge.Complete(%s) ok=%s err=%s", tostring(AchievementId), tostring(Ok), Safe.String(Err))
    return Ok, Err
end

--- Logs a one-line summary of an FSBZChallengeData record (map value).
---@param Label string
---@param Record any # FSBZChallengeData value (wrapper or table)
function Challenge.DumpRecord(Label, Record)
    if Record == nil then
        Log.Warn("%s: nil record", Label)
        return
    end
    Log.Info("%s: ChallengeId=%s ChallengeName=%s Status=%s Progress=%s/%s Active=%s",
        Label,
        Safe.String(Safe.Resolve(Safe.Get(Record, "ChallengeId"))),
        Safe.String(Safe.Resolve(Safe.Get(Record, "ChallengeName"))),
        Challenge.StatusName(Safe.Num(Safe.Get(Record, "ChallengeStatus"), -1)),
        Safe.String(Safe.Resolve(Safe.Get(Record, "TotalProgress"))),
        Safe.String(Safe.Resolve(Safe.Get(Record, "TotalTarget"))),
        Safe.String(Safe.Resolve(Safe.Get(Record, "IsActive"))))
end

--- Dumps the current stat map (registered internal stats) using reflection.
---@param Manager? UObject # defaults to Challenge.Manager()
---@param MaxEntries? integer # default 25
---@param Opts? pd3.Reflect.Options # forwarded to Reflect.DumpStruct
function Challenge.DumpStatMap(Manager, MaxEntries, Opts)
    local Map = Safe.Resolve(Safe.Get(Manager or Challenge.Manager(), "StatMap"))
    if Map == nil then
        Log.Warn("challenge.DumpStatMap: StatMap unreadable")
        return
    end
    local Limit = MaxEntries or 25
    local Shown = 0
    Maps.ForEach(Map, function(Key, Value)
        Shown = Shown + 1
        if Shown <= Limit then
            Log.Info("stat[%d] %s", Shown, Safe.String(Key))
            Reflect.DumpStruct(Value, "SBZInternalStatData", Opts)
        end
    end)
    Log.Info("challenge.DumpStatMap: %d entries (shown %d)", Shown, math.min(Shown, Limit))
end

--- ChallengeRecordCaches wraps as an opaque TrivialObject on this build; this
--- reports what is readable instead of failing.
---@param Manager? UObject # defaults to Challenge.Manager()
function Challenge.DumpCaches(Manager)
    local Caches = Safe.Get(Manager or Challenge.Manager(), "ChallengeRecordCaches")
    local Count = Safe.ArrayCount(Caches)
    Log.Info("challenge.DumpCaches: %s (%s)", Safe.Describe(Caches), Count ~= nil and (Count .. " entries") or "count unreadable")
end

return Challenge
