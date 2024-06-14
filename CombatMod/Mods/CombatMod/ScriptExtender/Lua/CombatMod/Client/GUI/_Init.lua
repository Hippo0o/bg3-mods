Require("CombatMod/Client/GUI/Components")

Require("CombatMod/Client/GUI/Control")
Require("CombatMod/Client/GUI/Unlocks")
Require("CombatMod/Client/GUI/Creation")
Require("CombatMod/Client/GUI/Config")
Require("CombatMod/Client/GUI/Extras")
Require("CombatMod/Client/GUI/Debug")

---@type ExtuiWindow
local window = Ext.IMGUI.NewWindow(
    string.format("%s v%d.%d.%d", Mod.Prefix, Mod.Version.major, Mod.Version.minor, Mod.Version.revision)
)

Event.On("WindowClosed", function()
    window.Visible = false
    Net.Send("WindowClosed")
end)
Event.On("WindowOpened", function()
    window.Visible = true
    Net.Send("WindowOpened")
end)

L.Warn("Window created.", "If the window is not visible, make sure to update to the latest version of Script Extender.")

window:SetSize({ 1000, 600 })
window.Closeable = true
window.NoFocusOnAppearing = true
window.OnClose = function()
    Event.Trigger("WindowClosed")
end

Event.Trigger("WindowOpened")

local function open()
    if not window.Open then
        window.Open = true
        Event.Trigger("WindowOpened")
    end
end

local function close()
    if window.Open then
        window.Open = false
        Event.Trigger("WindowClosed")
    end
end

local function toggle()
    if window.Open then
        close()
    else
        open()
    end
end

Net.Send("SyncState")

do
    local errorBox = window:AddText("")
    errorBox:SetColor("Text", { 1, 0.4, 0.4, 1 })
    local clearError = Debounce(2000, function()
        errorBox.Label = ""
    end)
    Components.Computed(errorBox, function(box, result)
        clearError()

        return result
    end, "Error")

    local successBox = window:AddText("")
    successBox:SetColor("Text", { 0.4, 1, 0.4, 1 })
    local clearSuccess = Debounce(2000, function()
        successBox.Label = ""
    end)
    Components.Computed(successBox, function(box, result)
        clearSuccess()
        return result
    end, "Success")

    successBox.SameLine = true

    function DisplayResponse(payload)
        if payload[1] then
            Event.Trigger("Success", payload[2])
        else
            Event.Trigger("Error", payload[2])
        end
    end
end

local tabs = window:AddTabBar(U.RandomId())

Control.Main(tabs)

ClientUnlock.Main(tabs)

Config.Main(tabs)

Extras.Main(tabs)

Components.Conditional(_, function()
    return { Creation.Main(tabs), Debug.Main(tabs) }
end, "ToggleDebug")

do -- auto hide window
    local windowVisible = Debounce(1000, function(bool)
        if PersistentVars.AutoHide then
            window.Visible = bool
        end
    end)
    -- local windowAlpha = Debounce(100, function(bool)
    --     if bool then
    --         window:SetStyle("Alpha", 1)
    --         window.Visible = bool
    --     else
    --         window:SetStyle("Alpha", 0.5)
    --     end
    -- end)

    Ext.UI.GetRoot():Subscribe("MouseEnter", function()
        windowVisible(false)
        -- windowAlpha(false)
    end)
    Ext.UI.GetRoot():Subscribe("MouseLeave", function()
        windowVisible(true)
        -- windowAlpha(true)
    end)
end

GameState.OnUnload(function()
    window.Visible = false
end)
GameState.OnLoad(function()
    window.Visible = true
end)

return { window, toggle, open, close }
