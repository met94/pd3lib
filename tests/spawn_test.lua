-- Pure tests for game.spawn math (engine paths are in-game only).
local Spawn = require("pd3lib.game.spawn")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

check("facing yaw 0 -> 180", Spawn.FacingYaw(0) == 180)
check("facing yaw 350 -> 170", Spawn.FacingYaw(350) == 170)
check("facing yaw 180 -> 0", Spawn.FacingYaw(180) == 0)
check("facing yaw wraps above 360", Spawn.FacingYaw(370) == 190)

local X, Y = Spawn.OffsetLocation(100, 200, 0, 500)
check("offset yaw 0 -> +X", X == 600 and Y == 200)
local X2, Y2 = Spawn.OffsetLocation(100, 200, 90, 500)
check("offset yaw 90 -> +Y", math.abs(X2 - 100) < 1e-9 and math.abs(Y2 - 700) < 1e-9)
local X3, Y3 = Spawn.OffsetLocation(100, 200, 180, 500)
check("offset yaw 180 -> -X", math.abs(X3 - (-400)) < 1e-9 and math.abs(Y3 - 200) < 1e-9)

check("yaw radians", math.abs(Spawn.YawRadians(180) - math.pi) < 1e-12)
check("enum constants", Spawn.AlwaysSpawn == 0 and Spawn.TransformScale == 1)
check("class paths", Spawn.KismetPath == "/Script/Engine.KismetMathLibrary"
    and Spawn.GameplayStaticsPath == "/Script/Engine.GameplayStatics")

return failures
