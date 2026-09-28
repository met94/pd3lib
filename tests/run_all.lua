-- Pure-function test runner (fengari). Run from anywhere:
--   fengari.cmd tests/run_all.lua
-- Suites must run without the game: only engine-free code paths are covered.
local Source = (debug.getinfo(1, "S").source or ""):gsub("^@", ""):gsub("\\", "/")
local Root = string.match(Source, "^(.*)/tests/[^/]+$")
local Parent
if Root == nil then
    Root = "."
    Parent = ".."
else
    Parent = string.match(Root, "^(.*)/[^/]+$")
end
package.path = Parent .. "/?.lua;" .. package.path

local Suites = {
    "safe_test.lua",
    "world_test.lua",
    "classes_test.lua",
    "chat_test.lua",
    "spawn_test.lua",
    "ai_test.lua",
    "weapons_test.lua",
    "mission_test.lua",
}

local Failures = 0
for _, Name in ipairs(Suites) do
    local Path = Root .. "/tests/" .. Name
    print("== " .. Name)
    local Ok, Result = pcall(dofile, Path)
    if not Ok then
        print("ERROR " .. Name .. ": " .. tostring(Result))
        Failures = Failures + 1
    else
        Failures = Failures + (tonumber(Result) or 0)
    end
end

if Failures > 0 then
    print(string.format("FAILURES: %d", Failures))
    os.exit(1)
end
print("ALL PASS")
os.exit(0)
