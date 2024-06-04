---@type Mod
Mod = Require("Hlib/Mod")
Mod.Debug = true
Mod.Dev = false
Mod.EnableRCE = true
Mod.Prefix = "DOLL"
Mod.TableKey = "DOLL"

---@type Utils
local Utils = Require("Hlib/Utils")

U = Utils
UT = Utils.Table
US = Utils.String
UE = Utils.Entity
L = Utils.Log

---@type Constants
local Constants = Require("Hlib/Constants")

---@type DollConstants
C = UT.Merge(Constants, Require("DOLL/Shared/Constants"))

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
