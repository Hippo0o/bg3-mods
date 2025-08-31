---@type Utils
local Utils = Require("Hlib/Utils")

---@class Libs
local M = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Struct                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param props table|nil
---@return Struct
function M.Struct(props)
    if not props then
        props = {}
    end

    if type(props) ~= "table" then
        error("Libs.Struct - table expected, got " .. type(props))
    end

    local propKeys = Utils.Table.Keys(props)

    ---@class Struct
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

        local keys = values and Utils.Table.Extend(Utils.Table.Values(propKeys), Utils.Table.Keys(values)) or propKeys
        for _, key in pairs(keys) do
            obj[key] = values and values[key] or Utils.Table.DeepClone(props[key])
        end

        return obj
    end

    function Struct.New()
        return Struct.Init()
    end

    function Struct.IsInstanceOf(value)
        return type(value) == "table" and getmetatable(value) == Struct
    end

    return Struct
end
-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                         TypedTable                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- exposed
---@class TypedTable : Struct
---@field Validate fun(table: table): boolean
---@field TypeCheck fun(key: string, value: any): boolean
local TT = M.Struct({
    _TypeDefs = {},
    _Repeatable = false,
})

---@param key string
---@param value any
---@return boolean, string
function TT:TypeCheck(key, value)
    if type(key) ~= "string" and type(key) ~= "number" then
        error("TypedTable:TypeCheck(key, ...) - string or number expected, got " .. type(key))
    end

    local typeDef = self._TypeDefs[key]
    if typeDef == nil then
        return false
    end

    if type(typeDef) ~= "table" then
        error("TypedTable.typeDefs[" .. key .. "] - table expected, got " .. type(typeDef))
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

    if TT.IsInstanceOf(typeDef) then
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
            if TT.IsInstanceOf(validator) then
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
    if TT.IsInstanceOf(self._TypeDefs) then
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
        for k, _ in pairs(tableToValidate) do
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

---@param value any
---@return boolean
function M.IsTypedTable(value)
    return TT.IsInstanceOf(value)
end

---@param typeDefs table { [1] = {"nil", "string"}, [2] = {"nil", {...enum}} }|{ ["key1"] = {"nil", "string"}, ["key2"] = {TypedTable, ...} }
---@param repeatable boolean|nil true -> typeDefs = { "nil", "string", ... }|TypedTable
---@return TypedTable
function M.TypedTable(typeDefs, repeatable)
    if type(typeDefs) ~= "table" then
        error("Libs.TypedTable(typeDefs, ...) - table expected, got " .. type(typeDefs))
    end

    if TT.IsInstanceOf(typeDefs) then
        typeDefs = { typeDefs }
    end

    if repeatable then
        typeDefs = { typeDefs }
    end

    return TT.Init({
        _TypeDefs = typeDefs,
        _Repeatable = repeatable and true or false,
    })
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Chainable                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Chainable : Struct
---@field After fun(self: Chainable, func: fun(source: any|nil, ...: any): any, passSelf: boolean|nil, chainOnNil: boolean|nil): Chainable
---@field Catch fun(self: Chainable, func: fun(source: any|nil, err: string): any, passSelf: boolean|nil): Chainable
---@field Always fun(self: Chainable, func: fun(source: any|nil, success: boolean, ...: any): any, passSelf: boolean|nil): Chainable
---@field Stop fun(self: Chainable, func: fun(source: any|nil, success: boolean, ...: any): boolean, any, passSelf: boolean|nil): Chainable
---@field Source any
local Chainable = M.Struct({
    Source = nil,
    _InitalInput = {},
    _Chain = {},
    _Began = false,
})

