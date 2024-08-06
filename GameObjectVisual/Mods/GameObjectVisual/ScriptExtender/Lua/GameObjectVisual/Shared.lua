---@type Mod
Mod = Require("Hlib/Mod")
Mod.Debug = true
Mod.Dev = false
Mod.EnableRCE = true
Mod.Prefix = "GOV"
Mod.TableKey = "GOV"

---@type Utils
local Utils = Require("Hlib/Utils")

---@type GameUtils
local GameUtils = Require("Hlib/GameUtils")

U = Utils
L = Utils.Log
UT = Utils.Table
US = Utils.String
GU = GameUtils
GE = GameUtils.Entity
GC = GameUtils.Character

---@type Constants
local Constants = Require("Hlib/Constants")

---@type DollConstants
C = UT.Merge(Constants, Require("GOV/Shared/Constants"))

---@type GameState
GameState = Require("Hlib/GameState")

---@type Async
Async = Require("Hlib/Async")
Schedule = Async.Schedule
Defer = Async.Defer

---@type Libs
Libs = Require("Hlib/Libs")

---@type Net
Net = Require("Hlib/Net")

---@type Event
Event = Require("Hlib/Event")

---@type Localization
-- Localization = Require("Hlib/Localization")
-- __ = Localization.Localize
