Require("CombatMod/Client/GUI/Components")

Require("CombatMod/Client/GUI/Control")
Require("CombatMod/Client/GUI/Unlocks")
Require("CombatMod/Client/GUI/Creation")
Require("CombatMod/Client/GUI/Config")
Require("CombatMod/Client/GUI/Extras")
Require("CombatMod/Client/GUI/Loot")
Require("CombatMod/Client/GUI/Debug")

---@type ExtuiWindow
local window = Ext.IMGUI.NewWindow(
    string.format("%s v%d.%d.%d", Mod.Prefix, Mod.Version.Major, Mod.Version.Minor, Mod.Version.Revision)
)

L.Warn("Window created.", "DX11 is known to cause issues.")
L.Warn("If the window is not visible, make sure to update to the latest version of Script Extender.")
L.Warn("Furthermore, try switching to Vulkan and disable all overlays (Steam, Discord, AMD, NVIDIA, etc.).")

window:SetSize({ 1000, 600 })
window.Closeable = true
window.NoFocusOnAppearing = true
window.OnClose = function()
    Event.Trigger("WindowClosed")
end

window.Open = false

local function open()
    window.Visible = true
    if not window.Open then
        L.Info("Window opened.")
        Event.Trigger("WindowOpened")
        Net.Send("WindowOpened")
    end

    window.Open = true
end

local function close()
    window.Visible = false
    if window.Open then
        Event.Trigger("WindowClosed")
        Net.Send("WindowClosed")
    end
    window.Open = false
end

local function toggle()
    if window.Open and window.Visible then
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

    function DisplayResponse(event)
        local payload = event.Payload

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

Loot.Main(tabs)

Extras.Main(tabs)

Components.Conditional(_, function()
    return { Creation.Main(tabs), Debug.Main(tabs) }
end, "ToggleDebug")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

do -- auto hide window
    local windowVisible = Debounce(1000, function(bool)
        if Settings.AutoHide then
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

GameState.OnSave(function()
    window.Visible = false
end)
GameState.OnUnload(function()
    window.Visible = false
end)
GameState.OnLoad(function()
    window.Visible = true
end)

Net.On("OpenGUI", function(event)
    if Settings.AutoOpen == false and event.Payload == "Optional" then
        return
    end

    open()
end)
Net.On("CloseGUI", function(event)
    if Settings.AutoOpen == false and event.Payload == "Optional" then
        return
    end

    close()
end)

local toggleWindow = Async.Throttle(100, toggle)

Ext.Events.KeyInput:Subscribe(function(e)
    if e.Event == "KeyDown" and e.Repeat == false and e.Key == Settings.ToggleKey then
        toggleWindow()
    end
end)

Net.Send("GUIReady")
