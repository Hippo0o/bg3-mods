Require("EndlessBattle/GUI/Components")

Require("EndlessBattle/GUI/Control")
Require("EndlessBattle/GUI/Creation")
Require("EndlessBattle/GUI/Config")
Require("EndlessBattle/GUI/Debug")

-- register window event listeners
local listeners = {}
---@return EventListener
function WindowEvent(event, callback, once)
    local chain = Event.ChainOn(event, once)
        .After(function(_, ...)
            callback(...)
        end)
        .Catch(function(self, err)
            L.Debug("WindowEvent", event, err)
            self:Unregister()
        end)

    table.insert(listeners, chain.Source)
    return chain.Source
end
function WindowNet(event, callback, ...)
    return WindowEvent(Net.EventName(event), callback, ...)
end
Event.On("WindowClosed", function()
    for _, listener in ipairs(listeners) do
        listener:Unregister()
    end
    listeners = {}
end)

local window
local function openWindow()
    if window then
        if not window.Open then
            window.Open = true
            window.Visible = true
        end
        return
    end

    ---@type ExtuiWindow
    window = Ext.IMGUI.NewWindow("Endless Battle")
    Event.Trigger("WindowOpened")

    L.Warn("Window opened.", "Support is currently in an experimental state.", "DX11 is known to cause issues.")
    L.Warn("If the window is not visible, make sure to update to the latest version of Script Extender.")
    L.Warn("Furthermore, try switching to Vulkan and disable all overlays (Steam, Discord, AMD, NVIDIA, etc.).")

    window:SetSize({ 670, 550 })
    window.Closeable = true
    window.NoFocusOnAppearing = true
    -- window.OnClose = function()
    --     Event.Trigger("WindowClosed")
    -- end

    Net.Send("GetState")

    local tabs = window:AddTabBar(__("Main"))
    Control.Main(tabs)
    Creation.Main(tabs)
    Config.Main(tabs)
    Debug.Main(tabs)

    do -- auto hide window
        local windowVisible = Async.Debounce(1000, function(bool)
            window.Visible = bool
        end)
        local windowAlpha = Async.Debounce(100, function(bool)
            if bool then
                window:SetStyle("Alpha", 1)
                window.Visible = bool
            else
                window:SetStyle("Alpha", 0.5)
            end
        end)

        Ext.UI.GetRoot():Subscribe("MouseEnter", function()
            windowVisible(false)
            windowAlpha(false)
        end)
        Ext.UI.GetRoot():Subscribe("MouseLeave", function()
            windowVisible(true)
            windowAlpha(true)
        end)
    end

    GameState.OnUnload(function()
        window.Visible = false
    end)
    GameState.OnLoad(function()
        window.Visible = true
    end)
end

Net.On("OpenGUI", openWindow)
