Require("EndlessBattle/Shared")
if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

IsHost = false
local hostChecked = false
GameState.OnLoad(function()
    Net.Request("IsHost").After(function(event)
        IsHost = event.Payload
        L.Debug("IsHost", IsHost)
        hostChecked = true
    end)
end, true)

State = {}
Net.On(
    "SyncState",
    Async.Debounce(100, function(event)
        State = event.Payload or {}
        Event.Trigger("StateChange", State)
    end)
)

Net.On(
    "OpenGUI",
    Async.Throttle(1000, function()
        -- only load client code when needed
        Require("EndlessBattle/Client/GUI/_Init")

        WaitFor(function()
            return hostChecked
        end).After(OpenWindow)
    end)
)
