Require("CombatMod/Shared")
if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Settings = Libs.Proxy(
    UT.Merge({ AutoHide = false, ToggleKey = "U" }, IO.LoadJson("ClientConfig.json") or {}),
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
    Debounce(100, function(event)
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
    WaitUntil(function()
        return hostChecked
    end, function()
        local _, toggle, open, close = table.unpack(Require("CombatMod/Client/GUI/_Init"))

        Net.On("OpenGUI", open)
        Net.On("CloseGUI", close)

        local toggleWindow = Async.Throttle(100, toggle)

        Ext.Events.KeyInput:Subscribe(function(e)
            if e.Event == "KeyDown" and e.Repeat == false and e.Key == Settings.ToggleKey then
                toggleWindow()
            end
        end)
    end)
end, true)
