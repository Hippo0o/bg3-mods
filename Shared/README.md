# The H(ippo0o) Lib(rary)

# What is it?

Hlib is a library that contains a lot of useful functions that can be used as a base for SE heavy projects.

# How to use it?

Copy the Hlib folder to your `ScriptExtender/Lua/` folder and require it in your script.
In your `BootstrapClient.lua` or `BootstrapServer.lua` add the following lines at the top of the file:

```lua
Ext.Require('Hlib/_Init.lua')
Ext.Require('...') -- your entry point
```

# What's in it?

### Require

The `Require` function is a alternative to the `Ext.Require` function that allows you to modularize your code easier.
`.lua` is optional and will be added automatically if not provided.

```lua
---@type Mod
local Mod = Require('Hlib/Mod')
```

### Mod

The `Mod` module does basic mod bootstrapping aswell as `PersistentVars` handling.

```lua
Mod.Debug = true
Mod.PersistentVarsTemplate = {
    MyVar = 0,
    MyTable = {}
}
```

### Constants

The `Constants` module has some predefined constants that can be used in your scripts and is used for Utils functions.
To extend the Constants use the following code in your script:

```lua
---@type Constants
local Constants = Require('Hlib/Constants')
---@type Utils
local Utils = Require('Hlib/Utils')

Utils.Table.Merge(Constants, {
    MyConstant = 'MyValue'
})
```

### Utils

The `Utils` module contains a lot of useful functions that can be used in your scripts.

```lua
---@type Utils
local Utils = Require("Hlib/Utils")
-- table functions
Utils.Table.Merge({ a = 1 }, { b = 2 }) -- {a = 1, b = 2}
Utils.Table.Extend({ 1, 2 }, { 1, 3 }) -- {1, 2, 1, 3}
Utils.Table.Filter({ 1, 2, 3 }, function(v) return v > 1 end) -- {2, 3}
Utils.Table.Map({ 1, 2, 3 }, function(v) return v * 2 end) -- {2, 4, 6}
Utils.Table.DeepClone({ a = { b = 1 } }) -- {a = {b = 1}}
-- string functions
Utils.String.Split("Hello World!", " ") -- {'Hello', 'World!'}
Utils.String.Contains('Hello World!', {'Hi', 'Hello', 'Bye'}) -- true
-- some more functions
Utils.Equals({ a = 1 }, { a = 1 }) -- true
Utils.UUID.Equals('Foo_00000000-0000-0000-0000-000000000000', 'Bar_00000000-0000-0000-0000-000000000000') -- true
```

More functions can be found in the `Utils` module.

### GameUtils

The `GameUtils` module contains some useful functions for interacting with the game.

```lua
---@type GameUtils
local GameUtils = Require("Hlib/GameUtils")

GameUtils.Entity.GetNearby(Osi.GetHostCharacter(), 10) -- {{Entity, Guid, Distance}, ...}

GameUtils.Character.IsOrigin(Osi.GetHostCharacter()) -- true
GameUtils.Character.RemoveSpell(character, learnedSpell, sourceType, class)

-- db with 2 columns, query 2nd column value, take 1st column, returns table of values
GameUtils.DB.TryGet("DB_Sees", 2, { nil, Osi.GetHostCharacter() }, 1) -- {"xxxx-xx", ...}
```

More functions can be found in the `GameUtils` module.

## Optional Modules

### Async

The `Async` module for Async programming.

```lua
---@type Async
local Async = Require("Hlib/Async")

-- run function after 1 second
Async.Defer(1000, function()
    print("Hello World!")
end)
Async.Defer(1000):After(function()
    print("Hello World!")
end)

-- run function every 1 second (indefinitly)
local handle = Async.Interval(1000, function()
    print("Hello World!")
end)
-- can be stopped manually
handle:Unregister()

-- run a function when a condition is met
Async.WaitUntil(function()
    return var == true
end):After(function()
    print("Hello World!")
    return Async.Defer(1000)
end):After(function()
    print("Hello World! 1s later")
end)

-- run a function every x second until a condition is met or tries are over
Async.RetryUntil(function(self, triesLeft, time)
    -- can be any code here
    return var == true
end, { retries = 3, interval = 1000 }):After(function()
    print("Hello World!")
end):Catch(function(_, err)
    print(var .. " is not true")
end)
```

