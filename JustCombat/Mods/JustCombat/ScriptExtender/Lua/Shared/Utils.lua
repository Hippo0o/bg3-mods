---@diagnostic disable: undefined-global

---@type Mod
local Mod = Require("Shared/Mod")

---@type Constants
local Constants = Require("Shared/Constants")

---@class Utils
local M = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Generic                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param v1 any
---@param v2 any
---@param ignoreMT boolean|nil ignore metatables
function M.Equals(v1, v2, ignoreMT)
    if v1 == v2 then
        return true
    end

    local v1Type = type(v1)
    local v2Type = type(v2)
    if v1Type ~= v2Type then
        return false
    end
    if v1Type ~= "table" then
        return false
    end

    if not ignoreMT then
        local mt1 = getmetatable(v1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return v1 == v2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(v1) do
        local value2 = v2[key1]
        if value2 == nil or M.Equals(value1, value2, ignoreMT) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(v2) do
        if not keySet[key2] then
            return false
        end
    end

    return true
end

-- probably useless
function M.Random(...)
    local time = Ext.Utils.MonotonicTime()
    local rand = Ext.Math.Random(...)
    local args = { ... }

    if #args == 0 then
        local r1 = math.floor(rand * time)
        local r2 = math.ceil(rand * time)
        rand = Ext.Math.Random(r1, r2) / time
        return rand
    end

    if #args == 1 then
        args[2] = args[1]
        args[1] = 1
    end

    rand = Ext.Math.Random(args[1] + rand * time, args[2] + rand * time) / time
    return Ext.Math.Round(rand)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Entity                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Entity = {}

---@return string[] list of avatar characters
function M.Entity.GetAvatars()
    return M.Table.Map(M.Protected.TryGetDB("DB_Avatars", 1), function(v)
        return v[1]
    end)
end

---@return string[] list of playable characters
function M.Entity.GetPlayers()
    return M.Table.Map(M.Protected.TryGetDB("DB_Players", 1), function(v)
        return v[1]
    end)
end

---@param character string GUID
---@return boolean
function M.Entity.IsHireling(character)
    local faction = Osi.GetFaction(character)

    return faction:match("^Hireling") ~= nil
end

---@param character string GUID
---@return boolean
function M.Entity.IsOrigin(character)
    local faction = Osi.GetFaction(character)

    local UUIDChar = M.UUID.GetGUID(character)

    return faction:match("^Origin") ~= nil
        or faction:match("^Companion") ~= nil
        or (
            #M.Table.Filter(Constants.OriginCharacters, function(v)
                return M.UUID.Equals(v, UUIDChar)
            end) > 0
        )
end

---@param character string GUID
---@param includeParty boolean|nil Summons or QuestNPCs might be considered party members
---@return boolean
function M.Entity.IsNonPlayer(character, includeParty)
    if not includeParty and (Osi.IsPartyMember(character, 1) == 1 or Osi.IsPartyFollower(character) == 1) then
        return false
    end
    return not M.Entity.IsOrigin(character) and not M.Entity.IsHireling(character) and Osi.IsPlayer(character) == 0
end

---@param character string GUID
---@return boolean
function M.Entity.IsPlayable(character)
    return M.Entity.IsOrigin(character)
        or M.Entity.IsHireling(character)
        or Osi.IsPlayer(character) == 1
        or (
            M.Table.Find(M.Entity.GetAvatars(), function(v)
                return M.UUID.Equals(v, character)
            end) ~= nil
        )
end

---@class EntityDistance
---@field Entity EntityHandle
---@field Guid string GUID
---@field Distance number
---@param source string GUID
---@param radius number|nil
---@param ignoreHeight boolean|nil
---@return EntityDistance[]
-- thanks to AtilioA/BG3-volition-cabinet
function M.Entity.GetNearby(source, radius, ignoreHeight)
    radius = radius or 1

    ---@param entity string|EntityHandle GUID
    ---@return number[]|nil {x, y, z}
    local function entityPos(entity)
        entity = type(entity) == "string" and Ext.Entity.Get(entity) or entity
        local ok, pos = pcall(function()
            return entity.Transform.Transform.Translate
        end)
        if ok then
            return { pos[1], pos[2], pos[3] }
        end
        return nil
    end

    local sourcePos = entityPos(source)
    if not sourcePos then
        return {}
    end

    ---@param target number[] {x, y, z}
    ---@return number
    local function calcDisance(target)
        return math.sqrt(
            (sourcePos[1] - target[1]) ^ 2
                + (not ignoreHeight and (sourcePos[2] - target[2]) ^ 2 or 0)
                + (sourcePos[3] - target[3]) ^ 2
        )
    end

    local nearby = {}
    for _, entity in ipairs(Ext.Entity.GetAllEntitiesWithComponent("Uuid")) do
        local pos = entityPos(entity)
        if pos then
            local distance = calcDisance(pos)
            if distance <= radius then
                table.insert(nearby, {
                    Entity = entity,
                    Guid = entity.Uuid.EntityUuid,
                    Distance = distance,
                })
            end
        end
    end

    table.sort(nearby, function(a, b)
        return a.Distance < b.Distance
    end)
    return nearby
