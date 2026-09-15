local Shield = {}
local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Interact = require("pd3lib.game.interact")
local Entities = require("pd3lib.game.entities")

Shield.AIInstigatorUnsupported = true

Shield.InstigatorStates = {
    [0] = "None",
    [1] = "ReachingSlot",
    [2] = "EnterGrabbing",
    [3] = "Grabbing",
    [4] = "Choking",
    [5] = "Exiting",
}

Shield.AbilityClassName = "GA_HumanShieldInstigator_C"

function Shield.StateName(Value)
    return Shield.InstigatorStates[Value] or ("Unknown(" .. tostring(Value) .. ")")
end

function Shield.InstigatorState(Pawn)
    return Safe.Get(Pawn, "HumanShieldInstigatorState")
end

function Shield.VictimFlags(Victim)
    return {
        Valid = Safe.Get(Victim, "bIsValidHumanShield"),
        Allowed = Safe.Get(Victim, "bIsHumanShieldAllowed"),
    }
end

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
