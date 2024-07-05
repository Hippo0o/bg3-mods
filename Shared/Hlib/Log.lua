---@class Log
local M = {}

---@type Mod
local Mod = Require("Hlib/Mod")

-- Fallen is the best
function M.RainbowText(text)
    local function HSVToRGB(h, s, v)
        local c = v * s
        local hp = h / 60
        local x = c * (1 - math.abs(hp % 2 - 1))
        local r, g, b = 0, 0, 0

        if hp >= 0 and hp <= 1 then
            r, g, b = c, x, 0
        elseif hp >= 1 and hp <= 2 then
            r, g, b = x, c, 0
        elseif hp >= 2 and hp <= 3 then
            r, g, b = 0, c, x
        elseif hp >= 3 and hp <= 4 then
            r, g, b = 0, x, c
        elseif hp >= 4 and hp <= 5 then
            r, g, b = x, 0, c
        elseif hp >= 5 and hp <= 6 then
            r, g, b = c, 0, x
        end

        local m = v - c
        return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
    end

    local coloredText = ""
    local len = #text
    local step = 360 / len
    local hue = 0

    for i = 1, len do
        local char = text:sub(i, i)
        local r, g, b = HSVToRGB(hue, 1, 1)
        coloredText = coloredText .. M.ColorText(char, { r, g, b })
        hue = (hue + step) % 360
    end

    return coloredText
end

function M.ColorText(text, color)
    if type(color) == "table" then
        local r, g, b = color[1], color[2], color[3]
        return string.format("\x1b[38;2;%d;%d;%dm%s\x1b[0m", r, g, b, text)
    end

    return string.format("\x1b[%dm%s\x1b[0m", color or 37, text)
end

local function logPrefix()
    local pre = M.RainbowText(Mod.Prefix) .. " "
    if Mod.Debug then
        pre = pre .. (Ext.IsClient() and "[Client]" or "[Server]")
    end
    return pre
end

function M.Info(...)
    Ext.Utils.Print(logPrefix() .. M.ColorText("[Info]"), ...)
end

function M.Warn(...)
    Ext.Utils.PrintWarning(logPrefix() .. M.ColorText("[Warning]", 33), ...)
end

function M.Debug(...)
    if Mod.Debug then
        Ext.Utils.Print(logPrefix() .. M.ColorText("[Debug]", 36), ...)
    end
end

function M.Dump(...)
    for i, v in pairs({ ... }) do
        M.Debug(i .. ":", type(v) == "string" and v or Ext.DumpExport(v))
    end
end

function M.Error(...)
    Ext.Utils.PrintError(logPrefix() .. M.ColorText("[Error]", 31), ...)
end

return M