### Event

The `Event` module for a custom event bus.

```lua
---@type Event
local Event = Require("Hlib/Event")

-- subscribe to an event
Event.On("MyEvent", function(arg1, arg2)
    print(arg1, arg2)
end)

-- emit an event
Event.Trigger("MyEvent", "Hello", "World!")
```

### Net

The `Net` module for network communication between clients and server.

```lua
---@type Net
local Net = Require("Hlib/Net")

-- subscribe to a network event (server-side or client-side)
Net.On("MyEvent", function(event) ---@type NetEvent
    print("Received MyEvent: " .. event.Payload.MyData)
end)

-- send a network event (client-side or server-side)
Net.Send("MyEvent", { MyData = "Hello World!" })

-- subscribe to a network event (server-side only)
Net.On("RequestData", function(event) ---@type NetEvent
    -- example
    local data = Osi.IsInCombat(event.Payload.Entity)

    Net.Respond(event, data)
end)

-- request a network event (client-side only)
Net.Request("RequestData", { Entity = "..." }):After(function(event) ---@type NetEvent
    print("Received RequestData response: " .. event.Payload)
end)
```

`Net` is using `Event` internally to handle the network events.

```lua
---@type Event
local Event = Require("Hlib/Event")

Event.On(Net.EventName("MyEvent"), function(event) ---@type NetEvent
    print("Received MyEvent: " .. event.Payload.MyData)
end)

--- does not transmit the event to the server/client but triggers the event locally
Event.Trigger(Net.EventName("MyEvent"), { MyData = "Hello World!" })
```

### GameState

The `GameState` module handles events when saving and loading game states.

```lua
---@type GameState
local GameState = Require("Hlib/GameState")

GameState.OnSave(function()
    print("Game is saving!")
end)

GameState.OnLoad(function()
    print("Game is loading!")
end)
```

`GameState` is using `Event` internally to handle the game state events.

```lua
---@type Event
local Event = Require("Hlib/Event")

Event.On(GameState.EventSave, function()
    print("Game is saving!")
end)

Event.Trigger(GameState.EventSave)
```

### Libs

The `Libs` module contains a class implementation.

```lua
---@type Libs
local Libs = Require("Hlib/Libs")

local MyStruct = Libs.Struct({
    MyVar = 0,
    MyFunction = function(self)
        print(self.MyVar)
    end
})

local myObject = MyStruct.New()
myObject:MyFunction() -- 0
myObject.MyVar = 1
myObject:MyFunction() -- 1

-- restore existing tables to class (useful for PersistentVars)
local myObject2 = MyStruct.Init({ MyVar = 3 })
```

# Example Setup

`BootstrapServer.lua`

```lua
Ext.Require('Hlib/_Init.lua')
Ext.Require('MyMod/_Server.lua')
```

`MyMod/_Server.lua`

```lua
Require('MyMod/Shared.lua')

Log.Info("Hello World!")
-- your server code here
```

`MyMod/Shared.lua`

```lua
---@type Mod
Mod = Require('Hlib/Mod')
---@type Constants
Constants = Require('Hlib/Constants')
---@type Utils
Utils = Require('Hlib/Utils')
---@type Utils
Log = Require('Hlib/Log')
---@type Event
Event = Require('Hlib/Event')
---@type GameState
GameState = Require('Hlib/GameState')

Mod.Debug = true
Mod.PersistentVarsTemplate = {
    MyVar = 0,
    MyTable = {}
}

Utils.Table.Merge(Constants, {
    MyConstant = 'MyValue'
})
```
