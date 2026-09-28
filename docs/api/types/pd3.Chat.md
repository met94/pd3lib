# class Chat



- namespace: pd3



In-game chat messages via `SBZChatInGame:SendChatMessageToServer`.

Works in solo / as host: the call runs the server path locally and the message is multicasted
back into the local chat feed. Field-proven by the EnableHiddenPainting mod (Art Gallery) in
solo loud; multiplayer client behaviour is untested.

The chat feed renders UMG rich text, so the game's `DT_ChatRichTextStyles` tags work:
`default` (white 85%), `PlayerName` (light mint), `Object` (amber, outlined), `Good` (green),
`Bad` / `Hostile` (red), `Hud_01` (light green), `Blue`, `Callout` (amber, outlined),
`Skills1` (orange, size 15), `StatDescription` (yellow), `Skill` (white), `Notation`
(white, outlined). Wrap text like `<Good>ok</>`; untagged text uses `default`.

Messages are not truncated locally - keep them short enough for one chat line.







---

## methods
---

### Chat.Reset
---
```lua
function Chat.Reset() ->  nil
```





Clears the one-shot "unavailable" warning (call on level change / restart
so a failure in the new level is reported again instead of staying silent).








### Chat.Get
---
```lua
function Chat.Get() -> chat UObject?
```





The live SBZChatInGame instance, or nil outside a running level.








### Chat.Available
---
```lua
function Chat.Available() ->  boolean
```





True when the game exposes a usable chat sink.








### Chat.Send
---
```lua
function Chat.Send(Text: string)
 -> ok boolean
 -> err string?

```





Sends one chat line to the local feed.








### Chat.SendFmt
---
```lua
function Chat.SendFmt(
  Format: string,
  ...
)
 -> ok boolean
 -> err string?

```





Sends a `string.format`-style chat line.











