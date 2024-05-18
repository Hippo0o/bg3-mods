---@type Utils
local Utils = Require("Hlib/Utils")

---@class Libs
local M = {}

---@param props table|nil
---@return LibsClass
function M.Class(props)
    if not props then
        props = {}
    end

    if type(props) ~= "table" then
        assert(type(props) == "table", "Libs.Class - table expected, got " .. type(props))
    end

    local propKeys = Utils.Table.Keys(props)

    ---@class LibsClass
    ---@field New fun(): self
    ---@field Init fun(values: table|nil): table
    local Class = {}
    Class.__index = Class

    function Class.Init(values)
        if values ~= nil then
            assert(type(values) == "table", "Class.Init(values) - table expected, got " .. type(values))
        end

        local obj = {}
        setmetatable(obj, Class)

        local keys = values and Utils.Table.Combine(Utils.Table.Values(propKeys), Utils.Table.Keys(values)) or propKeys
        for _, key in pairs(keys) do
            obj[key] = values and values[key] or Utils.Table.DeepClone(props[key])
        end

        return obj
    end

    function Class.New()
        return Class.Init()
    end

    return Class
end

---@param typeDefs table<number, table<string, string|function|table|LibsTypedTable>>|LibsTypedTable
---@return LibsTypedTable
function M.TypedTable(typeDefs, repeatable)
    assert(type(typeDefs) == "table", "Libs.TypedTable(typeDefs, ...) - table expected, got " .. type(typeDefs))
    assert(
        type(repeatable) == "boolean" or repeatable == nil,
        "Libs.TypedTable(..., repeatable) - boolean expected, got " .. type(typeDefs)
    )

    if typeDefs._IsTypedTable then
        typeDefs = { typeDefs }
    end

    if repeatable and #typeDefs ~= 1 then
        error("Libs.TypedTable - repeatable table must have exactly one type definition")
    end

    -- exposed
    ---@class LibsTypedTable : LibsClass
    ---@field Validate fun(table: table): boolean
    ---@field TypeCheck fun(key: string, value: any): boolean
    local TT = Libs.Class({
        _IsTypedTable = true,
        _TypeDefs = {},
        _Repeatable = false,
    })

    ---@param key string
    ---@param value any
    ---@return boolean, string
    function TT:TypeCheck(key, value)
        assert(
            type(key) == "string" or type(key) == "number",
            "Libs.TypedTable:TypeCheck(key, ...) - string or number expected, got " .. type(key)
        )

        local typeDef = self._TypeDefs[key]
        if typeDef == nil then
            return false
        end

        assert(
            type(typeDef) == "table",
            "Libs.TypedTable.typeDefs[" .. key .. "] - table expected, got " .. type(typeDef)
        )

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

---@param source any
---@return LibsChainable
function M.Chainable(source)
    ---@class LibsChainable
    ---@field After fun(func: fun(...: any): any, ...: any): LibsChainable
    ---@overload fun(self: LibsChainable, func: fun(source: any, ...: any), ...: any): LibsChainable
    ---@field Catch fun(func: fun(err: string), ...: any): LibsChainable
    ---@overload fun(self: LibsChainable, func: fun(source: any, err: string), ...: any): LibsChainable
    ---@field Source any
    local Chainable = {
        _IsChainable = true,
        _InitalInput = {},
        Source = source,
        _Chain = {},
    }

    local function inputToFunc(arg1, arg2, ...)
        local selfPassed = false
        if type(arg1) == "table" then
            selfPassed = arg1._IsChainable
            if not selfPassed then
                return
            end
        end

        local func = selfPassed and arg2 or arg1
        if type(func) ~= "function" then
            return
        end

        local args = { ... }
        if not selfPassed then
            table.insert(args, 1, arg2)
        end

        return function(self, ...)
            local funcArgs = Utils.Table.Combine({ ... }, args)

            if selfPassed then
                return func(self.Source, table.unpack(funcArgs))
            end

            return func(table.unpack(funcArgs))
        end
    end

    function Chainable.After(arg1, arg2, ...)
        local func = inputToFunc(arg1, arg2, ...)
        assert(type(func) == "function", "Chainable.After(func) - function expected, got " .. type(arg1))

        table.insert(Chainable._Chain, func)

        return Chainable
    end

    local catch = nil
    function Chainable.Catch(arg1, arg2, ...)
        local func = inputToFunc(arg1, arg2, ...)
        assert(type(func) == "function", "Chainable.Catch(func) - function expected, got " .. type(arg1))

        catch = func

        return Chainable
    end

    function Chainable.Throw(err)
        assert(type(catch) == "function", err)

        return catch(Chainable, err)
    end

    local function stateIsChainable(state)
        return type(state[1]) == "table" and state[1]._IsChainable
    end

    function Chainable.Begin(...)
        local state = Utils.Table.Combine({ ... }, Utils.Table.DeepClone(Chainable._InitalInput))

        -- for when calling :Begin(), the source is passed as the first argument
        if stateIsChainable(state) then
            state[1] = state[1].Source
        end

        for i, func in ipairs(Chainable._Chain) do
            local ok = xpcall(function()
                state = Utils.Table.Pack(func(Chainable, table.unpack(state)))
            end, function(err)
                state = Chainable.Throw(err)
            end)

            if not ok then
                break
            end

            if state[1] == nil then
                break
            end

            -- interrupt chain if a nested chainable is returned
            if stateIsChainable(state) then
                ---@type Chainable
                local nested = state[1]

                nested._Chain = Utils.Table.DeepClone(Chainable._Chain)
                for j = 1, i do
                    table.remove(nested._Chain, 1)
                end

                nested._InitalInput = state
                table.remove(nested._InitalInput, 1)
                if catch then
                    nested.Catch(catch)
                end

                break
            end
        end

        return state
    end

    return Chainable
end

return M