end

-- also works for items
function M.Entity.Remove(guid)
    Osi.SetOnStage(guid, 0)
    Osi.TeleportToPosition(guid, 0, 0, 0, "", 1, 1, 1, 1, 0) -- no blood
    Osi.RequestDelete(guid)
    Osi.Die(guid, 2, Constants.NullGuid, 0, 1)
    Osi.UnloadItem(guid)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Table                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Table = {}

---@param t1 table
---@vararg table
---@return table<string, any>
function M.Table.Merge(t1, ...)
    for _, t2 in ipairs({ ... }) do
        for k, v in pairs(t2) do
            t1[k] = v
        end
    end
    return t1
end

---@param t1 table<number, any>
---@vararg table
---@return table<number, any>
function M.Table.Combine(t1, ...)
    local r = {}
    for _, t in ipairs({ t1, ... }) do
        for _, v in pairs(t) do
            table.insert(r, v)
        end
    end
    return r
end

function M.Table.Size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---@param t table<number, any> e.g. { 1, 2, 3 } or { {v=1}, {v=2}, {v=3} }
---@param remove any|table<number, any> e.g. 2 or {v=2}
---@param multiple boolean|nil remove is a table of remove e.g. { 2, 3 } or { {v=2}, {v=3} }
---@return table t
function M.Table.Remove(t, remove, multiple)
    for i = #t, 1, -1 do
        if multiple then
            for _, value in ipairs(remove) do
                if M.Equals(t[i], value, true) then
                    table.remove(t, i)
                    break
                end
            end
        else
            if M.Equals(t[i], remove, true) then
                table.remove(t, i)
            end
        end
    end
    return t
end

---@param t table
---@param seen table|nil used to prevent infinite recursion
---@return table
function M.Table.DeepClone(t, seen)
    -- Handle non-tables and previously-seen tables.
    if type(t) ~= "table" then
        return t
    end
    if seen and seen[t] then
        return seen[t]
    end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[t] = res
    for k, v in pairs(t) do
        res[M.Table.DeepClone(k, s)] = M.Table.DeepClone(v, s)
    end
    return setmetatable(res, getmetatable(t))
end

---@param t table
---@param func function @function(value, key) -> value: any|nil, key: any|nil
---@return table
function M.Table.Map(t, func)
    local r = {}
    for k, v in pairs(t) do
        local value, key = func(v, k)
        if value ~= nil then
            if key ~= nil then
                r[key] = value
            else
                table.insert(r, value)
            end
        end
    end
    return r
end

---@param t table
---@param func function @function(value, key) -> boolean
---@return table
function M.Table.Filter(t, func, keepKeys)
    return M.Table.Map(t, function(v, k)
        if func(v, k) then
            if keepKeys then
                return v, k
            else
                return v
            end
        end
    end)
end

---@param t table table to search
---@param v any value to search for
---@param count boolean|nil return count instead of boolean
---@return boolean|number
function M.Table.Contains(t, v, count)
    local r = #M.Table.Filter(t, function(v2)
        return v == v2
    end)
    return count and r or r > 0
end

---@param t table table to search
---@param func function @function(value, key) -> boolean
---@return any|nil, string|number|nil @value, key
function M.Table.Find(t, func)
    for k, v in pairs(t) do
        if func(v, k) then
            return v, k
        end
    end
    return nil, nil
end

---@param t table
---@return table
function M.Table.Keys(t)
    return M.Table.Map(t, function(_, k)
        return k
    end)
end

