Require("EndlessBattle/Shared")
if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

State = {}
Net.On(
    "SyncState",
    Async.Debounce(100, function(event)
        State = event.Payload or {}
        Event.Trigger("StateChange", State)
    end)
)

IsHost = false
local hostChecked = false
GameState.OnLoad(function()
    Net.Request("IsHost").After(function(event)
        IsHost = event.Payload
        L.Debug("IsHost", IsHost)
        hostChecked = true
    end)
end, true)

Net.On("ModActive", function(event)
    local _, toggle, open, close = table.unpack(Require("EndlessBattle/Client/GUI/_Init"))
    Net.On("OpenGUI", open)
    Net.On("CloseGUI", close)
    local toggleWindow = Async.Throttle(100, function()
        -- only load client code when needed

        WaitFor(function()
            return hostChecked
        end).After(toggle)
    end)

    Ext.Events.KeyInput:Subscribe(function(e)
        if e.Event == "KeyDown" and e.Repeat == false and e.Key == "U" then
            toggleWindow()
        end
    end)
end, true)
