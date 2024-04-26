local GustavDevUUID = "28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"

local function newRequire(path, env)
    local modPath = path:gsub("/[^/]+%.lua$", "")
    local register = {}
    return function(module)
        if not string.match(module, ".lua$") then
            module = module .. ".lua"
        end

        if register[module] then
            return register[module]
        end

        -- local result = Ext.Utils.LoadString(Ext.IO.LoadFile(table.concat({ modPath, module }, "/"), "data"))()
        local result = Ext.Utils.Include(nil, table.concat({ modPath, module }, "/"), env)

        register[module] = result

        return result
    end
end

local function loadBootstrap(path, modTable)
    local function print(...)
        _P("[Loader " .. modTable .. "]", ...)
    end

    local env = {
        -- Put frequently used items directly into the table for faster access
        type = type,
        tostring = tostring,
        tonumber = tonumber,
        pairs = pairs,
        ipairs = ipairs,
        print = print,
        error = error,
        next = next,

        string = string,
        math = math,
        table = table,

        Ext = Ext,
        Osi = Osi,
        Game = Game,
        Sandboxed = true,

        ModuleUUID = modTable .. "_" .. GustavDevUUID,
    }
    -- The rest are accessed via __index
    setmetatable(env, { __index = _G })
    Mods[modTable] = env

    -- Custom require function that loads files a bit differently from Ext.Require
    env.Require = newRequire(path, env)

    do -- PersistentVars from ModVariable of GustavDev
        Ext.Vars.RegisterModVariable(GustavDevUUID, modTable, {
            Server = Ext.IsServer(),
            Client = Ext.IsClient(),
            SyncToClient = false,
        })

        local vars = Ext.Vars.GetModVariables(GustavDevUUID)
        if not vars[modTable] then
            print("Creating PersistentVars")
            vars[modTable] = {}
        else
            print("Loading PersistentVars")
        end

        env.PersistentVars = vars[modTable]
        Ext.Vars.SyncModVariables(GustavDevUUID)
        Ext.Events.GameStateChanged:Subscribe(function(e)
            if e.FromState == "Running" and e.ToState == "Save" then
                vars[modTable] = env.PersistentVars
                print("Saving PersistentVars")
                Ext.Vars.SyncModVariables(GustavDevUUID)
            end
        end)
    end

    env._G = env

    print("Loading bootstrap script: " .. path)
    Ext.Utils.Include(nil, path, env)
end

loadBootstrap("Mods/MyMod/ScriptExtender/Lua/ServerLoader.lua", "MyMod")
