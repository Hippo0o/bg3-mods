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

        local result = Ext.Require(module)
        register[module] = result

        return result
    end
end

---@type Mod
local Mod = Require("Shared/Mod")

Require("Shared/Constants")
---@type Utils
local Utils = Require("Shared/Utils")
Require("Shared/Libs")
Require("Shared/Event")
Require("Shared/GameState")
Require("Shared/Async")
Require("Shared/Net")
Require("Shared/OsirisEventDebug")

Ext.Events.SessionLoaded:Subscribe(function()
    local ModInfo = Ext.Mod.GetMod(Mod.ModUUID)["Info"]

    Mod.ModTableKey = ModInfo.Name
    Mod.ModVersion = { major = ModInfo.ModVersion[1], minor = ModInfo.ModVersion[2], revision = ModInfo.ModVersion[3] }

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
