--- In-game chat messages via `SBZChatInGame:SendChatMessageToServer`.
---
--- Works in solo / as host: the call runs the server path locally and the message is multicasted
--- back into the local chat feed. Field-proven by the EnableHiddenPainting mod (Art Gallery) in
--- solo loud; multiplayer client behaviour is untested.
---
--- The chat feed renders UMG rich text, so the game's `DT_ChatRichTextStyles` tags work:
--- `default` (white 85%), `PlayerName` (light mint), `Object` (amber, outlined), `Good` (green),
--- `Bad` / `Hostile` (red), `Hud_01` (light green), `Blue`, `Callout` (amber, outlined),
--- `Skills1` (orange, size 15), `StatDescription` (yellow), `Skill` (white), `Notation`
--- (white, outlined). Wrap text like `<Good>ok</>`; untagged text uses `default`.
---
--- Messages are not truncated locally - keep them short enough for one chat line.
---@class pd3.Chat
local Chat = {}

local Safe = require("pd3lib.core.safe")
local World = require("pd3lib.core.world")
local Log = require("pd3lib.core.log")

--- "SBZChatInGame" instance resolution is cached per call site only; FindLive is cheap.
local WarnedUnavailable = false

--- The live SBZChatInGame instance, or nil outside a running level.
---@return UObject? chat
function Chat.Get()
    return World.FindLive("SBZChatInGame")
end

--- True when the game exposes a usable chat sink.
---@return boolean
function Chat.Available()
    return Chat.Get() ~= nil
end

--- Sends one chat line to the local feed.
---@param Text string
---@return boolean ok
---@return string? err
function Chat.Send(Text)
    if type(Text) ~= "string" or Text == "" then
        return false, "empty message"
    end

    local Instance = Chat.Get()
    if Instance == nil then
        if not WarnedUnavailable then
            WarnedUnavailable = true
            Log.Warn("chat: SBZChatInGame not found; messages stay log-only")
        end
        return false, "no SBZChatInGame"
    end

    local Controller = World.GetPlayerController()
    if not Safe.IsValid(Controller) then return false, "no player controller" end

    local PlayerState = Safe.Get(Controller, "PlayerState")
    if not Safe.IsValid(PlayerState) then return false, "no player state" end

    local Ok, Err = Safe.CallFn(Instance, "SendChatMessageToServer", {
        PlayerState = PlayerState,
        Message = Text,
    })
    if not Ok then
        return false, tostring(Err)
    end
    return true, nil
end

--- Sends a `string.format`-style chat line.
---@param Format string
---@return boolean ok
---@return string? err
function Chat.SendFmt(Format, ...)
    local Ok, Text = pcall(string.format, Format, ...)
    if not Ok then
        return false, "format error: " .. tostring(Text)
    end
    return Chat.Send(Text)
end

return Chat
