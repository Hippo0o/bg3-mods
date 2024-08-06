---@type Mod
local Mod = Require("Hlib/Mod")

---@type Constants
local Constants = Require("Hlib/Constants")

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

---@param prefix string|nil
---@return string
function M.RandomId(prefix)
    return tostring({}):gsub("table: ", prefix or "")
end

---@param code string x, y => x + y
---@vararg any injected arguments: x
---@return fun(...): any @function(y) -> x + y
function M.Lambda(code, ...)
    local argString, evalString = table.unpack(M.String.Split(code, "=>"))

    local args = M.Table.Map(M.String.Split(argString, ","), M.String.Trim)

    code = "return " .. M.String.Trim(evalString)

    local env = { _G = _G }

    -- Add vararg values to env with keys from args
    -- Remove from args those that are injected via vararg
    for i, arg in ipairs(M.Table.Values(args)) do
        env[arg] = select(i, ...)
        if select("#", ...) < i then
            table.remove(args, 1)
        end
    end

    return function(...)
        for i, arg in ipairs(args) do
            env[arg] = select(i, ...)
        end

        local ok, res = pcall(Ext.Utils.LoadString(code, env))
        if not ok then
            error('\n[Lambda]: "' .. code .. '"\n' .. res)
        end

        return res
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Entity                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Entity = {}

if Ext.IsServer() then
    ---@param character string GUID
    ---@return boolean
    function M.Entity.IsHireling(character)
        local faction = Osi.GetFaction(character)

        return faction and faction:match("^Hireling") ~= nil
    end

    ---@param character string GUID
    ---@return boolean
    function M.Entity.IsOrigin(character)
        local faction = Osi.GetFaction(character)
        if faction and (faction:match("^Origin") ~= nil or faction:match("^Companion") ~= nil) then
            return true
        end

        return M.Table.Find(Constants.OriginCharacters, function(v)
            return M.UUID.Equals(v, character)
        end) ~= nil
    end

    ---@param character string GUID
    ---@param includeParty boolean|nil Summons or QuestNPCs might be considered party members
    ---@return boolean
    function M.Entity.IsNonPlayer(character, includeParty)
        if not includeParty and (Osi.IsPartyMember(character, 1) == 1 or Osi.IsPartyFollower(character) == 1) then
            return false
        end
        return not M.Entity.IsOrigin(character) and not M.Entity.IsHireling(character) and Osi.IsPlayer(character) ~= 1
    end

    ---@param character string GUID
    ---@return boolean
    function M.Entity.IsPlayable(character)
        return M.Entity.IsOrigin(character)
            or M.Entity.IsHireling(character)
            or Osi.IsPlayer(character) == 1
            or (
                M.Table.Find(M.DB.GetAvatars(), function(v)
                    return M.UUID.Equals(v, character)
                end) ~= nil
            )
    end

    function M.Entity.IsImportant(character)
        return M.Entity.IsPlayable(character)
            or (
                M.Table.Find(Constants.NPCCharacters, function(v)
                    return M.UUID.Equals(v, character)
                end) ~= nil
            )
    end

    -- also works for items
    function M.Entity.Remove(guid)
        Osi.PROC_RemoveAllPolymorphs(guid)
        Osi.PROC_RemoveAllDialogEntriesForSpeaker(guid)
        Osi.SetOnStage(guid, 0)
        Osi.TeleportToPosition(guid, 0, 0, 0, "", 1, 1, 1, 1, 0) -- no blood
        Osi.Die(guid, 2, Constants.NullGuid, 0, 1)
        Osi.RequestDelete(guid)
        Osi.RequestDeleteTemporary(guid)
        Osi.UnloadItem(guid)
    end
end

---@return EntityHandle[]
function M.Entity.GetParty()
    return Ext.Entity.GetAllEntitiesWithComponent("PartyMember")
end

---@return EntityHandle
function M.Entity.GetHost()
    if Ext.IsClient() then
        --- might not give the correct entity
        return Ext.Entity.GetAllEntitiesWithComponent("ClientControl")[1]
    end

    return Ext.Entity.Get(Osi.GetHostCharacter())
end

