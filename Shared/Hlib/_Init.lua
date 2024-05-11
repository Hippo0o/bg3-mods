if not Require then
    local register = {}
    ---@param module string
    function Require(module)
        if not string.match(module, ".lua$") then
            module = module .. ".lua"
        end

        if register[module] then
            return register[module]
        end

        local result = Ext.Utils.Include(ModuleUUID, module, _G)
        register[module] = result

        return result
    end
end

---@type Mod
local Mod = Require("Hlib/Mod")

Require("Hlib/Constants")
---@type Utils
local Utils = Require("Hlib/Utils")
-- Require("Hlib/Libs")
-- Require("Hlib/Event")
-- Require("Hlib/GameState")
-- Require("Hlib/Async")
-- Require("Hlib/Net")
-- Require("Hlib/OsirisEventDebug")

Ext.Events.SessionLoaded:Subscribe(function()
    Utils.Log.Info(
        Mod.ModTableKey
            .. " Version: "
            .. Mod.ModVersion.major
            .. "."
            .. Mod.ModVersion.minor
            .. "."
            .. Mod.ModVersion.revision
            .. " Loaded"
    )

    Mod.PreparePersistentVars()
end)
