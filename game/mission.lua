--- Mission state snapshot (SBZMissionState) and criterion reflection dumps.
---@class pd3.Mission
local Mission = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Reflect = require("pd3lib.core.reflect")

--- Short class name of the live mission state object.
---@type string
Mission.ClassName = "SBZMissionState"

--- ESBZDifficulty index -> name.
---@type table<integer, string>
Mission.DifficultyNames = {
    [0] = "Normal",
    [1] = "Hard",
    [2] = "VeryHard",
    [3] = "Overkill",
}

--- PD3 heist state index -> name.
---@type table<integer, string>
Mission.HeistStateNames = {
    [0] = "Stealth",
    [1] = "Search",
    [2] = "Alarm",
    [3] = "FirstResponse",
    [4] = "Negotiation",
    [5] = "Anticipation",
    [6] = "Assault",
    [7] = "Control",
    [8] = "PointOfNoReturn",
}

--- Live SBZMissionState (nil in menus).
---@return UObject? state
---@return string? fullName
function Mission.Get()
    return World.FindLive(Mission.ClassName)
end

--- Mission difficulty value and display name.
---@param State? UObject # defaults to Mission.Get()
---@return integer? value # ESBZDifficulty
---@return string? name # "Unknown(n)" when unmapped
function Mission.Difficulty(State)
    local Value = Safe.Get(State or Mission.Get(), "Difficulty")
    if type(Value) ~= "number" then return nil end
    return Value, Mission.DifficultyNames[Value] or ("Unknown(" .. Value .. ")")
end

--- The mission's CurrentHeistData object.
---@param State? UObject # defaults to Mission.Get()
---@return UObject? heistData
function Mission.HeistData(State)
    return Safe.Get(State or Mission.Get(), "CurrentHeistData")
end

--- Heist reference is a short token such as "penthouse"; the level name
--- ("Sky") is different and comes from core.world.GetLevelName. Gate on this.
---@param State? UObject # defaults to Mission.Get()
---@return string? heistRef
function Mission.HeistRef(State)
    local HeistData = Mission.HeistData(State)
    if not Safe.IsValid(HeistData) then return nil end
    local Ok, Ref = Safe.CallFn(HeistData, "GetHeistReferenceText")
    if not Ok then return nil end
    return Safe.String(Ref)
end

--- Escape volume snapshot.
---@class pd3.Mission.Escape
---@field TimeLeft number # EscapeTimeLeft, 0 when unreadable
---@field PlayersIn number # PlayersInEscapeVolume, 0 when unreadable
---@field PlayersRequired number # PlayersRequiredInEscapeVolume, 0 when unreadable

--- Current escape state (zeros outside an escape).
---@param State? UObject # defaults to Mission.Get()
---@return pd3.Mission.Escape escape
function Mission.Escape(State)
    local Live = State or Mission.Get()
    return {
        TimeLeft = Safe.Num(Safe.Get(Live, "EscapeTimeLeft"), 0),
        PlayersIn = Safe.Num(Safe.Get(Live, "PlayersInEscapeVolume"), 0),
        PlayersRequired = Safe.Num(Safe.Get(Live, "PlayersRequiredInEscapeVolume"), 0),
    }
end

--- Reads one entry of SBZMissionState.StatisticsCriteriaDataCollection,
--- e.g. Mission.Criterion("InsurancePolicy"). Returns nil outside a mission.
---@param CriteriaName string
---@return UObject? criterion # SBZStatisticCriteriaData
function Mission.Criterion(CriteriaName)
    local State = Mission.Get()
    if State == nil then return nil end
    local Collection = Safe.Resolve(Safe.Get(State, "StatisticsCriteriaDataCollection"))
    return Safe.Resolve(Safe.Get(Collection, CriteriaName))
end

--- Reflection dumps for update-proof re-discovery.
---@param Criteria any? # SBZStatisticCriteriaData; nil is a no-op
---@param Opts? pd3.Reflect.Options
function Mission.DumpCriterion(Criteria, Opts)
    if Criteria == nil then return end
    Reflect.DumpStruct(Criteria, "SBZStatisticCriteriaData", Opts)
end

--- Dumps a heist data object's reflected properties.
---@param HeistData any? # nil is a no-op
---@param Opts? pd3.Reflect.Options
function Mission.DumpHeistData(HeistData, Opts)
    if HeistData == nil then return end
    Reflect.DumpProperties(HeistData, Opts)
end

--- Dumps the mission's CurrentMissionResultData (SBZEndMissionResultData).
---@param State? UObject # defaults to Mission.Get()
---@param Opts? pd3.Reflect.Options
function Mission.DumpMissionResult(State, Opts)
    local Live = State or Mission.Get()
    if Live == nil then return end
    local Result = Safe.Get(Live, "CurrentMissionResultData")
    if Result == nil then return end
    Reflect.DumpStruct(Result, "SBZEndMissionResultData", Opts)
end

return Mission
