State = {}
Net.On("State", function(event)
    State = event.Payload or {}
    Event.Trigger("StateChange", State)
end)
Net.On("PlayerNotify", function()
    Net.Send("State")
end)

Require("JustCombat/GUI/Components")

Require("JustCombat/GUI/Control")
Require("JustCombat/GUI/Creation")
Require("JustCombat/GUI/Debug")

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
    window = Ext.IMGUI.NewWindow("Just Combat")

    window.Closeable = true
    window.OnClose = function()
        Event.Trigger("WindowClosed")
    end

    Net.Send("State")

    local dbgBtn = window:AddButton("Debug")
    dbgBtn.Visible = Mod.Debug

    local tabs = window:AddTabBar("Main")
    local tabMain = tabs:AddTabItem("Main")
    local tabCreation = tabs:AddTabItem("Create")
    Control.Main(tabMain)
    Creation.Main(tabCreation)

    if Mod.Debug then
        local dbg = Mod.Debug
        dbgBtn.OnClick = function()
            dbg = not dbg
            Event.Trigger("ToggleDebug", dbg)
        end
        WindowEvent("ToggleDebug", function(bool)
            dbgBtn.Label = bool and "Debug On" or "Debug Off"
        end)

        Schedule(function()
            Event.Trigger("ToggleDebug", dbg)
        end)

        local tabDebug = tabs:AddTabItem("Debug")
        Debug.Main(tabDebug)

        WindowEvent("ToggleDebug", function(bool)
            tabDebug.Visible = bool
        end)
    end
end

Net.On("OpenGUI", openWindow)
