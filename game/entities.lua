local Entities = {}
local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")

Entities.CivilianClasses = {
    "CH_Civilian_01_C",
    "CH_Civilian_Female_01_C",
    "CH_Civilian_Employee_Male_01_C",
    "CH_Civilian_Employee_Female_01_C",
    "CH_Civilian_ArtGallery_Manager_male_01_C",
}

Entities.CrewClasses = {
    "CH_CrewAI_Dallas_C",
    "CH_CrewAI_Hoxton_C",
    "CH_CrewAI_Wolf_C",
    "CH_CrewAI_Chains_C",
    "CH_CrewAI_Base_C",
}

function Entities.FindByClasses(ClassNames)
    local Result = {}
    for _, ClassName in ipairs(ClassNames) do
        for _, Actor in ipairs(World.FindAll(ClassName)) do
            if Safe.IsValid(Actor) then
                Result[#Result + 1] = Actor
            end
        end
    end
    return Result
end

function Entities.Civilians()
    return Entities.FindByClasses(Entities.CivilianClasses)
end

function Entities.CrewPawns()
    return Entities.FindByClasses(Entities.CrewClasses)
end

function Entities.InRange(Actors, Around, MaxDistance)
    local Result = {}
    for _, Actor in ipairs(Actors) do
        local Distance = World.Distance(Around, Actor)
        if Distance ~= nil and Distance <= MaxDistance then
            Result[#Result + 1] = { Actor = Actor, Distance = Distance }
        end
    end
    table.sort(Result, function(A, B) return (A.Distance or math.huge) < (B.Distance or math.huge) end)
    return Result
end

function Entities.CiviliansInRange(Around, MaxDistance)
    return Entities.InRange(Entities.Civilians(), Around, MaxDistance)
end

function Entities.NearestCivilian(Around, MaxDistance)
    local List = Entities.CiviliansInRange(Around, MaxDistance or math.huge)
    if #List == 0 then return nil end
    return List[1].Actor
end

function Entities.NearestCrew(Around, MaxDistance)
    local List = Entities.InRange(Entities.CrewPawns(), Around, MaxDistance or math.huge)
    if #List == 0 then return nil end
    return List[1].Actor
end

function Entities.InteractableOf(Character)
    return Safe.Get(Character, "Interactable")
end

function Entities.AIInteractorOf(Pawn)
    return Safe.Get(Pawn, "AIInteractorComponent")
end

function Entities.IsSurrendered(Civilian)
    local Valid = Safe.Get(Civilian, "bIsValidHumanShield")
    local Allowed = Safe.Get(Civilian, "bIsHumanShieldAllowed")
    return Valid == true, Allowed == true
end

return Entities
