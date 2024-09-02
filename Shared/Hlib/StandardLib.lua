---@type Utils
local Utils = Require("Hlib/Utils")

---@type Async
local Async = Require("Hlib/Async")

table.merge = Utils.Table.Merge
table.map = Utils.Table.Map
table.filter = Utils.Table.Filter
table.find = Utils.Table.Find
table.keys = Utils.Table.Keys
table.values = Utils.Table.Values
table.clone = Utils.Table.Clone
table.deepclone = Utils.Table.DeepClone
table.combine = Utils.Table.Combine
table.size = Utils.Table.Size
table.each = Utils.Table.Each
table.contains = Utils.Table.Contains
table.removevalue = Utils.Table.Remove
---@param t table
---@param key any
---@return table t
table.removekey = function(t, key)
    t[key] = nil
    return t
end

string.split = Utils.String.Split
string.trim = Utils.String.Trim
string.contains = Utils.String.Contains
string.imatch = Utils.String.IMatch
string.escape = Utils.String.Escape
string.lcfirst = Utils.String.LowerFirst
string.ucfirst = Utils.String.UpperFirst

fn = Utils.Lambda

eq = Utils.Equals

get = Utils.GetProperty

async = Async.Wrap

---@class Await
---@field condition fun(cond: fun(self: Runner, chainable: ChainableRunner): boolean): boolean|nil
---@field sleep fun(ms: number)
---@field ticks fun(ticks: number)
---@field retry fun(cond: fun(self: Runner, triesLeft: number, chainable: ChainableRunner): boolean, opts: RetryForOptions|nil): boolean|any
---@type Await|fun(chainable: ChainableRunner): any|fun(chainables: ChainableRunner[]): table<number, any>
await = setmetatable({}, {
    condition = function(cond)
        return Async.Sync(Async.WaitUntil(cond))
    end,
    sleep = function(ms)
        return Async.Sync(Async.Defer(ms))
    end,
    ticks = function(ticks)
        return Async.Sync(Async.WaitTicks(ticks))
    end,
    retry = function(cond, opts)
        return Async.Sync(Async.RetryUntil(cond, Utils.Table.Merge({ throw = true }, opts)))
    end,
    __call = function(_, ...)
        local args = { ... }

        if #args == 1 then
            return Async.Sync(args[1])
        end

        return Async.SyncAll(args)
    end,
})
