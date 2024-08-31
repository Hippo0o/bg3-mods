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

---@type Async|function
async = setmetatable({}, {
    __index = function(_, key)
        local _, k = Utils.Table.Find(Async, function(_, k)
            return string.lower(key) == string.lower(k)
        end)

        if not k then
            return nil
        end

        return function(...)
            return Async[k](...)
        end
    end,
    __call = function(_, ...)
        return Async.Wrap(...)
    end,
})

---@vararg Chainable
await = function(...)
    local args = { ... }

    if #args == 1 then
        return Async.Sync(args[1])
    end

    return Async.SyncAll(args)
end
