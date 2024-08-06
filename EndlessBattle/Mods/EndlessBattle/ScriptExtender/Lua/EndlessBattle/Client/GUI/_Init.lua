Require("EndlessBattle/Client/GUI/Components")

Require("EndlessBattle/Client/GUI/Control")
Require("EndlessBattle/Client/GUI/Unlocks")
Require("EndlessBattle/Client/GUI/Creation")
Require("EndlessBattle/Client/GUI/Config")
Require("EndlessBattle/Client/GUI/Debug")
Require("EndlessBattle/Client/GUI/Loot")

Event.On("WindowClosed", function()
    Net.Send("WindowClosed")
end)
Event.On("WindowOpened", function()
    Net.Send("WindowOpened")
end)

---@type ExtuiWindow
local window = Ext.IMGUI.NewWindow("Endless Battle - " .. __("Press %s to toggle window.", "U"))

L.Warn("Window opened.", "Support is currently in an experimental state.", "DX11 is known to cause issues.")
L.Warn("If the window is not visible, make sure to update to the latest version of Script Extender.")
L.Warn("Furthermore, try switching to Vulkan and disable all overlays (Steam, Discord, AMD, NVIDIA, etc.).")

window:SetSize({ 900, 600 })
window.Closeable = true
window.NoFocusOnAppearing = true
window.OnClose = function()
    Event.Trigger("WindowClosed")
end

Event.Trigger("WindowOpened")

local function open()
    if not window.Open then
        window.Open = true
        window.Visible = true
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
    local clearError = Async.Debounce(2000, function()
        errorBox.Label = ""
    end)
    Components.Computed(errorBox, function(box, result)
        clearError()

        return result
    end, "Error")

    local successBox = window:AddText("")
    successBox:SetColor("Text", { 0.4, 1, 0.4, 1 })
    local clearSuccess = Async.Debounce(2000, function()
        successBox.Label = ""
    end)
    Components.Computed(successBox, function(box, result)
        clearSuccess()
        return result
    end, "Success")

    successBox.SameLine = true
end

local tabs = window:AddTabBar(__("Main"))
ClientUnlock.Main(tabs)
Control.Main(tabs)
Loot.Main(tabs)
Config.Main(tabs)
Components.Conditional(_, function()
    return { Creation.Main(tabs), Debug.Main(tabs) }
end, "ToggleDebug")

-- do -- auto hide window
--     local windowVisible = Async.Debounce(1000, function(bool)
--         window.Visible = bool
--     end)
--     -- local windowAlpha = Async.Debounce(100, function(bool)
--     --     if bool then
--     --         window:SetStyle("Alpha", 1)
--     --         window.Visible = bool
--     --     else
--     --         window:SetStyle("Alpha", 0.5)
--     --     end
--     -- end)
--
--     Ext.UI.GetRoot():Subscribe("MouseEnter", function()
--         windowVisible(false)
--         -- windowAlpha(false)
--     end)
--     Ext.UI.GetRoot():Subscribe("MouseLeave", function()
--         windowVisible(true)
--         -- windowAlpha(true)
--     end)
-- end

GameState.OnUnload(function()
    window.Visible = false
end)
GameState.OnLoad(function()
    window.Visible = true
end)

return { window, toggle, open, close }