---@param t table
---@return table
function M.Table.Values(t)
    return M.Table.Map(t, function(v)
        return v
    end)
end

---@param t table<number, string>
---@return table<string, number>
function M.Table.Set(t)
    return M.Table.Map(t, function(v, k)
        return k, tostring(v)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           String                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.String = {}

-- same as string.match but case insensitive
function M.String.IMatch(s, pattern, init)
    s = string.lower(s)
    pattern = string.lower(pattern)
    return string.match(s, pattern, init)
end

function M.String.MatchAfter(s, prefix)
    return string.match(s, prefix .. "(.*)")
end

---@param s string
---@param patterns string[]|string
---@param ignoreCase boolean|nil
---@return boolean
function M.String.Contains(s, patterns, ignoreCase)
    if type(patterns) == "string" then
        patterns = { patterns }
    end
    for _, pattern in ipairs(patterns) do
        if ignoreCase then
            if M.String.IMatch(s, pattern) ~= nil then
                return true
            end
        else
            if string.match(s, pattern) ~= nil then
                return true
            end
        end
    end
    return false
end

---@param s string
---@return string
function M.String.Trim(s)
    return s:match("^%s*(.-)%s*$")
end

---@param s string
---@param sep string
---@return string[]
function M.String.Split(s, sep)
    local r = {}
    for match in (s .. sep):gmatch("(.-)" .. sep) do
        table.insert(r, match)
    end
    return r
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Protected                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Protected = {}

function M.Protected.TryGetProxy(entity, proxy)
    if entity[proxy] ~= nil then
        return entity[proxy]
    else
        error("Not a valid proxy")
    end
end

---@param query string
---@param arity number
---@return table
function M.Protected.TryGetDB(query, arity)
    local success, result = pcall(function()
        local db = Osi[query]
        if db and db.Get then
            return db:Get(table.unpack({}, 1, arity))
        end
    end)

    if success then
        return result
    else
        M.Log.Error("Failed to get DB", query, result)
        return {}
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            UUID                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.UUID = {}

function M.UUID.IsGUID(str)
    local x = "%x"
    local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
    local pattern = table.concat(t, "%-")

    return str:match(pattern)
end

function M.UUID.GetGUID(str)
    if str ~= nil and type(str) == "string" then
        return string.sub(str, (string.find(str, "_[^_]*$") ~= nil and (string.find(str, "_[^_]*$") + 1) or 0), nil)
    end
    return ""
end

function M.UUID.Equals(item1, item2)
    if type(item1) == "string" and type(item2) == "string" then
        return (M.UUID.GetGUID(item1) == M.UUID.GetGUID(item2))
    end

    return false
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Osiris                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Osiris = {}

---@class OsirisEventListener
---@field SubscriberId number
---@field Params table name, arity, typeName, callback
---@field Unregister fun(self: OsirisEventListener): boolean
---@param name string Osi.Events
---@param arity number callback arguments
---@param typeName string before, beforeDelete, after or afterDelete
---@param callback fun(...)
---@return OsirisEventListener
function M.Osiris.On(name, arity, typeName, callback)
    local id = Ext.Osiris.RegisterListener(name, arity, typeName, callback)

    return {
        SubscriberId = id,
        Params = { name, arity, typeName, callback },
        Unregister = function(self)
            return Ext.Osiris.UnregisterListener(self.SubscriberId)
        end,
    }
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Logging                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Log = {}

function M.Log.Info(...)
    Ext.Utils.Print(Mod.ModPrefix .. (Ext.IsClient() and " [Client]" or " ") .. "[Info]", ...)
end

function M.Log.Warn(...)
    Ext.Utils.PrintWarning(Mod.ModPrefix .. (Ext.IsClient() and " [Client]" or " ") .. "[Warning]", ...)
end

function M.Log.Debug(...)
    if Mod.Debug then
        Ext.Utils.Print(Mod.ModPrefix .. (Ext.IsClient() and " [Client]" or " ") .. "[Debug]", ...)
    end
end

function M.Log.Dump(...)
    for i, v in pairs({ ... }) do
        M.Log.Debug(i .. ":", Ext.DumpExport(v))
    end
end

function M.Log.Error(...)
    Ext.Utils.PrintError(Mod.ModPrefix .. (Ext.IsClient() and " [Client]" or " ") .. "[Error]", ...)
end

return M
