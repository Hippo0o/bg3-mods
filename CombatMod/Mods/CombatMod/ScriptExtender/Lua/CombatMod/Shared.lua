---@type Mod
Mod = Require("Hlib/Mod")
Mod.EnableRCE = true
Mod.Prefix = "Trials of Tav"
Mod.TableKey = "ToT"

Require("Hlib/StandardLib") -- extends global metatables

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Log
local Log = Require("Hlib/Log")

---@type GameUtils
local GameUtils = Require("Hlib/GameUtils")

U = Utils
L = Log
UT = Utils.Table
US = Utils.String
GU = GameUtils
GE = GameUtils.Entity
GC = GameUtils.Character

---@type IO
IO = Require("Hlib/IO")

Mod.Dev = IO.Exists("DevMode")
Mod.Debug = Mod.Dev

---@type GameState
GameState = Require("Hlib/GameState")

---@type ModEvent
ModEvent = Require("Hlib/ModEvent")

---@type Async
Async = Require("Hlib/Async")
WaitUntil = Async.WaitUntil
WaitTicks = Async.WaitTicks
RetryUntil = Async.RetryUntil
Schedule = Async.Schedule
Defer = Async.Defer
Debounce = Async.Debounce
Throttle = Async.Throttle
Interval = Async.Interval

---@type Libs
Libs = Require("Hlib/Libs")

---@type Net
Net = Require("Hlib/Net")

---@type Event
Event = Require("Hlib/Event")

---@type Localization
Localization = Require("Hlib/Localization")
__ = Localization.Localize

Require("CombatMod/Constants")
