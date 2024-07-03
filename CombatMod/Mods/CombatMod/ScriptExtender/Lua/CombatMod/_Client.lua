if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Require("CombatMod/Shared")

IsHost = false

Settings = Libs.Proxy(
    UT.Merge({ AutoHide = false, ToggleKey = "U", AutoOpen = true }, IO.LoadJson("ClientConfig.json") or {}),
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

Net.On("Notification", function(event)
    local data = event.Payload
    WaitUntil(function()
        return U.GetProperty(Ext.UI.GetRoot():Child(1):Child(1):Child(2).DataContext, "CurrentSubtitle", false)
    end, function()
        local context = Ext.UI.GetRoot():Child(1):Child(1):Child(2).DataContext
        context.CurrentSubtitleDuration = data.Duration or 3
        context.CurrentSubtitle = data.Text
    end)
end)

local done = false
local function init()
    if done then
        return
    end
    done = true

    Require("CombatMod/Overwrites")

    Require("CombatMod/Client/_Init")

    Event.Trigger(GameState.EventLoad)
end

Net.On("ModActive", init, true)
