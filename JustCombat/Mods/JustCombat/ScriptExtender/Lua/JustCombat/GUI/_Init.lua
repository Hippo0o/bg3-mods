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

local listeners = {}
function WindowEvent(event, callback, ...)
    local listener = Event.On(event, callback, ...)
    table.insert(listeners, listener)
    return listener
end
Event.On("WindowClosed", function()
    for _, listener in ipairs(listeners) do
        listener:Unregister()
    end
    listeners = {}
end)

function Debounced(func, delay)
    local seconds = delay / 1000
    local handlerId

    return function(...)
        if handlerId then
            Ext.Events.Tick:Unsubscribe(handlerId)
            handlerId = nil
        end

        local args = { ... }
        local last = 0
        handlerId = Ext.Events.Tick:Subscribe(function(e)
            last = last + e.Time.DeltaTime
            if last < seconds then
                return
            end

            Ext.Events.Tick:Unsubscribe(handlerId)
            handlerId = nil

            func(table.unpack(args))
        end)
    end
end

local function openWindow()
    if window then
        if window.Open then
            return
        end
        window:Destroy()
    end
    ---@type ExtuiWindow
    window = Ext.IMGUI.NewWindow("Just Combat")

    window:AddButton("Debug").OnClick = Debounced(function()
        L.Debug("Debug button clicked")
    end, 500)

    window.Closeable = true
    window.OnClose = function()
        Event.Trigger("WindowClosed")
    end

    if Mod.Debug then
        local dbg = Mod.Debug
        local dbgBtn = window:AddButton("Debug")
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
    end

    Net.Send("State")

    local tabs = window:AddTabBar("Main")
    local tabMain = tabs:AddTabItem("Main")
    Control.Main(tabMain)

    if Mod.Debug then
        local tabDebug = tabs:AddTabItem("Debug")

        Debug.Main(tabDebug)

        WindowEvent("ToggleDebug", function(bool)
            tabDebug.Visible = bool
        end)
    end
end

Net.On("OpenGUI", openWindow)
