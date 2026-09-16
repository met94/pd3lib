--- Player human shield helpers (interaction-driven grab, ability cancel release).
---
--- AI instigator is unsupported: triggering it with a crew AIInteractor crashes
--- the engine before SlotReached (player-only code assumption in the instigator
--- state machine). Never attempt it; Shield.AIInstigatorUnsupported documents this.
---@class pd3.Shield
local Shield = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Interact = require("pd3lib.game.interact")
local Entities = require("pd3lib.game.entities")

--- True: AI-driven human shields crash the game. Do not trigger them.
---@type boolean
Shield.AIInstigatorUnsupported = true

--- ESBZHumanShieldInstigatorState index -> name.
---@type table<integer, string>
Shield.InstigatorStates = {
    [0] = "None",
    [1] = "ReachingSlot",
    [2] = "EnterGrabbing",
    [3] = "Grabbing",
    [4] = "Choking",
    [5] = "Exiting",
}

--- Blueprint class name of the instigator ability.
---@type string
Shield.AbilityClassName = "GA_HumanShieldInstigator_C"

--- Name for an ESBZHumanShieldInstigatorState value.
---@param Value any
---@return string name # "Unknown(n)" when unmapped
function Shield.StateName(Value)
    return Shield.InstigatorStates[Value] or ("Unknown(" .. tostring(Value) .. ")")
end

--- The pawn's HumanShieldInstigatorState (3 Grabbing / 4 Choking when held).
---@param Pawn any # SBZCharacter
---@return integer? state
function Shield.InstigatorState(Pawn)
    return Safe.Get(Pawn, "HumanShieldInstigatorState")
end

--- Surrender/shield flags of a potential victim.
---@param Victim any # SBZCharacter
---@return { Valid: boolean?, Allowed: boolean? } flags
function Shield.VictimFlags(Victim)
    return {
        Valid = Safe.Get(Victim, "bIsValidHumanShield"),
        Allowed = Safe.Get(Victim, "bIsHumanShieldAllowed"),
    }
end

--- Grabs a surrendered civilian as a human shield via the interaction system.
--- Uses the interactor's current InteractId/ModeIndex and completes after
--- CompleteDelayMs (default 500). Grab leads to state 3 (Grabbing) within ~1-2s.
---@param Pawn any # player pawn (SBZPlayerCharacter)
---@param Victim any # civilian SBZCharacter
---@param CompleteDelayMs? integer # default 500
---@return boolean ok # false when refs are invalid
function Shield.Grab(Pawn, Victim, CompleteDelayMs)
    local InteractorRef = Interact.PlayerInteractor(Pawn)
    local Interactable = Entities.InteractableOf(Victim)

    if not Safe.IsValid(InteractorRef) then
        Log.Warn("Shield.Grab: no player interactor")
        return false
    end
    if not Safe.IsValid(Interactable) then
        Log.Warn("Shield.Grab: victim has no interactable component")
        return false
    end

    local Id = Safe.Num(Safe.Get(InteractorRef, "InteractId"), 1)
    local ModeIndex = Safe.Num(Safe.Get(InteractorRef, "ModeIndex"), 0)

    local Valid, Allowed = Entities.IsSurrendered(Victim)
    Log.Info("Shield.Grab victim=%s mode=%d (%s) surrendered=%s/%s",
        Safe.Describe(Victim), ModeIndex, Interact.ModeName(ModeIndex), tostring(Valid), tostring(Allowed))

    return Interact.StartWithComplete(InteractorRef, Interactable, ModeIndex, Id, CompleteDelayMs or 500)
end

--- Releases the human shield by cancelling live GA_HumanShieldInstigator_C
--- instances (Default__ CDOs are skipped).
---@return integer cancelled # number of ability instances cancelled
function Shield.Release()
    local Cancelled = 0
    for _, Ability in ipairs(World.FindAll(Shield.AbilityClassName)) do
        if Safe.IsValid(Ability) then
            local OkName, FullName = Safe.CallFn(Ability, "GetFullName")
            if OkName and FullName ~= nil and not string.find(tostring(FullName), "Default__", 1, true) then
                Safe.CallFn(Ability, "K2_CancelAbility")
                Cancelled = Cancelled + 1
            end
        end
    end
    Log.Info("Shield.Release cancelled %d ability instances", Cancelled)
    return Cancelled
end

return Shield
