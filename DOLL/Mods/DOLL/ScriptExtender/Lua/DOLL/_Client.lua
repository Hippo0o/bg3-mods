Require("DOLL/Shared")

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

Require("DOLL/Client/Components")

GameState.OnLoad(function()
    Require("DOLL/Client/Window")
end, true)
