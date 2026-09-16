# global selftest








---

## methods
---

### SelfTest.Add
---
```lua
function SelfTest.Add(
  Name: string,
  Fn: fun() -> (boolean?,string?)
) ->  nil
```





Registers an extra check. Fn returning false (or raising) counts as FAIL.








### SelfTest.Run
---
```lua
function SelfTest.Run()
 -> passed integer
 -> failed integer

```





Runs the built-in checks plus SelfTest.Add checks, logging PASS/FAIL lines.











