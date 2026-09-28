# global game.chat








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











