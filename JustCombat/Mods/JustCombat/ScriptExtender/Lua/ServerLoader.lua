Require("Shared/_Init")
Require("JustCombat/_Init")

Require("Shared/Mod").PreparePersistentVars()

Require("Shared/GameState").OnLoadedActions({ FromState = "Sync", ToState = "Running" })
