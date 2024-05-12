---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@class Localization
local M = {}

M.Translations = {}
M.UseLoca = true

function M.Translate(text, version)
    local key = text .. (version and ":" .. version or "")

    if M.Translations[key] == nil then
        M.Translations[key] = {
            Text = text,
            Version = version,
        }
        if M.UseLoca then
            local handle = M.GenerateHandle(text, version)
            local loca = M.Get(handle)
            M.Translations[key].Handle = handle
            M.Translations[key].LocaText = loca

            if loca ~= "" then
                text = loca
            end
        end

        M.Translations[key].Text = text
    end

    return M.Translations[key].Text
end

---@param handle string
---@return string
function M.Get(handle)
    return Ext.Loca.GetTranslatedString(handle)
end

---@param strict boolean
---@return string
function M.GenerateHandle(str, version)
    local handle = "h" .. Utils.UUID.FromString(str, version):gsub("-", "g")

    if M.Get(handle) ~= "" then
        Utils.Log.Debug("Handle detected: ", handle, str, M.Get(handle))
    end

    return handle
end

---@param text string text
---@vararg any passed to string.format
---@return string
function M.Localize(text, ...)
    return string.format(M.Translate(text), ...)
end

-- for dev purposes
function M.BuildLocaFile()
    local xmlWrap = [[
<?xml version="1.0" encoding="utf-8"?>
<contentList>
%s
</contentList>
    ]]
    local xmlEntry = [[
    <content contentuid="%s" version="1">%s</content>
    ]]

    local entries = {}
    for text, translation in pairs(M.Translations) do
        table.insert(entries, string.format(xmlEntry, translation.Handle, translation.Text))
    end

    local loca = string.format(xmlWrap, table.concat(entries, "\n"))

    return loca
end

-- maybe remove
function M.CreateLocaFile()
    local path = Mod.ModPrefix .. "/Localization/" .. Mod.ModTableKey .. ".xml"
    while Ext.IO.LoadFile(path) ~= nil do
        path = path:gsub(".xml", "_.xml")
    end

    local loca = M.BuildLocaFile()
    Ext.IO.SaveFile(path, loca)

    return path, loca
end

return M
