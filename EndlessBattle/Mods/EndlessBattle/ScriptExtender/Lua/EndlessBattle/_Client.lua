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
    "GetState",
    Async.Debounce(10, function(event)
        State = event.Payload or {}
        Event.Trigger("StateChange", State)
    end)
)
Net.On(
    "PlayerNotify",
    Async.Throttle(1000, function()
        Net.Send("GetState")
    end)
)

Net.On(
    "OpenGUI",
    Async.Throttle(1000, function()
        -- only load client code when needed
        Require("EndlessBattle/GUI/_Init")
        OpenWindow()
    end)
)
