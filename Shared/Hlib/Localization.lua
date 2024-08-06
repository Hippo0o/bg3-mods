---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Log
local Log = Require("Hlib/Log")

---@type Libs
local Libs = Require("Hlib/Libs")

---@type IO
local IO = Require("Hlib/IO")

---@type Event
local Event = Require("Hlib/Event")

---@type Event
local Async = Require("Hlib/Async")

---@type Net
local Net = Require("Hlib/Net")

---@type GameState
local GameState = Require("Hlib/GameState")

---@class Localization
local M = {}

M.Translations = {}
M.UseLoca = true

---@class LocalizationStruct
local Localization = Libs.Struct({
    Version = nil,
    Text = nil,
    Stack = {},
    Handle = nil,
    LocaText = nil,
    _StackNew = true,
})
function Localization.New(text, version, handle)
    local obj = Localization.Init({
        Version = version,
        Text = text,
    })

    if M.UseLoca then
        obj.Handle = handle or M.GenerateHandle(text, version)
        obj.LocaText = M.Get(obj.Handle)

        if obj.LocaText ~= "" then
            Log.Info("Translation found: ", obj.Handle, obj.Text, obj.LocaText)

            obj.Text = obj.LocaText
        end
    end

    return obj
end
local stackNew = {}
function Localization:ExtendStack(stack)
    if self._StackNew then
        self.Stack = {}
        self._StackNew = false
    end

    if stack == "" then -- should not happen
        return
    end

    for _, v in ipairs(self.Stack) do
        if v == stack then
            return
        end
    end

    table.insert(self.Stack, stack)
end

M.FilePath = "Localization/" .. Mod.TableKey
M.Translations = {}

GameState.OnLoadSession(function()
    local cached = IO.LoadJson(M.FilePath .. ".json") or {}
    for k, v in pairs(cached) do
        M.Translations[k] = Localization.New(v.Text, v.Version, v.Handle)
        if type(v.Stack) ~= "table" then
            v.Stack = { v.Stack }
        end

        M.Translations[k].Stack = v.Stack
    end
end)

if Ext.IsServer() then
    Net.On("_TranslationRequest", function(event)
        Utils.Table.Merge(M.Translations, event.Payload)
        Event.Trigger("_TranslationChanged")
    end)
else
    Net.On("_TranslationRequest", function(event)
        Utils.Table.Merge(M.Translations, event.Payload)
    end)
end

Event.On(
    "_TranslationChanged",
    Async.Debounce(100, function()
        if Ext.IsServer() then
            IO.SaveJson(
                M.FilePath .. ".json",
                Utils.Table.Map(M.Translations, function(v, k)
                    return {
                        Text = v.Text,
                        Version = v.Version,
                        Handle = v.Handle,
                        Stack = v.Stack,
                    },
                        k
                end)
            )
        end
        Net.Send("_TranslationRequest", M.Translations)
    end)
)

function M.Translate(text, version)
    version = version or 1

    local key = text .. ";" .. version

    if M.Translations[key] == nil or Mod.Dev then
        local stack = Utils.String.Trim(Utils.Table.Find(Utils.String.Split(debug.traceback(), "\n"), function(line)
            return not line:match("stack traceback:")
                and not line:match("Hlib/Localization.lua")
                and not line:match("(...tail calls...)")
        end) or "")

        if not M.Translations[key] then
            M.Translations[key] = Localization.New(text, version)
        end

        Localization.ExtendStack(M.Translations[key], stack)

        Event.Trigger("_TranslationChanged")

        Log.Debug("Localization/Translate", M.Translations[key].Handle, M.Translations[key].Text)
    end

    return M.Translations[key].Text
end

---@param handle string
---@vararg any
---@return string
function M.Get(handle, ...)
    local str = Ext.Loca.GetTranslatedString(handle):gsub("<LSTag .->(.-)</LSTag>", "%1"):gsub("<br>", "\n")
    for i, v in pairs({ ... }) do
        str = str:gsub("%[" .. i .. "%]", v)
    end

    return str
end

---@param strict boolean
---@param version number|nil
---@return string
function M.GenerateHandle(str, version)
    return "h" .. Utils.UUID.FromString(str, version):gsub("-", "g")
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
    local xmlEntry = [[%s
    <content contentuid="%s" version="%d">%s</content>
]]

    local ordered = {}
    for k, v in pairs(M.Translations) do
        table.insert(ordered, k)
    end
    table.sort(ordered)

    local entries = {}
    for _, key in ipairs(ordered) do
        local translation = M.Translations[key]

        local handle = translation.Handle:gsub(";%d+$", "") -- handle should not have a version

        local stack = {}
        local duplicate = {}
        for i, v in ipairs(translation.Stack) do
            local simple = v:match("([^:]+):%d+")

            if not duplicate[simple] then
                table.insert(stack, string.format("    <!-- %s -->", v:match("([^:]+):%d+")))
                duplicate[simple] = true
            end
        end

        table.insert(entries, string.format(xmlEntry, table.concat(stack, "\n"), handle, 1, translation.Text))
    end

    local loca = string.format(xmlWrap, table.concat(entries, "\n"))

    IO.Save(M.FilePath .. ".xml", loca)
end

return M
