-- Pure tests for core.safe.IsValid dispatch (global first, method fallback).
local Safe = require("pd3lib.core.safe")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

-- Global IsValid is preferred when the UE4SS build exposes it.
IsValid = function(Value)
    if Value == "boom" then error("native failure") end
    return Value ~= nil and Value.valid == true
end

check("nil is invalid", Safe.IsValid(nil) == false)
check("global IsValid accepted", Safe.IsValid({ valid = true }) == true)
check("global IsValid rejected", Safe.IsValid({ valid = false }) == false)
check("global IsValid error swallowed", Safe.IsValid("boom") == false)

-- Method fallback when the global is absent.
IsValid = nil
local MethodValid = { valid = true }
MethodValid.IsValid = function(self) return self.valid end
check("method fallback valid", Safe.IsValid(MethodValid) == true)
check("method fallback missing method", Safe.IsValid({}) == false)
local MethodErr = { IsValid = function() error("no") end }
check("method error swallowed", Safe.IsValid(MethodErr) == false)

-- A non-function global must not shadow the method fallback.
IsValid = "not a function"
check("non-function global ignored", Safe.IsValid(MethodValid) == true)
IsValid = nil

return failures