---@class EntityDistance
---@field Entity EntityHandle
---@field Guid string GUID
---@field Distance number
---@param source string GUID
---@param radius number|nil
---@param ignoreHeight boolean|nil
---@param withComponent ExtComponentType|nil
---@return EntityDistance[]
-- thanks to AtilioA/BG3-volition-cabinet
function M.Entity.GetNearby(source, radius, ignoreHeight, withComponent)
    radius = radius or 1
    withComponent = withComponent or "Uuid"

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
    for _, entity in ipairs(Ext.Entity.GetAllEntitiesWithComponent(withComponent)) do
        local pos = entityPos(entity)
        if pos then
            local distance = calcDisance(pos)
            if distance <= radius then
                table.insert(nearby, {
                    Entity = entity,
                    Guid = entity.Uuid and entity.Uuid.EntityUuid,
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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Table                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Table = {}

---@param t1 table
---@vararg table
---@return table<string, any> t1
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
---@return table<number, any> t1
function M.Table.Combine(t1, ...)
    for _, t in ipairs({ ... }) do
        for _, v in pairs(t) do
            table.insert(t1, v)
        end
    end
    return t1
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
        return M.Equals(v, v2, true)
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

function M.Table.Pack(...)
    return { ... }
end

-- remove unserializeable values
---@param t table
---@param maxEntityDepth number|nil default: 1
---@return table
function M.Table.Clean(t, maxEntityDepth)
    maxEntityDepth = maxEntityDepth or 1

    return M.Table.Map(t, function(v, k)
        k = tonumber(k) or tostring(k)

        if type(v) == "userdata" then
            local ok, value = pcall(Ext.Types.Serialize, v)
            if ok then
                v = value
            elseif getmetatable(v) == "EntityProxy" then
                if maxEntityDepth <= 0 then
                    return tostring(v), k
                else
                    v = M.Table.Clean(v:GetAllComponents(), maxEntityDepth - 1)
                end
            else
                v = Ext.Json.Parse(Ext.Json.Stringify(v, {
                    Beautify = false,
                    StringifyInternalTypes = true,
                    IterateUserdata = true,
                    AvoidRecursion = true,
                }))
            end
        end

        if type(v) == "function" then
            return nil, k
        end

        if type(v) == "table" then
            return M.Table.Clean(v, maxEntityDepth), k
        end

        return v, k
    end)
end

---@param t table
---@param size number
---@return table
function M.Table.Batch(t, size)
    local r = {}
    local i = 1
    for _, v in pairs(t) do
        if not r[i] then
            r[i] = {}
        end
        table.insert(r[i], v)
        if #r[i] == size then
            i = i + 1
        end
    end
    return r
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           String                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.String = {}

function M.String.Escape(s)
    local matches = {
        ["^"] = "%^",
        ["$"] = "%$",
        ["("] = "%(",
        [")"] = "%)",
        ["%"] = "%%",
        ["."] = "%.",
        ["["] = "%[",
        ["]"] = "%]",
        ["*"] = "%*",
        ["+"] = "%+",
        ["-"] = "%-",
        ["?"] = "%?",
        ["\0"] = "%z",
    }
    return (s:gsub(".", matches))
end

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
---@param escape boolean|nil
---@return boolean
function M.String.Contains(s, patterns, ignoreCase, escape)
    if type(patterns) == "string" then
        patterns = { patterns }
    end
    for _, pattern in ipairs(patterns) do
        if escape then
            pattern = M.String.Escape(pattern)
        end

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
--                                             DB                                              --
--                                                                                             --
-------------------------------------------------------------------------------------------------

if Ext.IsServer() then
    M.DB = {}

    ---@param query string
    ---@param arity number
    ---@return table
    function M.DB.TryGet(query, arity)
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

    ---@return string[] list of avatar characters
    function M.DB.GetAvatars()
        return M.Table.Map(M.DB.TryGet("DB_Avatars", 1), function(v)
            return v[1]
        end)
    end

    ---@return string[] list of playable characters
    function M.DB.GetPlayers()
        return M.Table.Map(M.DB.TryGet("DB_Players", 1), function(v)
            return v[1]
        end)
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            UUID                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.UUID = {}

function M.UUID.IsValid(str)
    return M.UUID.Extract(str) ~= nil
end

function M.UUID.Extract(str)
    if type(str) ~= "string" then
        return nil
    end

    local x = "%x"
    local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
    local pattern = table.concat(t, "%-")

    return str:match(pattern)
end

function M.UUID.Equals(item1, item2)
    if type(item1) == "string" and type(item2) == "string" then
        return (M.UUID.Extract(item1) == M.UUID.Extract(item2))
    end

    return false
end

-- expensive operation
---@param uuid string
---@return boolean
function M.UUID.Exists(uuid)
    return Ext.Template.GetTemplate(uuid)
        or Ext.Mod.IsModLoaded(uuid)
        or Ext.Entity.GetAllEntitiesWithUuid()[uuid] and true
        or false
end

---@return string @UUIDv4
function M.UUID.Random()
    -- version 4 UUID
    return string.gsub("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx", "[xy]", function(c)
        local v = (c == "x") and M.Random(0, 0xf) or M.Random(8, 0xb)
        return string.format("%x", v)
    end)
end

---@param str string
---@param iteration number|nil
---@return string @UUIDv4
function M.UUID.FromString(str, iteration)
    local function hashToUUID(hash)
        return string.format(
            "%08x-%04x-4%03x-%04x-%012x",
            tonumber(hash:sub(1, 8), 16),
            tonumber(hash:sub(9, 12), 16),
            tonumber(hash:sub(13, 15), 16),
            tonumber(hash:sub(16, 19), 16) & 0x3fff | 0x8000,
            tonumber(hash:sub(20, 31), 16)
        )
    end

    local function simpleHash(input)
        local hash = 0
        local shift = 0
        for i = 1, #input do
            hash = (hash ~ ((string.byte(input, i) + i) << shift)) & 0xFFFFFFFF
            shift = (shift + 6) % 25
        end
        return string.format("%08x%08x%08x%08x", hash, hash ~ 0x55555555, hash ~ 0x33333333, hash ~ 0x11111111)
    end

    local prefix = ""
    for i = 1, (iteration or 1) do
        prefix = prefix .. Mod.UUID
    end

    return hashToUUID(simpleHash(prefix .. str))
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

local function logPrefix()
    local pre = Mod.Prefix .. " "
    if Mod.Debug then
        pre = pre .. (Ext.IsClient() and "[Client]" or "[Server]")
    end
    return pre
end

function M.Log.Info(...)
    Ext.Utils.Print(logPrefix() .. "[Info]", ...)
end

function M.Log.Warn(...)
    Ext.Utils.PrintWarning(logPrefix() .. "[Warning]", ...)
end

function M.Log.Debug(...)
    if Mod.Debug then
        Ext.Utils.Print(logPrefix() .. "[Debug]", ...)
    end
end

function M.Log.Dump(...)
    for i, v in pairs({ ... }) do
        M.Log.Debug(i .. ":", Ext.DumpExport(v))
    end
end

function M.Log.Error(...)
    Ext.Utils.PrintError(logPrefix() .. "[Error]", ...)
end

return M
