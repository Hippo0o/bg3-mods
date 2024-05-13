Require("EndlessBattle/Shared")
if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

State = {}
Net.On("GetState", function(event)
    State = event.Payload or {}
    Event.Trigger("StateChange", State)
end)
Net.On("PlayerNotify", function()
    Net.Send("GetState")
end)

Require("EndlessBattle/GUI/_Init")
