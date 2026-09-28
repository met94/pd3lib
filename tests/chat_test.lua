-- Pure tests for game.chat input guards and Reset (no engine objects required).
local Chat = require("pd3lib.game.chat")

local failures = 0
local function check(name, cond)
    if cond then
        print("PASS " .. name)
    else
        print("FAIL " .. name)
        failures = failures + 1
    end
end

check("empty message rejected", Chat.Send("") == false)
check("nil message rejected", Chat.Send(nil) == false)

local FormatOk, FormatErr = Chat.SendFmt("%d", "not-a-number")
check("format error rejected",
    FormatOk == false and type(FormatErr) == "string"
        and FormatErr:find("format error", 1, true) == 1)

-- Outside a level there is no chat sink: Send must return false, not raise.
local SendOk = Chat.Send("[test] no level")
check("send outside level is guarded", SendOk == false)

-- Reset clears the one-shot availability warning (called on level change).
Chat.Reset()
local SendAgain = Chat.Send("[test] still outside level")
check("send after reset is guarded", SendAgain == false)

return failures
