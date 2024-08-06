---@type Libs
local Libs = Require("Hlib/Libs")

---@type Utils
local Utils = Require("Hlib/Utils")

---@class Async
local M = {}

---@class Loop : LibsClass
---@field Startable boolean
---@field Queues Queue[]
---@field Handle number|nil
---@field Tasks { Count: number, Inc: fun(self: Loop.Tasks), Dec: fun(self: Loop.Tasks) }
---@field IsRunning fun(self: Loop): boolean
---@field IsEmpty fun(self: Loop): boolean
---@field Start fun(self: Loop)
---@field Stop fun(self: Loop)
---@field Tick fun(self: Loop, time: GameTime)
local Loop = Libs.Class({
    Startable = true,
    Queues = {},
    Tasks = {
        Count = 0,
        Inc = function(self)
            self.Count = self.Count + 1
        end,
        Dec = function(self)
            self.Count = self.Count - 1
        end,
    },
    Handle = nil,
    IsRunning = function(self) ---@param self Loop
        return self.Handle ~= nil
    end,
    IsEmpty = function(self) ---@param self Loop
        if self.Tasks.Count > 0 then
            return false
        end

        local count = 0
        for _, queue in ipairs(self.Queues) do
            count = count + #queue.Tasks
        end
        return count == 0
    end,
    Start = function(self) ---@param self Loop
        assert(self.Handle == nil, "Loop already running.")
        if not self.Startable or self:IsEmpty() then
            return
        end

        local ticks = 0
        self.Handle = Ext.Events.Tick:Subscribe(function(e)
            if self:IsEmpty() then
                self:Stop()
                return
            end

            self:Tick(e.Time)

            ticks = ticks + 1
            if ticks % 3000 == 0 then
                Utils.Log.Warn("Loop is running for too long.", "Ticks:", ticks, "Tasks:", self.Tasks.Count)
                Utils.Log.Dump(self)
            end
        end)
    end,
    Stop = function(self) ---@param self Loop
        assert(self.Handle ~= nil, "Loop not running.")
        Ext.Events.Tick:Unsubscribe(self.Handle)
        self.Handle = nil
    end,
    Tick = function(self, time) ---@param self Loop
        for _, queue in ipairs(self.Queues) do
            for _, runner in queue:Iter() do
                local success, result = pcall(function()
                    if runner:ExecCond(time) then
                        runner:Exec(time)

                        if runner:ClearCond(time) then
                            runner:Clear()
                        end

                        return true
                    end
                end)

                if not success then
                    Utils.Log.Error("Async", result)
                    runner:Clear()
                    return
                end

                if result == true then -- only 1 task per tick
                    return
                end
            end
        end
    end,
})

---@class Queue : LibsClass
---@field Loop Loop
---@field Tasks table<number, { idx: number, item: Runner }>
---@field Enqueue fun(self: Queue, item: Runner): string
---@field Dequeue fun(self: Queue, idx: number)
---@field Iter fun(self: Queue): fun(): number, Runner
---@field New fun(loop: Loop): Queue
local Queue = Libs.Class({
    Loop = nil,
    Tasks = {},
    Enqueue = function(self, item) ---@param self Queue
        local idx = Utils.RandomId("Queue_")
        table.insert(self.Tasks, { idx = idx, item = item })

        self.Loop.Tasks:Inc()
        if not self.Loop:IsRunning() then
            self.Loop:Start()
        end

        if Mod.Dev then
            Utils.Log.Debug("Queue/Enqueue", self.Loop.Tasks.Count, idx)
        end

        return idx
    end,
    Dequeue = function(self, idx) ---@param self Queue
        for i, v in ipairs(self.Tasks) do
            if v.idx == idx then
                table.remove(self.Tasks, i)
                self.Loop.Tasks:Dec()

                if Mod.Dev then
                    Utils.Log.Debug("Queue/Dequeue", self.Loop.Tasks.Count, idx)
                end

                return
            end
        end
    end,
    Iter = function(self) ---@param self Queue
        local i = 0
        return function()
            i = i + 1
            if self.Tasks[i] then
                return i, self.Tasks[i].item
            end
        end
    end,
})

---@param loop Loop
---@return Queue
function Queue.New(loop)
    local obj = Queue.Init({
        Loop = loop,
    })

    table.insert(loop.Queues, obj)

    return obj
end

-- exposed
---@class Runner : LibsClass
---@field Cleared boolean
---@field ExecCond fun(self: Runner, time: GameTime): boolean
---@field Exec fun(self: Runner, time: GameTime)
---@field ClearCond fun(self: Runner, time: GameTime): boolean
---@field Clear fun(self: Runner)
local Runner = Libs.Class({
    Cleared = false,
    ExecCond = function(_, _)
        return true
    end,
    Exec = function(_, _) end,
    ClearCond = function(_, _)
        return true
    end,
})

