# class Options



- namespace: pd3.Reflect



Per-call dump options; missing fields fall back to Reflect.Defaults.







---



## fields
---

### Options.MaxDepth
---
```lua
Options.MaxDepth : integer?
```



nested struct recursion depth (objects are described, not recursed); default 1








### Options.MaxArray
---
```lua
Options.MaxArray : integer?
```



array elements printed per array; 0 = unlimited; default 25








### Options.MaxString
---
```lua
Options.MaxString : integer?
```



max chars per formatted value; 0 = unlimited; default 200








### Options.MaxLines
---
```lua
Options.MaxLines : integer?
```



max output lines per dump; 0 = unlimited; default 400








### Options.Filter
---
```lua
Options.Filter : string?
```



property-name substring; non-empty limits DumpProperties output








### Options.Skip
---
```lua
Options.Skip : table<string,boolean>?
```



property names never dumped









