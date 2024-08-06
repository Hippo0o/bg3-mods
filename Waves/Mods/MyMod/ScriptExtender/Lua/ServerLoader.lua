Require("Shared/_Init")
Require("MyMod/_Init")

Require("Shared/Mod").PreparePersistentVars()

Require("Shared/GameState").OnLoadedActions({ FromState = "Sync", ToState = "Running" })
