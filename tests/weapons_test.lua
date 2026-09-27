-- Pure tests for weapon falloff breakpoint conversion and live FireData reads
-- against fake objects (the live pawn chain is in-game only).
local Weapons = require("pd3lib.game.weapons")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

local Distances = Weapons.DistancesFromCm({ 250, 1000, 250 }, { 2500, 500 })
check("union dedupe length", #Distances == 4)
check("sorted ascending", Distances[1] == 2.5 and Distances[2] == 5
    and Distances[3] == 10 and Distances[4] == 25)
check("rounds to 2 decimals", Weapons.DistancesFromCm({ 123 }, nil)[1] == 1.23)
check("ignores zero and negative", #Weapons.DistancesFromCm({ 0, -5 }, nil) == 0)
check("nil safe", #Weapons.DistancesFromCm(nil, nil) == 0)

local Fire = {
    DamageDistanceArray = { { Distance = 250 }, { Distance = 1000 } },
    CriticalDamageMultiplierDistanceArray = { { Distance = 500 } },
}
local DamageCm, CritCm = Weapons.BreakpointsCm(Fire)
check("damage field read", #DamageCm == 2 and DamageCm[1] == 250 and DamageCm[2] == 1000)
check("crit field read", #CritCm == 1 and CritCm[1] == 500)
local Meters = Weapons.BreakpointsMeters(Fire)
check("meters union", #Meters == 3 and Meters[1] == 2.5 and Meters[2] == 5 and Meters[3] == 10)

local Sparse = setmetatable({ GetArrayNum = function() return 2 end }, {
    __index = function(_, Key)
        if Key == 1 then return { Distance = 700 } end
        if Key == 2 then return { Distance = 900 } end
    end,
})
local SparseField = Weapons.DistanceFieldCm({ Arr = Sparse }, "Arr")
check("GetArrayNum fallback", SparseField ~= nil and #SparseField == 2 and SparseField[1] == 700)

check("missing field nil", Weapons.DistanceFieldCm(Fire, "Nope") == nil)
check("empty fire yields no meters", #Weapons.BreakpointsMeters({}) == 0)
check("nil fire yields no meters", #Weapons.BreakpointsMeters(nil) == 0)

return failures
