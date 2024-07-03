---@type Utils
local Utils = Require("Hlib/Utils")

---@class Libs
local M = {}

---@param props table|nil
---@return LibsStruct
function M.Struct(props)
    if not props then
        props = {}
    end

    if type(props) ~= "table" then
        error("Libs.Struct - table expected, got " .. type(props))
    end

    local propKeys = Utils.Table.Keys(props)

    ---@class LibsStruct
    ---@field New fun(): self
    ---@field Init fun(values: table|nil): table
    local Struct = {}
    Struct.__index = Struct

    function Struct.Init(values)
        if values ~= nil and type(values) ~= "table" then
            error("Struct.Init(values) - table expected, got " .. type(values))
        end

        local obj = {}
        setmetatable(obj, Struct)

        local keys = values and Utils.Table.Combine(Utils.Table.Values(propKeys), Utils.Table.Keys(values)) or propKeys
        for _, key in pairs(keys) do
            obj[key] = values and values[key] or Utils.Table.DeepClone(props[key])
        end

        return obj
    end

    function Struct.New()
        return Struct.Init()
    end

    return Struct
end

---@param typeDefs table { [1] = {"nil", "string"}, [2] = {"nil", {...enum}} }|{ ["key1"] = {"nil", "string"}, ["key2"] = {LibsTypedTable, ...} }
---@param repeatable boolean|nil true -> typeDefs = { "nil", "string", ... }|LibsTypedTable
---@return LibsTypedTable
function M.TypedTable(typeDefs, repeatable)
    if type(typeDefs) ~= "table" then
        error("Libs.TypedTable(typeDefs, ...) - table expected, got " .. type(typeDefs))
    end

    if typeDefs._IsTypedTable then
        typeDefs = { typeDefs }
    end

    if repeatable then
        typeDefs = { typeDefs }
    end

    -- exposed
    ---@class LibsTypedTable : LibsStruct
    ---@field Validate fun(table: table): boolean
    ---@field TypeCheck fun(key: string, value: any): boolean
    local TT = Libs.Struct({
        _IsTypedTable = true,
        _TypeDefs = {},
        _Repeatable = false,
    })

    ---@param key string
    ---@param value any
    ---@return boolean, string
    function TT:TypeCheck(key, value)
        if type(key) ~= "string" and type(key) ~= "number" then
            error("Libs.TypedTable:TypeCheck(key, ...) - string or number expected, got " .. type(key))
        end

        local typeDef = self._TypeDefs[key]
        if typeDef == nil then
            return false
        end

        if type(typeDef) ~= "table" then
            error("Libs.TypedTable.typeDefs[" .. key .. "] - table expected, got " .. type(typeDef))
        end

        local matchType = {
            ["string"] = function()
                return type(value) == "string"
            end,
            ["number"] = function()
                return type(value) == "number"
            end,
            ["boolean"] = function()
                return type(value) == "boolean"
            end,
            ["table"] = function()
                return type(value) == "table"
            end,
            ["function"] = function()
                return type(value) == "function"
            end,
            ["nil"] = function()
                return value == nil
            end,
        }

        if typeDef._IsTypedTable then
            typeDef = { typeDef }
        end

        local function test(validator)
            if type(validator) == "string" then
                if matchType[validator] and matchType[validator]() then
                    return true, type(value)
                end

                return false, validator .. " expected, got " .. type(value)
            end

            if type(validator) == "function" then
                local ok, res, err = pcall(validator, value)
                if not ok then
                    return false, res
                end

                return res and true or false, err
            end

            -- basically enum or reference to another TypedTable
            if type(validator) == "table" then
                if validator._IsTypedTable then
                    if type(value) ~= "table" then
                        return false, "table expected, got " .. type(value)
                    end

                    return TT.Init(validator):Validate(value)
                end

                for _, enum in pairs(validator) do
                    if Utils.Equals(enum, value, true) then
                        return true, value
                    end
                end

                return false, "value not in list of valid values"
            end

            return false
        end

        local valid, result
        for _, v in ipairs(typeDef) do
            valid, result = test(v)
            if valid then
                return true, result
            end
        end

        return false, result
    end

    function TT:Validate(tableToValidate)
        if type(tableToValidate) ~= "table" then
            return false, { "table expected, got " .. type(tableToValidate) }
        end

        -- should never happen
        if self._TypeDefs._IsTypedTable then
            self._TypeDefs = { self._TypeDefs }
        end

        local failed = {}
        local function validate(repeatableKey)
            for k, _ in pairs(self._TypeDefs) do
                local valid, error = self:TypeCheck(k, tableToValidate[repeatableKey or k])
                if not valid then
                    error = error or "value invalid"
                    failed[tostring(repeatableKey or k)] = error
                end
            end
        end

        if self._Repeatable then
            if Utils.Table.Size(tableToValidate) == 0 then
                validate(1)
            end
            for k, v in pairs(tableToValidate) do
                validate(k)
            end
        else
            validate()
        end

        return Utils.Table.Size(failed) == 0, failed
    end

    ---@return string[]|number[]
    function TT:GetFields()
        return Utils.Table.Keys(self._TypeDefs)
    end

    return TT.Init({
        _TypeDefs = typeDefs,
        _Repeatable = repeatable and true or false,
    })
