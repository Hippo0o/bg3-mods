---@type Utils
local Utils = Require("Hlib/Utils")

---@class Libs
local M = {}

---@param props table|nil
---@return LibsObject
function M.Object(props)
    if not props then
        props = {}
    end

    if type(props) ~= "table" then
        assert(type(props) == "table", "Libs.Object - table expected, got " .. type(props))
    end

    local propKeys = Utils.Table.Keys(props)

    ---@class LibsObject
    ---@field New fun(): self
    ---@field Init fun(values: table|nil): table
    local Object = {}
    Object.__index = Object

    function Object.Init(values)
        if values ~= nil then
            assert(type(values) == "table", "Object.Init(values) - table expected, got " .. type(values))
        end

        local obj = {}
        setmetatable(obj, Object)

        local keys = values and Utils.Table.Combine(Utils.Table.Values(propKeys), Utils.Table.Keys(values)) or propKeys
        for _, key in pairs(keys) do
            obj[key] = values and values[key] or Utils.Table.DeepClone(props[key])
        end

        return obj
    end

    function Object.New()
        return Object.Init()
    end

    return Object
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

    ---@class LibsTypedTable : LibsObject
    ---@field Validate fun(table: table): boolean
    ---@field TypeCheck fun(key: string, value: any): boolean
    local Object = Libs.Object({
        _IsTypedTable = true,
        _TypeDefs = {},
        _Repeatable = false,
    })

    ---@param key string
    ---@param value any
    ---@return boolean, string
    function Object:TypeCheck(key, value)
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

                    return Object.Init(validator):Validate(value)
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

    function Object:Validate(tableToValidate)
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
    function Object:GetFields()
        return Utils.Table.Keys(self._TypeDefs)
    end

    return Object.Init({
        _TypeDefs = typeDefs,
        _Repeatable = repeatable and true or false,
    })
end

return M
