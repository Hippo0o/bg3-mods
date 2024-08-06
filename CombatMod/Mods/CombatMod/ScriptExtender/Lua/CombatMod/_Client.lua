if Ext.IMGUI == nil then
    L.Error("IMGUI not available.", "Update to latest Script Extender.")
    return
end

Require("CombatMod/Shared")

-- ModEvent.Register("ModInit")

local isActive = false
function IsActive()
    return isActive
end

local function init()
    if isActive then
        return
    end
    isActive = true

    Require("CombatMod/ModActive/Client/_Init")

    Event.Trigger(GameState.EventLoad)

    Event.Trigger("ModInit")
end

Require("CombatMod/Overwrites")

Net.On("ModActive", init, true)
