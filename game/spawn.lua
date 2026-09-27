--- Direct actor spawning for test rigs and training areas. Spawns through
--- `GameplayStatics:BeginDeferredActorSpawnFromClass` + `FinishSpawningActor`
--- with transforms built by `KismetMathLibrary`.
---
--- The engine statics are resolved with `StaticFindObject` — this UE4SS build
--- has no Lua globals for script classes such as `UKismetMathLibrary` /
--- `UGameplayStatics`, so calling them as globals fails with "attempt to call
--- a nil value". Every step is pcall'd; failures return `nil, reason` instead
--- of raising.
---
--- `BeginDeferredActorSpawnFromClass` / `FinishSpawningActor` are game-thread
--- only: call from `pd3.timers.InGameThread` / tick handlers, never from a
--- keybind callback.
---@class pd3.Spawn
local Spawn = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Log = require("pd3lib.core.log")

--- ESpawnActorCollisionHandlingMethod: spawn regardless of collision.
---@type integer
Spawn.AlwaysSpawn = 0

--- ETransformScaleMethod: apply the passed transform's scale.
---@type integer
Spawn.TransformScale = 1

--- Object path of the Kismet math function library class.
---@type string
Spawn.KismetPath = "/Script/Engine.KismetMathLibrary"

--- Object path of the GameplayStatics class.
---@type string
Spawn.GameplayStaticsPath = "/Script/Engine.GameplayStatics"

--- Degrees -> radians.
---@param Deg number?
---@return number radians
function Spawn.YawRadians(Deg)
    return math.rad(tonumber(Deg) or 0)
end

--- Yaw that makes a spawned actor face the player (180 degrees from the
--- player's yaw), normalized to 0..360.
---@param PlayerYaw number?
---@return number yaw
function Spawn.FacingYaw(PlayerYaw)
    return ((tonumber(PlayerYaw) or 0) + 180) % 360
end

--- 2D world offset (cm) at a yaw: X + cos(yaw)*distance, Y + sin(yaw)*distance.
---@param X number?
---@param Y number?
---@param YawDeg number?
---@param DistanceCm number?
---@return number offsetX # X + cos(yaw) * distance
---@return number offsetY # Y + sin(yaw) * distance
function Spawn.OffsetLocation(X, Y, YawDeg, DistanceCm)
    local Radians = Spawn.YawRadians(YawDeg)
    local Distance = tonumber(DistanceCm) or 0
    return (tonumber(X) or 0) + math.cos(Radians) * Distance,
        (tonumber(Y) or 0) + math.sin(Radians) * Distance
end

local CachedKismet = nil
local CachedStatics = nil

--- Resolves (and caches) the Kismet math library and GameplayStatics CDOs.
---@return UObject? kismet
---@return UObject? gameplayStatics
function Spawn.Statics()
    if Safe.IsValid(CachedKismet) and Safe.IsValid(CachedStatics) then
        return CachedKismet, CachedStatics
    end

    local OkKismet, Kismet = pcall(StaticFindObject, Spawn.KismetPath)
    local OkStatics, GameplayStatics = pcall(StaticFindObject, Spawn.GameplayStaticsPath)
    if OkKismet and Safe.IsValid(Kismet) then CachedKismet = Kismet end
    if OkStatics and Safe.IsValid(GameplayStatics) then CachedStatics = GameplayStatics end

    if CachedKismet == nil or CachedStatics == nil then
        Log.Debug("spawn: statics unresolved (kismet=%s gameplayStatics=%s)",
            tostring(OkKismet and Safe.IsValid(Kismet)), tostring(OkStatics and Safe.IsValid(GameplayStatics)))
    end
    return CachedKismet, CachedStatics
end

--- Spawns one actor of Class at Location facing YawDeg.
---
--- Location is a table with numeric X, Y, Z fields (cm). YawDeg is the full
--- facing yaw in degrees; roll/pitch stay 0. WorldObject defaults to the local
--- player's world, falling back to the first live "World" instance.
---@param Class UObject # class object (use core.classes to resolve)
---@param Location { X: number, Y: number, Z: number }
---@param YawDeg number
---@param WorldObject? UObject # world-context override
---@return UObject? actor
---@return string? err
function Spawn.ActorFromClass(Class, Location, YawDeg, WorldObject)
    if not Safe.IsValid(Class) then return nil, "class unresolved" end
    if type(Location) ~= "table" then return nil, "location table required" end

    local X = tonumber(Location.X or Location.x)
    local Y = tonumber(Location.Y or Location.y)
    local Z = tonumber(Location.Z or Location.z)
    if X == nil or Y == nil or Z == nil then return nil, "location needs X/Y/Z" end

    local WorldObject = WorldObject or World.GetWorld()
    if not Safe.IsValid(WorldObject) then
        WorldObject = World.FindLive("World")
    end
    if not Safe.IsValid(WorldObject) then return nil, "no world" end

    local Kismet, GameplayStatics = Spawn.Statics()
    if Kismet == nil or GameplayStatics == nil then return nil, "engine statics unresolved" end

    local OkVector, LocationVector = pcall(function() return Kismet:MakeVector(X, Y, Z) end)
    if not OkVector or LocationVector == nil then
        return nil, "MakeVector failed: " .. tostring(LocationVector)
    end

    local OkRotator, Rotation = pcall(function() return Kismet:MakeRotator(0.0, 0.0, tonumber(YawDeg) or 0) end)
    if not OkRotator or Rotation == nil then
        return nil, "MakeRotator failed: " .. tostring(Rotation)
    end

    local OkScale, Scale = pcall(function() return Kismet:MakeVector(1.0, 1.0, 1.0) end)
    if not OkScale or Scale == nil then
        return nil, "MakeVector(scale) failed: " .. tostring(Scale)
    end

    local OkTransform, Transform = pcall(function() return Kismet:MakeTransform(LocationVector, Rotation, Scale) end)
    if not OkTransform or Transform == nil then
        return nil, "MakeTransform failed: " .. tostring(Transform)
    end

    local OkActor, Actor = pcall(function()
        return GameplayStatics:BeginDeferredActorSpawnFromClass(
            WorldObject, Class, Transform, Spawn.AlwaysSpawn, nil, Spawn.TransformScale)
    end)
    if not OkActor then
        return nil, "BeginDeferredActorSpawnFromClass failed: " .. tostring(Actor)
    end
    if not Safe.IsValid(Actor) then return nil, "spawn returned no actor" end

    local OkFinish, FinishErr = pcall(function()
        return GameplayStatics:FinishSpawningActor(Actor, Transform, Spawn.TransformScale)
    end)
    if not OkFinish then
        Log.Warn("spawn: FinishSpawningActor failed: %s", tostring(FinishErr))
        return Actor, "FinishSpawningActor failed: " .. tostring(FinishErr)
    end

    return Actor
end

--- K2_DestroyActor in protected mode.
---@param Actor any
---@return boolean ok
---@return string? err
function Spawn.Destroy(Actor)
    if not Safe.IsValid(Actor) then return false, "invalid actor" end
    local Ok, Err = Safe.CallFn(Actor, "K2_DestroyActor")
    if not Ok then return false, tostring(Err) end
    return true
end

return Spawn
