---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@class IO
local M = {}

function M.Load(file)
    file = Mod.Prefix .. "/" .. file
    return Ext.IO.LoadFile(file)
end

function M.Save(file, data)
    file = Mod.Prefix .. "/" .. file
    Ext.IO.SaveFile(file, tostring(data))
end

function M.Exists(file)
    file = Mod.Prefix .. "/" .. file
    return Ext.IO.LoadFile(file) ~= nil
end

function M.LoadJson(file)
    if file:sub(-5) ~= ".json" then
        file = file .. ".json"
    end

    local data = M.Load(file)
    if not data then
        return nil
    end

    return Ext.Json.Parse(data)
end

function M.SaveJson(file, data)
    if file:sub(-5) ~= ".json" then
        file = file .. ".json"
    end

    M.Save(file, Ext.Json.Stringify(type(data) == "table" and Utils.Table.Clean(data, 0) or data))
end

return M