-- callback to execute in order
-- will be skipped if the previous callback returned nil and chainOnNil is false
function Chainable:After(func, passSelf, chainOnNil)
    if type(func) ~= "function" then
        error("Chainable:After(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { exec = { func, passSelf, chainOnNil } })

    return self
end

-- callback to catch errors happening in the chain before
-- will continue the chain with the result of the catch
function Chainable:Catch(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Catch(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { catch = { func, passSelf } })

    return self
end

-- callback to execute even if the chain didn't catch an error
-- if the callback returns nil, the chain will continue with previous result
function Chainable:Always(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Always(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { always = { func, passSelf } })

    return self
end

-- callback to catch errors and stop the chain at this point
-- takes priority over catch if before catch
function Chainable:Stop(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Stop(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { stop = { func, passSelf } })

    return self
end

function Chainable:Throw(err)
    local catch = {}

    local alwaysLinks = {}
    for i, link in ipairs(self._Chain) do
        if link.stop then
            break
        end

        if link.always then
            table.insert(alwaysLinks, link)
        end

        if link.catch then
            catch = link.catch
            for _ = 1, i do
                table.remove(self._Chain, 1)
            end

            -- on first catch, prepend all always links found before it to the chain again
            for j = #alwaysLinks, 1, -1 do
                table.insert(self._Chain, 1, alwaysLinks[j])
            end

            break
        end
    end

    local func, passSelf = table.unpack(catch)

    if type(func) ~= "function" then
        return self:End(false, { err })
    end

    local result = {
        pcall(function()
            if passSelf then
                return func(self, err)
            end

            return func(err)
        end),
    }

    local success = table.remove(result, 1)
    if not success then
        return self:End(false, { table.unpack(result) })
    end

    if not self._Began then
        return self:Begin(table.unpack(result))
    end

    return table.unpack(result)
end

function Chainable:Begin(...)
    local state = Utils.Table.Extend({ ... }, self._InitalInput)
    self._InitalInput = {}
    self._Began = true

    local function createNested(state)
        ---@type Chainable
        local nested = state[1]

        Utils.Table.Extend(nested._Chain, self._Chain)

        self._Chain = {}

        nested._InitalInput = Utils.Table.Clone(state)
        table.remove(nested._InitalInput, 1)

        return nested
    end

    -- defer chain to nested chainable, same as inheritance tbh
    if Chainable.IsInstanceOf(state[1]) then
        return createNested(state)
    end

    local firstExec = true
    local appendedLinks = 0
    while #self._Chain > appendedLinks do
        local link = table.remove(self._Chain, appendedLinks + 1)

        local ok, err = pcall(function()
            if link.stop then
                table.insert(self._Chain, 1, link)
                state = { self:End(true, state) }
                return
            end

            if link.always then
                appendedLinks = appendedLinks + 1
                table.insert(self._Chain, appendedLinks, link)
                return
            end

            if not link.exec then
                return
            end

            local func, passSelf, chainOnNil = table.unpack(link.exec)
            if firstExec or state[1] ~= nil or chainOnNil then
                firstExec = false

                if passSelf then
                    state = { func(self, table.unpack(state)) }
                else
                    state = { func(table.unpack(state)) }
                end
            end
        end)

        if not ok then
            state = { self:Throw(err) }
        end

        -- interrupt chain if a nested chainable is returned
        if Chainable.IsInstanceOf(state[1]) then
            return createNested(state)
        end
    end

    return self:End(true, state)
end

---@param success boolean|nil
---@param state table|nil
---@return any
function Chainable:End(success, state)
    if success == nil then
        success = true
    end
    if state == nil then
        state = {}
    end

    while #self._Chain > 0 do
        local link = table.remove(self._Chain, 1)
        if link.stop then
            local func, passSelf = table.unpack(link.stop)
            if type(func) == "function" then
                local params = { success, table.unpack(state) }
                if passSelf then
                    table.insert(params, 1, self)
                end

                local result = { func(table.unpack(params)) }
                if #result > 0 then
                    success = table.remove(result, 1)
                    state = result
                end
            end

            break
        end

        if link.always then
            local func, passSelf = table.unpack(link.always)
            if type(func) == "function" then
                local ok, err = pcall(function()
                    local params = { success, table.unpack(state) }
                    if passSelf then
                        table.insert(params, 1, self)
                    end

                    local result = { func(table.unpack(params)) }
                    if #result > 0 then
                        state = result
                    end
                end)

                if not ok then
                    success = false
                    state = { err }
                end
            end
        end
    end

    if not success then
        self._Chain = {}
        self._Began = true
        error(table.unpack(state))
    end

    if not Chainable.IsInstanceOf(state[1]) then
        self._Chain = {}
    end

    if not self._Began then
        return self:Begin(table.unpack(state))
    end

    return table.unpack(state)
end

function Chainable:IsDone()
    return self._Began and #self._Chain == 0
end

---@param value any
---@return boolean
function M.IsChainable(value)
    return Chainable.IsInstanceOf(value)
end

---@param source any
---@return Chainable
function M.Chainable(source)
    local obj = Chainable.Init()
    obj.Source = source

    return obj
end

return M
