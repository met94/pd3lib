local World = {}
local Safe = require("pd3lib.core.safe")

local PlayerControllerCache = nil

function World.GetPlayerController()
    if Safe.IsValid(PlayerControllerCache) then return PlayerControllerCache end

    local Controllers = World.FindAll("PlayerController")
    if #Controllers == 0 then Controllers = World.FindAll("Controller") end

    for _, Controller in ipairs(Controllers) do
        if Safe.IsValid(Controller) then
            PlayerControllerCache = Controller
            return Controller
        end
    end
    return nil
end

function World.GetPawn()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    return Safe.Get(Controller, "Pawn")
end

function World.GetPlayerState()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    return Safe.Get(Controller, "PlayerState")
end

function World.GetWorld()
    local Controller = World.GetPlayerController()
    if Controller == nil then return nil end
    local Ok, WorldObject = Safe.CallFn(Controller, "GetWorld")
    if Ok and WorldObject ~= nil then return WorldObject end
    return nil
end

function World.GetLevelName()
    local WorldObject = World.GetWorld()
    if WorldObject == nil then return nil end

    local OkFind, GameplayStatics = pcall(StaticFindObject, "/Script/Engine.Default__GameplayStatics")
    if not OkFind or not Safe.IsValid(GameplayStatics) then return nil end

    local Ok, Name = Safe.CallFn(GameplayStatics, "GetCurrentLevelName", WorldObject, true)
    if Ok and Name ~= nil then
        return Safe.Text(Name)
    end
    return nil
end

function World.FindAll(ClassName)
    local Ok, Result = pcall(FindAllOf, ClassName)
    if Ok and type(Result) == "table" then return Result end
    return {}
end

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

function World.Distance(From, To)
    local A = ToVector(From)
    local B = ToVector(To)
    if A == nil or B == nil then return nil end
    local DX, DY, DZ = A.X - B.X, A.Y - B.Y, A.Z - B.Z
    return math.sqrt(DX * DX + DY * DY + DZ * DZ)
end

function World.ActorsInPath(PathSubstring, Around, MaxDistance)
    local Result = {}
    for _, Actor in ipairs(World.FindAll("Actor")) do
        if Safe.IsValid(Actor) then
            local OkPath, ClassPath = pcall(function() return Actor:GetClass():GetFullName() end)
            if OkPath and ClassPath ~= nil and string.find(ClassPath, PathSubstring, 1, true) then
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

function World.HasAuthority(Actor)
    local Ok, Value = Safe.CallFn(Actor, "HasAuthority")
    if Ok then return Value == true end
    return nil
end

function World.Owner(Actor)
    local Ok, Value = Safe.CallFn(Actor, "GetOwner")
    if Ok then return Value end
    return nil
end

return World
