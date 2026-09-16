--- Payday 3 entity finders (civilians, crew) with distance helpers.
---@class pd3.Entities
local Entities = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")

--- Blueprint class short names for civilians (_C suffix required by FindAllOf).
---@type string[]
Entities.CivilianClasses = {
    "CH_Civilian_01_C",
    "CH_Civilian_Female_01_C",
    "CH_Civilian_Employee_Male_01_C",
    "CH_Civilian_Employee_Female_01_C",
    "CH_Civilian_ArtGallery_Manager_male_01_C",
}

--- Blueprint class short names for crew AI pawns (_C suffix required by FindAllOf).
---@type string[]
Entities.CrewClasses = {
    "CH_CrewAI_Dallas_C",
    "CH_CrewAI_Hoxton_C",
    "CH_CrewAI_Wolf_C",
    "CH_CrewAI_Chains_C",
    "CH_CrewAI_Base_C",
}

--- Finds all valid live instances of the given class names.
---@param ClassNames string[] # exact short names, _C suffix required for blueprints
---@return UObject[] actors
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

--- All live civilian characters.
---@return UObject[] civilians
function Entities.Civilians()
    return Entities.FindByClasses(Entities.CivilianClasses)
end

--- All live crew AI pawns.
---@return UObject[] crewPawns
function Entities.CrewPawns()
    return Entities.FindByClasses(Entities.CrewClasses)
end

--- Filters Actors to those within MaxDistance of Around, sorted nearest-first.
---@param Actors UObject[]
---@param Around any # actor or vector
---@param MaxDistance number
---@return { Actor: UObject, Distance: number? }[] entries
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

--- Civilians within MaxDistance of Around, sorted nearest-first.
---@param Around any # actor or vector
---@param MaxDistance number
---@return { Actor: UObject, Distance: number? }[] entries
function Entities.CiviliansInRange(Around, MaxDistance)
    return Entities.InRange(Entities.Civilians(), Around, MaxDistance)
end

--- Nearest live civilian within MaxDistance (or anywhere when nil).
---@param Around any # actor or vector
---@param MaxDistance? number
---@return UObject? civilian
function Entities.NearestCivilian(Around, MaxDistance)
    local List = Entities.CiviliansInRange(Around, MaxDistance or math.huge)
    if #List == 0 then return nil end
    return List[1].Actor
end

--- Nearest live crew pawn within MaxDistance (or anywhere when nil).
---@param Around any # actor or vector
---@param MaxDistance? number
---@return UObject? crewPawn
function Entities.NearestCrew(Around, MaxDistance)
    local List = Entities.InRange(Entities.CrewPawns(), Around, MaxDistance or math.huge)
    if #List == 0 then return nil end
    return List[1].Actor
end

--- The character's interaction target component (SBZAICharacterInteractableComponent
--- or SBZCharacterInteractableComponent).
---@param Character any # SBZCharacter
---@return UObject? interactable
function Entities.InteractableOf(Character)
    return Safe.Get(Character, "Interactable")
end

--- The pawn's AI interactor component (SBZAIInteractorComponent).
---@param Pawn any # SBZAICharacter
---@return UObject? interactor
function Entities.AIInteractorOf(Pawn)
    return Safe.Get(Pawn, "AIInteractorComponent")
end

--- Surrender/shield flags of a civilian.
---@param Civilian any # SBZCharacter
---@return boolean validHumanShield # bIsValidHumanShield
---@return boolean humanShieldAllowed # bIsHumanShieldAllowed
function Entities.IsSurrendered(Civilian)
    local Valid = Safe.Get(Civilian, "bIsValidHumanShield")
    local Allowed = Safe.Get(Civilian, "bIsHumanShieldAllowed")
    return Valid == true, Allowed == true
end

return Entities
