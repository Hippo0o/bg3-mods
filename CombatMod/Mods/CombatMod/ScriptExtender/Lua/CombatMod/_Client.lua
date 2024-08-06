if Ext.IMGUI == nil then
    L.Warn("IMGUI not available.", "Update to Script Extender v16.")
    return
end

Require("CombatMod/Shared")

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
end

Require("CombatMod/Overwrites")

Net.On("ModActive", init, true)
