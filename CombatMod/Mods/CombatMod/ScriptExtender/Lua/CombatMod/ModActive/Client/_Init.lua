IsHost = Ext.Net.IsHost()

Settings = UT.Proxy(
    table.merge({ AutoHide = false, ToggleKey = "U", AutoOpen = true }, IO.LoadJson("ClientConfig.json") or {}),
    function(value, _, raw)
        -- raw not updated yet
        Schedule(function()
            IO.SaveJson("ClientConfig.json", raw)
        end)

        return value
    end
)

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

State = {}
Net.On(
    "SyncState",
    Debounce(300, function(event)
        State = event.Payload or {}
        Event.Trigger("StateChange", State)
    end, true)
)

Net.On("Notification", function(event)
    local data = event.Payload
    WaitUntil(function()
        return get(Ext.UI.GetRoot():Child(1):Child(1):Child(2).DataContext, "CurrentSubtitle", false)
    end, function()
        local context = Ext.UI.GetRoot():Child(1):Child(1):Child(2).DataContext
        context.CurrentSubtitleDuration = data.Duration or 3
        context.CurrentSubtitle = data.Text
    end)
end)

Require("CombatMod/ModActive/Client/GUI/_Init")