end

---@class LibsChainable : LibsStruct
---@field After fun(self: LibsChainable, func: fun(source: any|nil, ...: any), passSource: boolean|nil): LibsChainable
---@field Catch fun(self: LibsChainable, func: fun(source: any|nil, err: string), passSource: boolean|nil): LibsChainable
---@field Source any
local Chainable = M.Struct({
    _IsChainable = nil,
    Source = nil,
    _InitalInput = {},
    _Chain = {},
    _Catch = {},
})
function Chainable.New(source)
    local obj = Chainable.Init()
    obj._IsChainable = Utils.RandomId("Chainable_")
    obj.Source = source
    obj._InitalInput = {}
    obj._Chain = {}

    return obj
end
function Chainable:After(func, passSource)
    if type(func) ~= "function" then
        error("Chainable:After(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { func, passSource })

    return self
end
function Chainable:Catch(func, passSource)
    if type(func) ~= "function" then
        error("Chainable:Catch(func) - function expected, got " .. type(func))
    end

    self._Catch = { func, passSource }

    return self
end
function Chainable:Throw(err)
    local func, passSource = table.unpack(self._Catch)

    if type(func) ~= "function" then
        error(err)
    end

    if passSource then
        func(self.Source, err)
    else
        func(err)
    end
end
function Chainable:Begin(...)
    local state = Utils.Table.Combine({ ... }, Utils.Table.DeepClone(self._InitalInput))

    for i, link in ipairs(self._Chain) do
        local func, passSource = table.unpack(link)

        local ok, err = pcall(function()
            if passSource then
                state = { func(self.Source, table.unpack(state)) }
            else
                state = { func(table.unpack(state)) }
            end
        end)

        if not ok then
            state = self:Throw(err)
            break
        end

        if state[1] == nil then
            break
        end

        -- interrupt chain if a nested chainable is returned
        if type(state[1]) == "table" and state[1]._IsChainable then
            ---@type Chainable
            local nested = state[1]

            local addonChain = Utils.Table.DeepClone(self._Chain)
            for j = 1, i do
                table.remove(addonChain, 1)
            end

            Utils.Table.Combine(nested._Chain, addonChain)

            nested._InitalInput = state
            table.remove(nested._InitalInput, 1)
            if self._Catch then
                nested._Catch = self._Catch
            end

            break
        end
    end

    return state
end

---@param source any
---@return LibsChainable
function M.Chainable(source)
    return Chainable.New(source)
end

---@param t table
---@param onSet fun(value: any, key: string, raw: table, parent: table|nil): any value
---@param onGet fun(value: any, key: string, raw: table, parent: table|nil): any value
---@return LibsProxy, fun(): table toTable
function M.Proxy(t, onSet, onGet)
    local raw = {}
    t = t or {}

    local proxy = false

    ---@class LibsProxy: table
    local Proxy = setmetatable({}, {
        __metatable = false,
        __name = "Proxy",
        __eq = function(self, other)
            -- create a closure around `t` to emulate shallow equality
            return rawequal(t, other) or rawequal(self, other)
        end,
        __pairs = function(self)
            -- wrap `next` to enable proxy hits during traversal
            return function(tab, key)
                local index, value = next(raw, key)

                return index, value ~= nil and self[index]
            end,
                self,
                nil
        end,
        -- these metamethods create closures around `actual`
        __len = function(self)
            return rawlen(raw)
        end,
        __index = function(self, key)
            local v = rawget(raw, key)
            if proxy and onGet then
                v = onGet(v, key, raw)
            end

            return v
        end,
        __newindex = function(self, key, value)
            if proxy and onSet then
                value = onSet(value, key, raw)
            end

            if type(value) == "table" then
                value = Libs.Proxy(value, function(sub, subKey, subValue)
                    local parent = {}
                    for k, v in pairs(raw) do
                        parent[k] = v
                    end

                    parent[key] = sub

                    if proxy and onSet then
                        return onSet(subValue, subKey, parent, raw)
                    end

                    return subValue
                end, function(sub, subKey, subValue)
                    local parent = {}
                    for k, v in pairs(raw) do
                        parent[k] = v
                    end

                    parent[key] = sub

                    if proxy and onGet then
                        return onGet(subValue, subKey, parent, raw)
                    end

                    return subValue
                end)
            end

            rawset(raw, key, value)
        end,
    })

    -- copy all values from `t` to `proxy`
    for key, value in pairs(t) do
        Proxy[key] = value
    end

    -- enable after initialization
    proxy = true

    -- recursively convert `proxy` to a table
    local function toTable(tbl)
        local t = {}
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                t[k] = toTable(v)
            else
                t[k] = v
            end
        end
        return t
    end

    return Proxy, function()
        return toTable(raw)
    end
end

return M
