--- Interaction system helpers (SBZInteractorComponent RPCs).
---
--- Flow: client calls Server_StartInteraction(interactable, id, modeIndex); the
--- server validates and multicasts start/complete. id is the interactor's
--- InteractId - reuse it for Complete/Stop. On online/solo-online only
--- player-owned actors route to the server.
---@class pd3.Interact
local Interact = {}

local Log = require("pd3lib.core.log")
local Safe = require("pd3lib.core.safe")
local Hooks = require("pd3lib.core.hooks")
local Timers = require("pd3lib.core.timers")

--- ESBZAICharacterInteractableMode index -> name. Index semantics are not
--- reliably enumerable at runtime; do not read ModeArray/ModeDataArray.
---@type table<integer, string>
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

--- ESBZInteractionAction index -> name.
---@type table<integer, string>
Interact.Actions = {
    [0] = "None",
    [1] = "GetDown",
    [2] = "HogTie",
    [3] = "Follow",
    [4] = "TradeHostage",
}

--- Known interaction/state-machine UFunction paths for discovery logging.
---@type table<string, string>
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

--- Mode name for an ESBZAICharacterInteractableMode index.
---@param Index any
---@return string name # "Unknown(n)" when unmapped
function Interact.ModeName(Index)
    return Interact.Modes[Index] or ("Unknown(" .. tostring(Index) .. ")")
end

--- Name for an ESBZInteractionAction index.
---@param Index any
---@return string name # "Unknown(n)" when unmapped
function Interact.ActionName(Index)
    return Interact.Actions[Index] or ("Unknown(" .. tostring(Index) .. ")")
end

--- The pawn's player interactor component (SBZPlayerInteractorComponent).
---@param Pawn any # SBZPlayerCharacter
---@return UObject? interactor
function Interact.PlayerInteractor(Pawn)
    return Safe.Get(Pawn, "Interactor")
end

--- Client-side RPC: Server_StartInteraction(interactable, id, modeIndex).
---@param InteractorRef any # SBZPlayerInteractorComponent / SBZAIInteractorComponent
---@param Interactable any # target's Interactable component
---@param ModeIndex? integer # default 0; do not assume enum name-to-index mapping
---@param Id? integer # default 1; usually the interactor's InteractId
---@return boolean ok # false when refs are invalid or the call raised
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

--- Client-side RPC: Server_CompleteInteraction(interactable, id). The server
--- often completes by itself; an extra call has been observed harmless.
---@param InteractorRef any
---@param Interactable any
---@param Id? integer # default 1; must match the Start id
---@return boolean ok
function Interact.Complete(InteractorRef, Interactable, Id)
    if not Safe.IsValid(InteractorRef) or not Safe.IsValid(Interactable) then
        Log.Warn("Interact.Complete: invalid interactor or interactable")
        return false
    end
    local Ok = Safe.CallFn(InteractorRef, "Server_CompleteInteraction", Interactable, Id or 1)
    Log.Info("CompleteInteraction id=%s ok=%s", tostring(Id or 1), tostring(Ok))
    return Ok
end

--- Client-side RPC: Server_StopInteraction(interactable).
---@param InteractorRef any
---@param Interactable any
---@return boolean ok
function Interact.Stop(InteractorRef, Interactable)
    if not Safe.IsValid(InteractorRef) or not Safe.IsValid(Interactable) then
        Log.Warn("Interact.Stop: invalid interactor or interactable")
        return false
    end
    local Ok = Safe.CallFn(InteractorRef, "Server_StopInteraction", Interactable)
    Log.Info("StopInteraction ok=%s", tostring(Ok))
    return Ok
end

--- Start, then Complete after CompleteDelayMs (skipped when delay is nil).
---@param InteractorRef any
---@param Interactable any
---@param ModeIndex? integer
---@param Id? integer
---@param CompleteDelayMs integer? # nil = start only
---@return boolean ok # Start result
function Interact.StartWithComplete(InteractorRef, Interactable, ModeIndex, Id, CompleteDelayMs)
    local Started = Interact.Start(InteractorRef, Interactable, ModeIndex, Id)
    if Started and CompleteDelayMs ~= nil then
        Timers.After(CompleteDelayMs, function()
            Interact.Complete(InteractorRef, Interactable, Id)
        end)
    end
    return Started
end

--- Current interaction state of an interactor.
---@class pd3.Interact.State
---@field InteractId any # interactor.InteractId
---@field ModeIndex any # interactor.ModeIndex
---@field CurrentInteraction any # interactor.CurrentInteraction
---@field Selected any # GetSelectedInteraction() result, nil when unavailable

--- Reads the interactor's current interaction state.
---@param InteractorRef any
---@return pd3.Interact.State state
function Interact.State(InteractorRef)
    local SelectedOk, Selected = Safe.CallFn(InteractorRef, "GetSelectedInteraction")
    return {
        InteractId = Safe.Get(InteractorRef, "InteractId"),
        ModeIndex = Safe.Get(InteractorRef, "ModeIndex"),
        CurrentInteraction = Safe.Get(InteractorRef, "CurrentInteraction"),
        Selected = SelectedOk and Selected or nil,
    }
end

--- Hooks every path in Interact.HookPaths with full fire logging.
---@return integer registered # number of hooks installed successfully
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
