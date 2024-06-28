local hostChecked = false
Net.Request("IsHost").After(function(event)
    IsHost = event.Payload
    L.Debug("IsHost", IsHost)
    hostChecked = true
end)

WaitUntil(function()
    return hostChecked
end, function()
    local _, toggle, open, close = table.unpack(Require("CombatMod/Client/GUI/_Init"))

    Net.On("OpenGUI", function(event)
        if Settings.AutoOpen == false and event.Payload == "Optional" then
            return
        end

        open()
    end)
    Net.On("CloseGUI", function(event)
        if Settings.AutoOpen == false and event.Payload == "Optional" then
            return
        end

        close()
    end)

    local toggleWindow = Async.Throttle(100, toggle)

    Ext.Events.KeyInput:Subscribe(function(e)
        if e.Event == "KeyDown" and e.Repeat == false and e.Key == Settings.ToggleKey then
            toggleWindow()
        end
    end)
end)
