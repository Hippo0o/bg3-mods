---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Libs
local Libs = Require("Hlib/Libs")

---@type IO
local IO = Require("Hlib/IO")

---@type Event
local Event = Require("Hlib/Event")

---@type Net
local Net = Require("Hlib/Net")

---@class Localization
local M = {}

M.Translations = {}
M.UseLoca = true

---@class LocalizationStruct
local Localization = Libs.Struct({
    Version = nil,
    Text = nil,
    Handle = nil,
    LocaText = nil,
})

local filepath = "Localization/" .. Mod.TableKey
M.Translations = IO.LoadJson(filepath .. ".json") or {}

if Ext.IsServer() then
    Net.On("_TranslationRequest", function(event)
        Utils.Table.Merge(M.Translations, event.Payload)
        Net.Respond(event, M.Translations)
        Event.Trigger("_TranslationChanged")
    end)
    Event.On("_TranslationChanged", function(event)
        IO.SaveJson(filepath .. ".json", M.Translations)
        if Mod.Dev then
            IO.Save(filepath .. ".xml", M.BuildLocaFile())
        end
    end)
end

function M.Translate(text, version)
    version = version or 1

    local key = text .. ";" .. version

    if M.Translations[key] == nil or Mod.Dev then
        local stack = Utils.Table.Find(Utils.String.Split(debug.traceback(), "\n"), function(line)
            return not line:match("stack traceback:") and not line:match("Hlib/Localization.lua") and not line:match("(...tail calls...)")
        end)

        M.Translations[key] = Localization.Init({
            Stack = Utils.String.Trim(stack),
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

        if Ext.IsClient() then
            Net.Request("_TranslationRequest", M.Translations).After(function(event)
                -- potential race condition
                M.Translations = event.Payload
            end)
        else
            Event.Trigger("_TranslationChanged")
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
---@param version number|nil
---@return string
function M.GenerateHandle(str, version)
    local handle = "h" .. Utils.UUID.FromString(str, version):gsub("-", "g")

    if Mod.Dev and M.Get(handle) ~= "" and M.Get(handle) ~= str then
        Utils.Log.Debug("Handle translated: ", handle, str, M.Get(handle))
    end

    return handle
end

---@param text string text "...;2" for version 2
---@vararg any passed to string.format
---@return string
function M.Localize(text, ...)
    local version = text:match(";%d+$")
    if version then
        text = text:gsub(";%d+$", "")
    end

    return string.format(M.Translate(text, version), ...)
end

function M.BuildLocaFile()
    local xmlWrap = [[
<?xml version="1.0" encoding="utf-8"?>
<contentList>
%s
</contentList>
]]
    local xmlEntry = [[
    <!-- %s -->
    <content contentuid="%s" version="%d">%s</content>
]]

    local entries = {}
    for text, translation in pairs(M.Translations) do
        local handle = translation.Handle:gsub(";%d+$", "") -- handle should not have a version
        table.insert(entries, string.format(xmlEntry, translation.Stack, handle, 1, translation.Text))
    end

    local loca = string.format(xmlWrap, table.concat(entries, "\n"))

    return loca
end

return M
