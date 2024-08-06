Require("Hlib/_Init")
Require("JustCombat/_Init")

Require("Hlib/Mod").PreparePersistentVars()

Require("Hlib/GameState").OnLoadedActions({ FromState = "Sync", ToState = "Running" })
