# class Spawn



- namespace: pd3



Direct actor spawning for test rigs and training areas. Spawns through
`GameplayStatics:BeginDeferredActorSpawnFromClass` + `FinishSpawningActor`
with transforms built by `KismetMathLibrary`.

The engine statics are resolved with `StaticFindObject` — this UE4SS build
has no Lua globals for script classes such as `UKismetMathLibrary` /
`UGameplayStatics`, so calling them as globals fails with "attempt to call
a nil value". Every step is pcall'd; failures return `nil, reason` instead
of raising.

`BeginDeferredActorSpawnFromClass` / `FinishSpawningActor` are game-thread
only: call from `pd3.timers.InGameThread` / tick handlers, never from a
keybind callback.







---

## methods
---

### Spawn.YawRadians
---
```lua
function Spawn.YawRadians(Deg: number?) -> radians number
```





Degrees -> radians.








### Spawn.FacingYaw
---
```lua
function Spawn.FacingYaw(PlayerYaw: number?) -> yaw number
```





Yaw that makes a spawned actor face the player (180 degrees from the
player's yaw), normalized to 0..360.








### Spawn.OffsetLocation
---
```lua
function Spawn.OffsetLocation(
  X: number?,
  Y: number?,
  YawDeg: number?,
  DistanceCm: number?
)
 -> offsetX number
 -> offsetY number

```

@return `offsetX` - X + cos(yaw) * distance

@return `offsetY` - Y + sin(yaw) * distance





2D world offset (cm) at a yaw: X + cos(yaw)*distance, Y + sin(yaw)*distance.








### Spawn.Statics
---
```lua
function Spawn.Statics()
 -> kismet UObject?
 -> gameplayStatics UObject?

```





Resolves (and caches) the Kismet math library and GameplayStatics CDOs.








### Spawn.ActorFromClass
---
```lua
function Spawn.ActorFromClass(
  Class: UObject,
  Location: { X: number, Y: number, Z: number },
  YawDeg: number,
  WorldObject: UObject?
)
 -> actor UObject?
 -> err string?

```
@param `Class` - class object (use core.classes to resolve)

@param `WorldObject` - world-context override






Spawns one actor of Class at Location facing YawDeg.

Location is a table with numeric X, Y, Z fields (cm). YawDeg is the full
facing yaw in degrees; roll/pitch stay 0. WorldObject defaults to the local
player's world, falling back to the first live "World" instance.








### Spawn.Destroy
---
```lua
function Spawn.Destroy(Actor: any)
 -> ok boolean
 -> err string?

```





K2_DestroyActor in protected mode.











## fields
---

### Spawn.AlwaysSpawn
---
```lua
Spawn.AlwaysSpawn : integer
```



ESpawnActorCollisionHandlingMethod: spawn regardless of collision.








### Spawn.TransformScale
---
```lua
Spawn.TransformScale : integer
```



ETransformScaleMethod: apply the passed transform's scale.








### Spawn.KismetPath
---
```lua
Spawn.KismetPath : string
```



Object path of the Kismet math function library class.








### Spawn.GameplayStaticsPath
---
```lua
Spawn.GameplayStaticsPath : string
```



Object path of the GameplayStatics class.









