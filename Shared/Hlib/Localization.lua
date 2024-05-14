---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Localization
local M = {}

M.Translations = {}
M.UseLoca = true

---@class LocalizationClass
local Localization = Libs.Class({
    Version = nil,
    Text = nil,
    Handle = nil,
    LocaText = nil,
})

function M.Translate(text, version)
    local key = text .. (version and ":" .. version or "")

    if M.Translations[key] == nil then
        M.Translations[key] = Localization.Init({
            Text = text,
            Version = version,
        })

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

        if Mod.Dev then
            if Ext.IsClient() then
                Require("Hlib/Net").Request("DevTranslationAdded", M.Translations).Then(function(event)
                    M.Translations = event.Payload
                end)
            else
                Require("Hlib/Event").Trigger("DevSaveTranslations")
            end
        end
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

    if M.Get(handle) ~= "" and M.Get(handle) ~= str then
        Utils.Log.Debug("Handle translated: ", handle, str, M.Get(handle))
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
if Mod.Dev then
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

    function M.CreateLocaFile()
        local path = Mod.Prefix .. "/Localization/" .. Mod.TableKey .. ".xml"

        local loca = M.BuildLocaFile()
        Ext.IO.SaveFile(path, loca)

        return path, loca
    end

    if Ext.IsServer() then
        local Net = Require("Hlib/Net")
        local Event = Require("Hlib/Event")

        local filepath = Mod.Prefix .. "/Localization/" .. Mod.TableKey .. ".json"
        M.Translations = Ext.Json.Parse(Ext.IO.LoadFile(filepath) or "{}")

        Net.On("DevTranslationAdded", function(event)
            Utils.Table.Merge(M.Translations, event.Payload)
            Net.Respond(event, M.Translations)
            Event.Trigger("DevSaveTranslations")
        end)

        Event.On("DevSaveTranslations", function(event)
            Ext.IO.SaveFile(filepath, Ext.Json.Stringify(M.Translations))
            M.CreateLocaFile()
        end)
    end
end

return M
