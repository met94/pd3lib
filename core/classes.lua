--- Class resolution with ordered fallbacks and an incremental, non-fatal load
--- queue. Blueprint classes are commonly not loaded yet when a mod looks for
--- them, and a single bad path must never abort a roster: callers enqueue
--- paths, call `loader:Step()` once per tick (budget 1-2), retry on later
--- ticks and treat `false` as permanently gave up.
---
--- Resolution variants, in order:
---   1. `LoadAsset(object path)`  2. `StaticFindObject(object path)`
---   3. `LoadAsset(package path)` 4. `StaticFindObject(package path)`
--- Blueprint assets unwrap to their `GeneratedClass`.
---@class pd3.Classes
local Classes = {}

local Safe = require("pd3lib.core.safe")
local Log = require("pd3lib.core.log")

--- Ordered resolution variants for one object path. Paths without a dot have a
--- single unique argument, so only the two kinds remain.
---@param Path string
---@return { Kind: "LoadAsset"|"FindObject", Arg: string, Label: string }[] variants
function Classes.Variants(Path)
    if type(Path) ~= "string" or Path == "" then return {} end

    local Result = {
        { Kind = "LoadAsset", Arg = Path, Label = "LoadAsset(object)" },
        { Kind = "FindObject", Arg = Path, Label = "FindObject(object)" },
    }

    local Package = string.match(Path, "^(.*)%.[^%.]+$")
    if Package ~= nil and Package ~= Path then
        Result[#Result + 1] = { Kind = "LoadAsset", Arg = Package, Label = "LoadAsset(package)" }
        Result[#Result + 1] = { Kind = "FindObject", Arg = Package, Label = "FindObject(package)" }
    end
    return Result
end

--- Resolves a raw object to a UClass: class objects pass through, Blueprint
--- assets unwrap to their GeneratedClass, everything else is rejected.
---@param Obj any
---@return UObject? class
function Classes.ClassFromObject(Obj)
    if not Safe.IsValid(Obj) then return nil end

    local OkName, RawName = pcall(function() return Obj:GetClass():GetFName() end)
    if not OkName then return nil end

    local Name = Safe.String(RawName)
    if Name == "Class" or Name == "BlueprintGeneratedClass" then return Obj end
    if Name == "Blueprint" then
        local OkGenerated, Generated = pcall(function() return Obj.GeneratedClass end)
        if OkGenerated and Safe.IsValid(Generated) then return Generated end
    end

    return nil
end

--- Resolves one class path through all variants (single shot, no retry).
--- `LoadAsset` only works on the game thread.
---@param Path string
---@return UObject? class
---@return string? variant # label of the variant that succeeded
function Classes.Ensure(Path)
    for _, Variant in ipairs(Classes.Variants(Path)) do
        local Ok, Obj
        if Variant.Kind == "LoadAsset" then
            if type(LoadAsset) == "function" then
                Ok, Obj = pcall(LoadAsset, Variant.Arg)
            else
                Ok, Obj = false, "LoadAsset unavailable"
            end
        else
            Ok, Obj = pcall(StaticFindObject, Variant.Arg)
        end

        if Ok then
            local Class = Classes.ClassFromObject(Obj)
            if Class ~= nil then return Class, Variant.Label end
        elseif Safe.Verbose then
            Log.Debug("classes: %s failed: %s", Variant.Label, tostring(Obj))
        end
    end

    return nil
end

--- Incremental class load queue.
---@class pd3.Classes.Loader
---@field BudgetPerTick integer
---@field MaxAttempts integer

--- Creates a loader. `Opts.Resolve(path)` may be injected for tests; it must
--- return a class object or nil. The default resolver runs `Classes.Ensure`
--- (game thread only).
---@param Opts? { BudgetPerTick?: integer, MaxAttempts?: integer, Resolve?: fun(path: string): any, Log?: fun(fmt: string, ...: any) }
---@return pd3.Classes.Loader loader
function Classes.NewLoader(Opts)
    Opts = Opts or {}

    local Loader = {
        BudgetPerTick = Opts.BudgetPerTick or 2,
        MaxAttempts = Opts.MaxAttempts or 8,
        Resolve = Opts.Resolve or function(Path) return (Classes.Ensure(Path)) end,
        Log = Opts.Log,
        Queue = {},
        InQueue = {},
        States = {},
        Attempts = {},
    }

    --- Enqueues unresolved paths (resolved/failed ones are skipped). Returns
    --- the number of paths actually added.
    ---@param Paths string[]
    ---@return integer added
    function Loader:Enqueue(Paths)
        local Added = 0
        for _, Path in ipairs(Paths or {}) do
            if type(Path) == "string" and self.States[Path] == nil and not self.InQueue[Path] then
                self.InQueue[Path] = true
                self.Queue[#self.Queue + 1] = Path
                Added = Added + 1
            end
        end
        return Added
    end

    --- Processes up to BudgetPerTick queued paths. A path that keeps failing is
    --- marked `false` ("gave up") after MaxAttempts and dropped from the queue.
    ---@return integer processed
    ---@return integer resolved
    ---@return integer gaveUp
    function Loader:Step()
        local Processed, ResolvedCount, GaveUp = 0, 0, 0
        local Remaining = {}

        for _, Path in ipairs(self.Queue) do
            if Processed < self.BudgetPerTick then
                Processed = Processed + 1
                self.InQueue[Path] = nil

                local Class = self.Resolve(Path)
                if Class ~= nil then
                    self.States[Path] = Class
                    ResolvedCount = ResolvedCount + 1
                    if self.Log then self.Log("class ok: %s", Path) end
                else
                    local Attempts = (self.Attempts[Path] or 0) + 1
                    self.Attempts[Path] = Attempts
                    if Attempts >= self.MaxAttempts then
                        self.States[Path] = false
                        GaveUp = GaveUp + 1
                        if self.Log then self.Log("class gave up: %s", Path) end
                    else
                        Remaining[#Remaining + 1] = Path
                        self.InQueue[Path] = true
                    end
                end
            else
                Remaining[#Remaining + 1] = Path
            end
        end

        self.Queue = Remaining
        return Processed, ResolvedCount, GaveUp
    end

    --- Clears gave-up markers and re-enqueues them (e.g. after a level change).
    ---@return integer retried
    function Loader:RetryFailed()
        local Failed = {}
        for Path, State in pairs(self.States) do
            if State == false then Failed[#Failed + 1] = Path end
        end
        table.sort(Failed)

        local Retried = 0
        for _, Path in ipairs(Failed) do
            self.States[Path] = nil
            self.Attempts[Path] = nil
            Retried = Retried + self:Enqueue({ Path })
        end
        return Retried
    end

    --- Resolved class, `false` when gave up, nil when still pending.
    ---@param Path string
    ---@return any state
    function Loader:Get(Path)
        return self.States[Path]
    end

    --- Number of paths still queued.
    ---@return integer pending
    function Loader:Pending()
        return #self.Queue
    end

    return Loader
end

return Classes
