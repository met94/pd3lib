--- World/player accessors with caching. All lookups are pcall-guarded and
--- return nil (or an empty table) instead of raising.
---@class pd3.World
local World = {}

local Safe = require("pd3lib.core.safe")
local Log = require("pd3lib.core.log")

local PlayerControllerCache = nil

--- True when the controller resolves to a live Pawn.
---@param Controller any
---@return boolean
local function HasPawn(Controller)
    if not Safe.IsValid(Controller) then return false end
    return Safe.IsValid(Safe.Get(Controller, "Pawn"))
end

--- True when the controller says it is the local one; a missing or raising
--- `IsLocalController` counts as not local.
---@param Controller any
---@return boolean
local function IsLocal(Controller)
    local Ok, Value = Safe.CallFn(Controller, "IsLocalController")
    return Ok and Value == true
end

--- Resolution score: 3 local with a live pawn (the only usable one for spawn
--- and weapon reads), 2 local without (PlayerState/chat), 1 pawned non-local,
--- 0 any other valid controller (menu/loading fallback).
---@param Controller any
---@return integer
local function ControllerScore(Controller)
    local Local = IsLocal(Controller)
    local Pawned = HasPawn(Controller)
    if Local then return Pawned and 3 or 2 end
    if Pawned then return 1 end
    return 0
end

--- Best live controller of the current object list; second return is its score
--- (-1 when the list holds no valid controller).
---@return UObject? controller
---@return integer score
local function FindController()
    local Controllers = World.FindAll("PlayerController")
    if #Controllers == 0 then Controllers = World.FindAll("Controller") end

    local Best, BestScore = nil, -1
    for _, Controller in ipairs(Controllers) do
        if Safe.IsValid(Controller) then
            local Score = ControllerScore(Controller)
            if Score > BestScore then
                Best, BestScore = Controller, Score
            end
        end
    end
    return Best, BestScore
end

--- Local PlayerController. Prefers the local controller with a live pawn so
--- that a transition/menu or remote controller cached around a level change is
--- not pinned: a pawnless cache is re-resolved as soon as a local candidate
--- (pawned or not) exists. Falls back to "Controller" finds and the first
--- valid controller for menu/loading states.
---@return APlayerController? controller
function World.GetPlayerController()
    if Safe.IsValid(PlayerControllerCache) then
        if not HasPawn(PlayerControllerCache) then
            local Best, Score = FindController()
            if Best ~= nil and Score >= 2 and Best ~= PlayerControllerCache then
                PlayerControllerCache = Best
            end
        end
        return PlayerControllerCache
    end

    PlayerControllerCache = FindController()
    return PlayerControllerCache
end

--- Clears the cached PlayerController (call on level change / restart so the
--- next lookup re-resolves against the new level instead of a stale menu or
--- previous-level controller).
function World.Reset()
    PlayerControllerCache = nil
end

--- Pawn of the local PlayerController.
---@return APawn? pawn
function World.GetPawn()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    return Safe.Get(Controller, "Pawn")
end

--- PlayerState of the local PlayerController.
---@return APlayerState? playerState
function World.GetPlayerState()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    return Safe.Get(Controller, "PlayerState")
end

--- UWorld the local player is currently in.
---@return UWorld? world
function World.GetWorld()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    local Ok, WorldObject = Safe.CallFn(Controller, "GetWorld")
    if Ok and WorldObject ~= nil then return WorldObject end
    return nil
end

--- Name of the currently loaded level (e.g. "Sky"), not the heist ref.
---@return string? levelName
function World.GetLevelName()
    local WorldObject = World.GetWorld()
    if WorldObject == nil then return nil end

    local OkFind, GameplayStatics = pcall(StaticFindObject, "/Script/Engine.Default__GameplayStatics")
    if not OkFind or not Safe.IsValid(GameplayStatics) then
        Log.Debug("world: GameplayStatics CDO unavailable")
        return nil
    end

    local Ok, Name = Safe.CallFn(GameplayStatics, "GetCurrentLevelName", WorldObject, true)
    if Ok and Name ~= nil then
        return Safe.Text(Name)
    end
    return nil
end

--- Safe FindAllOf; always returns a table (empty when the class is unknown).
---@param ClassName string # exact short class name; blueprint classes need the _C suffix
---@return UObject[] objects
function World.FindAll(ClassName)
    local Ok, Result = pcall(FindAllOf, ClassName)
    if Ok and type(Result) == "table" then return Result end
    Log.Debug("world: FindAllOf(%s) failed: %s", tostring(ClassName), tostring(Result))
    return {}
end

--- Like FindFirstOf, but skips class default objects and invalid entries.
---@param ClassName string # exact short class name; blueprint classes need the _C suffix
---@return UObject? instance
---@return string? fullName # full name of the found instance
function World.FindLive(ClassName)
    for _, Obj in ipairs(World.FindAll(ClassName)) do
        if Safe.IsValid(Obj) then
            local OkName, FullName = Safe.CallFn(Obj, "GetFullName")
            if OkName and FullName ~= nil and not string.find(tostring(FullName), "Default__", 1, true) then
                return Obj, FullName
            end
        end
    end
    return nil
