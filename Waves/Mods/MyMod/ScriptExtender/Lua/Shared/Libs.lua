---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

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
            assert(type(values) == "table", "Object.Init - table expected, got " .. type(values))
        end

        local obj = {}
        setmetatable(obj, Object)

        local keys = values and Utils.Table.Combine(propKeys, Utils.Table.Keys(values)) or propKeys
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

return M
