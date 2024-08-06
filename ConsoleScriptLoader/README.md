Useful for loading Lua code in Multiplayer while not having to share the same mods.


# Load scripts from SE Console

Execute this code in Console to load the Loader.lua
from `Data/Mods/` folder:

```lua
Ext.Utils.Include(nil, "Mods/Loader.lua")
```

from `%UserProfile%/Script Extender` folder:

```lua
Ext.Utils.LoadString(Ext.IO.LoadFile("Loader.lua"))()
```

# Compatiblitity

Only Lua scripts are supported. Other Mod files wont work.
Also functions like `Ext.Stats.GetStatsLoadedBefore(...)` are not available.
Early events like `SessionLoaded` are not available.

## Requirement

`Ext.Require` needs to be replaced with `Require` everywhere in your Lua for it work.

### Tip: Define this in your BootstrapClient.lua/BootstrapServer.lua for general use:

```lua
Require = Ext.Require
```

Be aware that `Ext.Require` behaves a bit differently than the `Require` implementation in this loader.

## Require function

The `Require` function is a simple implementation of a module loader. It will load the file and execute it in the current context.
It might not fully support the 2nd parameter of `Ext.Require`.

## Separate entryscript

define a standalone entry script for your mod e.g. ServerLoader.lua

```lua
-- requires like in BootstrapServer.lua
Require("Shared/_Init.lua")
Require("Server/_Init.lua")

-- execute code that would usually run on SessionLoaded
-- example:
for k, v in pairs(PersistentVarsTemplate) do
    if PersistentVars[k] == nil then
        PersistentVars[k] = v
    end
end
```

## PersistentVars

The usual `PersistentVars` is not directly available. As a workaround it uses ModVariables to store the data per defined ModTable.
Every Game should have the GustavDev mod with the id `28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8` enabled. This mod is used to store the ModVariables.
*needs more testing*

# define Mods to load

### TODO maybe define mods per json

in Loader.lua add:

```lua
loadBootstrap("Mods/MyMod/ScriptExtender/Lua/ServerLoader.lua", "MyMod")
```
