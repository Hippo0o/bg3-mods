local hostChecked = false
Net.Request("IsHost"):After(function(event)
    IsHost = event.Payload
    L.Debug("IsHost", IsHost)
    hostChecked = true
end)

WaitUntil(function()
    return hostChecked
end, function()
    Require("CombatMod/ModActive/Client/GUI/_Init")
end)
