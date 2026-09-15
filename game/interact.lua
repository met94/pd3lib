local Interact = {}
local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local Hooks = require("pd3lib.core.hooks")
local Timers = require("pd3lib.core.timers")

Interact.Modes = {
    [0] = "PickUp",
    [1] = "HumanShield",
    [2] = "AnswerPager",
    [3] = "OrderDownOnGround",
    [4] = "TieHands",
    [5] = "OrderFollow",
    [6] = "TradeHostage",
    [7] = "KillHumanShield",
    [8] = "PickUpKilledHumanShield",
    [9] = "HackerGlitchProtocol",
    [10] = "None",
}

Interact.Actions = {
    [0] = "None",
    [1] = "GetDown",
    [2] = "HogTie",
    [3] = "Follow",
    [4] = "TradeHostage",
}

Interact.HookPaths = {
    ServerStart = "/Script/Starbreeze.SBZInteractorComponent:Server_StartInteraction",
    ServerComplete = "/Script/Starbreeze.SBZInteractorComponent:Server_CompleteInteraction",
    ServerStop = "/Script/Starbreeze.SBZInteractorComponent:Server_StopInteraction",
    SimulatedStart = "/Script/Starbreeze.SBZInteractorComponent:Multicast_StartSimulatedInteraction",
    SimulatedComplete = "/Script/Starbreeze.SBZInteractorComponent:Multicast_CompletedInteraction",
    Abort = "/Script/Starbreeze.SBZInteractorComponent:Multicast_AbortInteraction",
    ServerSlotReached = "/Script/Starbreeze.SBZCharacter:Server_HumanShieldInstigatorSlotReached",
    SlotReached = "/Script/Starbreeze.SBZCharacter:Multicast_HumanShieldInstigatorSlotReached",
    SnapVictim = "/Script/Starbreeze.SBZCharacter:Multicast_SnapVictimOntoInstigator",
}

function Interact.ModeName(Index)
    return Interact.Modes[Index] or ("Unknown(" .. tostring(Index) .. ")")
end

function Interact.ActionName(Index)
    return Interact.Actions[Index] or ("Unknown(" .. tostring(Index) .. ")")
end

function Interact.PlayerInteractor(Pawn)
    return Safe.Get(Pawn, "Interactor")
end

function Interact.Start(InteractorRef, Interactable, ModeIndex, Id)
    if not Safe.IsValid(InteractorRef) or not Safe.IsValid(Interactable) then
        Log.Warn("Interact.Start: invalid interactor or interactable")
        return false
    end
    local Ok = Safe.CallFn(InteractorRef, "Server_StartInteraction", Interactable, Id or 1, ModeIndex or 0)
    Log.Info("StartInteraction id=%s mode=%s (%s) ok=%s",
        tostring(Id or 1), tostring(ModeIndex or 0), Interact.ModeName(ModeIndex or 0), tostring(Ok))
    return Ok
end

function Interact.Complete(InteractorRef, Interactable, Id)
    if not Safe.IsValid(InteractorRef) or not Safe.IsValid(Interactable) then
        Log.Warn("Interact.Complete: invalid interactor or interactable")
        return false
    end
    local Ok = Safe.CallFn(InteractorRef, "Server_CompleteInteraction", Interactable, Id or 1)
    Log.Info("CompleteInteraction id=%s ok=%s", tostring(Id or 1), tostring(Ok))
    return Ok
end

function Interact.Stop(InteractorRef, Interactable)
    if not Safe.IsValid(InteractorRef) or not Safe.IsValid(Interactable) then
        Log.Warn("Interact.Stop: invalid interactor or interactable")
        return false
    end
    local Ok = Safe.CallFn(InteractorRef, "Server_StopInteraction", Interactable)
    Log.Info("StopInteraction ok=%s", tostring(Ok))
    return Ok
end

function Interact.StartWithComplete(InteractorRef, Interactable, ModeIndex, Id, CompleteDelayMs)
    local Started = Interact.Start(InteractorRef, Interactable, ModeIndex, Id)
    if Started and CompleteDelayMs ~= nil then
        Timers.After(CompleteDelayMs, function()
            Interact.Complete(InteractorRef, Interactable, Id)
        end)
    end
    return Started
end

function Interact.State(InteractorRef)
    local SelectedOk, Selected = Safe.CallFn(InteractorRef, "GetSelectedInteraction")
    return {
        InteractId = Safe.Get(InteractorRef, "InteractId"),
        ModeIndex = Safe.Get(InteractorRef, "ModeIndex"),
        CurrentInteraction = Safe.Get(InteractorRef, "CurrentInteraction"),
        Selected = SelectedOk and Selected or nil,
    }
end

function Interact.EnableDiscoveryLogging()
    local Registered = 0
    for _, Path in pairs(Interact.HookPaths) do
        if Hooks.HookLogged(Path) ~= nil then
            Registered = Registered + 1
        end
    end
    Log.Info("discovery logging enabled (%d hooks)", Registered)
    return Registered
end

return Interact
