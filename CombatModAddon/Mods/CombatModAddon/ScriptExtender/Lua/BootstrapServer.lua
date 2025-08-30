ModuleUUID = "edd53e42-3753-4b47-ac7a-9a5736fd2886"

local register = {}
function Require(file)
    if not register[file] then
        register[file] = { Ext.Utils.Include(ModuleUUID, file, _G) }
    end
    return table.unpack(register[file])
end

Ext.Events.SessionLoaded:Subscribe(function()
    if not Ext.Mod.IsModLoaded("e6f0c417-36f9-42d6-9617-fd7fe2efd626") then
        Ext.Utils.PrintError("Trials of Tav is required.")
        return
    end

    local function log(message)
        Mods.ToT.L.Info(Mods.ToT.L.ColorText("Addon Mod", { 200, 255, 200 }), message)
    end

    -- include file with ToT table as _G
    -- local function include(file)
    --     Ext.Utils.Include(ModuleUUID, file, Mods.ToT)
    -- end

    -- On mod active check what mods are loaded and include addons
    Ext.ModEvents.ToT.ModActive:Subscribe(function()
        -- if Ext.Mod.IsModLoaded("49a94025-c3e4-461f-bc08-2de6a629666c") then
        --     log("AdditionalEnemies detected.")
        --
        --     -- include file with ToT table as _G
        --     include("Mods/AdditionalEnemies.lua")
        -- end

        if Ext.Mod.IsModLoaded("fa49db03-caa7-49c8-7c76-e6c38b60267a") then
            log("AdvancedTTSpells detected.")

            Require("Mods/AdvancedTTSpells/_Init.lua")
        end
    end, { Once = true })
end)
