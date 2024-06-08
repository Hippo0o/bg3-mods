Require("GOV/Shared")

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

Require("GOV/Client/Components")

GameState.OnLoad(function()
    Require("GOV/Client/Window")
end, true)
