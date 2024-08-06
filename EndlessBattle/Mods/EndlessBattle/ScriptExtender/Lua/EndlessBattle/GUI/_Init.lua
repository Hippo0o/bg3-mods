Require("EndlessBattle/GUI/Components")

Require("EndlessBattle/GUI/Control")
Require("EndlessBattle/GUI/Creation")
Require("EndlessBattle/GUI/Config")
Require("EndlessBattle/GUI/Debug")

local window
GameState.OnUnload(function()
    if window then
        window.Visible = false
    end
end)
GameState.OnLoad(function()
    if window then
        window.Visible = true
    end
end)

do
    local handles = {}
    Event.On("WindowClosed", function()
        for _, handle in ipairs(handles) do
            Ext.UI.GetRoot():Unsubscribe(handle)
        end
    end)
    Event.On("WindowOpened", function()
        -- auto hide window
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

        handles[1] = Ext.UI.GetRoot():Subscribe("MouseEnter", function()
            if not window then
                return
            end
            windowVisible(false)
            windowAlpha(false)
        end)
        handles[2] = Ext.UI.GetRoot():Subscribe("MouseLeave", function()
            if not window then
                return
            end
            windowVisible(true)
            windowAlpha(true)
        end)
    end)
end

-- register window event listeners
local listeners = {}
---@return EventListener
function WindowEvent(event, callback, ...)
    local chain = Event.On(event, callback, ...).Catch(function(self, err)
        L.Debug("WindowEvent", event, err)
        self.Source:Unregister()
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

local function openWindow()
    if window then
        if window.Open then
            return
        end
        window:Destroy()
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
    window.OnClose = function()
        Event.Trigger("WindowClosed")
    end

    Net.Send("GetState")

    local tabs = window:AddTabBar(__("Main"))
    Control.Main(tabs)
    Creation.Main(tabs)
    Config.Main(tabs)
    Debug.Main(tabs)
end

Net.On("OpenGUI", openWindow)
