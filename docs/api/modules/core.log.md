# global core.log








---

## methods
---

### Log.SetPrefix
---
```lua
function Log.SetPrefix(NewPrefix: string) ->  nil
```





Sets the prefix prepended to every log line.








### Log.GetPrefix
---
```lua
function Log.GetPrefix() -> prefix string
```





Returns the current log prefix.








### Log.SetDebug
---
```lua
function Log.SetDebug(Enabled: boolean) ->  nil
```





Enables or disables Log.Debug output.








### Log.Info
---
```lua
function Log.Info(
  Msg: string,
  ...: any
) ->  nil
```
@param `Msg` - format string when arguments are passed

@param `...` - string.format arguments






Logs an info line.








### Log.Warn
---
```lua
function Log.Warn(
  Msg: string,
  ...: any
) ->  nil
```
@param `Msg` - format string when arguments are passed

@param `...` - string.format arguments






Logs a warning line (adds "[warn] ").








### Log.Err
---
```lua
function Log.Err(
  Msg: string,
  ...: any
) ->  nil
```
@param `Msg` - format string when arguments are passed

@param `...` - string.format arguments






Logs an error line (adds "[error] ").








### Log.Debug
---
```lua
function Log.Debug(
  Msg: string,
  ...: any
) ->  nil
```
@param `Msg` - format string when arguments are passed

@param `...` - string.format arguments






Logs a debug line; no-op unless SetDebug(true) was called.








### Log.Dump
---
```lua
function Log.Dump(
  Value: any,
  MaxDepth: integer?
) ->  nil
```
@param `MaxDepth` - default 2






Logs a value; tables are expanded up to MaxDepth levels.











