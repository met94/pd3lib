-- Pure/nil-safe tests for mission difficulty naming and the guarded setter.
local Mission = require("pd3lib.game.mission")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

check("name 0", Mission.DifficultyName(0) == "Normal")
check("name 1", Mission.DifficultyName(1) == "Hard")
check("name 2", Mission.DifficultyName(2) == "VeryHard")
check("name 3", Mission.DifficultyName(3) == "Overkill")
check("unknown index", Mission.DifficultyName(9) == "Unknown(9)")
check("nil index", Mission.DifficultyName(nil) == nil)

-- No live game instance in the test process: the setter must fail cleanly.
local Ok, Err = Mission.SetDifficultyIdx(1)
check("setter fails without game instance", Ok == false and type(Err) == "string")
check("difficulty idx nil without mission", Mission.DifficultyIdx() == nil)

return failures
