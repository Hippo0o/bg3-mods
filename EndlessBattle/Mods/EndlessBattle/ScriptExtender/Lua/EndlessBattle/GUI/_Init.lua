State = {}
Net.On("GetState", function(event)
    State = event.Payload or {}
    Event.Trigger("StateChange", State)
end)
Net.On("PlayerNotify", function()
    Net.Send("GetState")
end)

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

-- register window event listeners
local listeners = {}
function WindowEvent(event, callback, ...)
    local listener = Event.On(event, callback, ...)
    listener.UnregisterOnError = true
    table.insert(listeners, listener)
    return listener
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

    L.Warn("Window opened.", "Support is currently in an experimental state.", "DX11 is known to cause issues.")
    L.Warn("If the window is not visible, make sure to update to the latest version of Script Extender.")
    L.Warn("Furthermore, try switching to Vulkan and disable all overlays (Steam, Discord, AMD, NVIDIA, etc.).")

    window:SetSize({ 670, 550 })
    window.Closeable = true
    window.OnClose = function()
        Event.Trigger("WindowClosed")
    end

    Net.Send("GetState")

    local tabs = window:AddTabBar(__("Main"))
    Control.Main(tabs)
    -- Creation.Main(tabs)
    Config.Main(tabs)
    Debug.Main(tabs)
end

Net.On("OpenGUI", openWindow)