end

--- Finds a class by object path, loading its package first when needed.
---@param PackagePath string # e.g. "/Game/UI/Widgets/Misc/WBP_Tooltip"
---@param ClassPath string # e.g. "/Game/UI/Widgets/Misc/WBP_Tooltip.WBP_Tooltip_C"
---@return UObject? class
function World.LoadClass(PackagePath, ClassPath)
    local Ok, Found = pcall(StaticFindObject, ClassPath)
    if Ok and Safe.IsValid(Found) then return Found end
    if type(LoadAsset) == "function" then
        pcall(LoadAsset, PackagePath)
    end
    local OkAgain, Again = pcall(StaticFindObject, ClassPath)
    if OkAgain and Safe.IsValid(Again) then return Again end
    return nil
end

--- Drops entries that are no longer valid UObjects, calling OnLost(entry, index)
--- for each dropped one (callback errors are logged, not raised). The original
--- list is returned unchanged when nothing was lost. Iterate the survivor list
--- on the next tick and re-resolve, never keep reading properties of entries
--- that failed this check: stale handles crash natively inside UE4SS, beyond
--- pcall's reach (see Safe.IsValid).
---@param List UObject[]?
---@param OnLost fun(entry: any, index: integer)?
---@return UObject[] survivors
---@return integer lostCount
function World.PruneValid(List, OnLost)
    if type(List) ~= "table" then return {}, 0 end

    local Survivors, Lost = {}, 0
    for Index, Entry in ipairs(List) do
        if Safe.IsValid(Entry) then
            Survivors[#Survivors + 1] = Entry
        else
            Lost = Lost + 1
            if OnLost ~= nil then
                local Ok, Err = pcall(OnLost, Entry, Index)
                if not Ok then
                    Log.Warn("world.PruneValid onLost error: %s", tostring(Err))
                end
            end
        end
    end

    if Lost == 0 then return List, 0 end
    return Survivors, Lost
end

--- Returns Value when it is a vector (has numeric .X), else K2_GetActorLocation
--- when it is an actor, else nil.
---@param Value any
---@return any vector # FVector-like or nil
local function ToVector(Value)
    if Value == nil then return nil end
    local OkX, X = pcall(function() return Value.X end)
    if OkX and type(X) == "number" then return Value end
    if Safe.IsValid(Value) then
        local OkLocation, Location = Safe.CallFn(Value, "K2_GetActorLocation")
        if OkLocation and Location ~= nil then return Location end
    end
    return nil
end

--- Euclidean distance between two actors and/or vectors.
---@param From any # actor or vector
---@param To any # actor or vector
---@return number? distance
function World.Distance(From, To)
    local A = ToVector(From)
    local B = ToVector(To)
    if A == nil or B == nil then return nil end
    local DX, DY, DZ = A.X - B.X, A.Y - B.Y, A.Z - B.Z
    return math.sqrt(DX * DX + DY * DY + DZ * DZ)
end

--- All actors whose class path contains PathSubstring, optionally within
--- MaxDistance of Around, sorted nearest-first. Heavy: iterates FindAllOf("Actor").
---@param PathSubstring string # class path substring, e.g. "SBZPlayerEscapeVolume"
---@param Around any? # actor or vector used for Distance
---@param MaxDistance number? # nil = unlimited
---@return { Actor: UObject, Distance: number? }[] entries
function World.ActorsInPath(PathSubstring, Around, MaxDistance)
    local Result = {}
    for _, Actor in ipairs(World.FindAll("Actor")) do
        if Safe.IsValid(Actor) then
            local OkPath, ClassPath = pcall(function() return Actor:GetClass():GetFullName() end)
            if not OkPath then
                Log.Debug("world: actor class path failed: %s", tostring(ClassPath))
            elseif ClassPath ~= nil and string.find(ClassPath, PathSubstring, 1, true) then
                local Distance = nil
                if Around ~= nil then Distance = World.Distance(Around, Actor) end
                if MaxDistance == nil or (Distance ~= nil and Distance <= MaxDistance) then
                    Result[#Result + 1] = { Actor = Actor, Distance = Distance }
                end
            end
        end
    end
    table.sort(Result, function(A, B) return (A.Distance or math.huge) < (B.Distance or math.huge) end)
    return Result
end

--- Actor:HasAuthority(); nil when the call is unavailable.
---@param Actor any
---@return boolean? hasAuthority
function World.HasAuthority(Actor)
    local Ok, Value = Safe.CallFn(Actor, "HasAuthority")
    if Ok then return Value == true end
    return nil
end

--- Actor:GetOwner().
---@param Actor any
---@return UObject? owner
function World.Owner(Actor)
    local Ok, Value = Safe.CallFn(Actor, "GetOwner")
    if Ok then return Value end
    return nil
end

return World