---@param queue Queue
---@param func fun()
---@return Runner
function Runner.New(queue, func)
    local obj = Runner.Init()
    obj.Exec = func

    local tid = queue:Enqueue(obj)
    obj.Clear = function()
        queue:Dequeue(tid)
        obj.Cleared = true
    end

    return obj
end

---@type Loop
local loop = Loop.New()
---@type Queue
local prio = Queue.New(loop)
---@type Queue
local lowPrio = Queue.New(loop)

---@type GameState
local GameState = Require("Hlib/GameState")
-- TODO save loop state in SavingAction or run all tasks from prio queue at once
GameState.OnUnload(function()
    if loop:IsRunning() then
        loop:Stop()
    end
end)
GameState.OnSave(function()
    if loop:IsRunning() then
        loop:Stop()
    end
end)
GameState.OnLoadSession(function()
    loop.Startable = false
end)
GameState.OnLoad(function()
    loop.Startable = true
    if not loop:IsRunning() then
        loop:Start()
    end
end)

---@param ms number
---@param func fun(self: Runner, time: GameTime)
---@return Runner
function M.Defer(ms, func)
    local seconds = ms / 1000
    local last = 0

    local runner = Runner.New(prio, func)

    runner.ExecCond = function(_, time)
        last = last + time.DeltaTime
        return last >= seconds
    end

    return runner
end

---@param func fun()
---@return Runner
function M.Run(func)
    return Runner.New(prio, func)
end

---@param func fun()
---@return Runner
function M.Schedule(func)
    return Runner.New(lowPrio, func)
end

---@param ms number
---@param func fun(self: Runner, time: GameTime)
---@return Runner
function M.Interval(ms, func)
    local seconds = ms / 1000
    local last = 0
    local skip = false -- avoid consecutive executions
    local runner = Runner.New(lowPrio, func)

    runner.ExecCond = function(_, time)
        last = last + time.DeltaTime

        local cond = last >= seconds and not skip
        if cond then
            last = 0
        end
        skip = cond

        return cond
    end

    runner.ClearCond = function(_, _)
        return false
    end

    return runner
end

---@param cond fun(self: Runner, time: GameTime): boolean
---@param func fun(self: Runner, time: GameTime)
---@return Runner
-- check for condition every ~100ms
function M.WaitFor(cond, func)
    local runner = Runner.New(prio, func)
    local last = 0

    runner.ExecCond = function(self, time)
        last = last + time.DeltaTime
        if last < 0.1 then
            return false
        end
        last = 0
        return cond(self, time)
    end

    return runner
end

---@class RetryForOptions
---@field retries number|nil default: 3, -1 for infinite
---@field success fun(result: any)|nil
---@field failed fun(error)|nil error object
---@field interval number|nil default: 1000
---@field immediate boolean|nil default: false, GameTime is not available
---@param cond fun(self, triesLeft: number, time: GameTime): boolean
---@param options RetryForOptions|nil
---@return Runner
-- retries every (default: 1000 ms) until condition is met or tries(default: 3) are exhausted
function M.RetryFor(cond, options)
    options = options or {}
    local retries = options.retries or 3
    local success = options.success
    local failed = options.failed
    local interval = options.interval or 1000
    local immediate = options.immediate or false

    local runner = M.Interval(interval, function(self, time)
        local ok, result = pcall(cond, self, retries, time)
        if ok and result then
            self:Clear()
            if success then
                success(result)
            end
            return
        end

        if not ok then
            L.Debug("RetryFor error:", result)
        end

        retries = retries - 1

        if retries == 0 then
            self:Clear()
            if failed then
                failed(result)
            end
        end
    end)

    if immediate then
        runner:Exec()
    end

    return runner
end

---@param ms number
---@param func fun(...)
---@return fun(...)
-- will create a function that is debounced
function M.Debounce(ms, func)
    local runner

    return function(...)
        if runner then
            runner:Clear()
        end

        local args = { ... }
        runner = M.Defer(ms, function()
            func(table.unpack(args))
        end)
    end
end

---@param ms number
---@param func fun(...)
---@return fun(...)
-- will create a function that is throttled
function M.Throttle(ms, func)
    local canRun = true

    return function(...)
        if not canRun then
            return
        end
        canRun = false
        M.Defer(ms, function()
            canRun = true
        end)

        func(...)
    end
end

return M
