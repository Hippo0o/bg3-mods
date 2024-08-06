Ext.Events.SessionLoaded:Subscribe(function()
    if not Ext.Mod.IsModLoaded("e6f0c417-36f9-42d6-9617-fd7fe2efd626") then
        Ext.Utils.PrintError("Trials of Tav is required.")
        return
    end

    local function log(message)
        Mods.ToT.L.Info(Mods.ToT.L.ColorText("Addon Mod", {200, 255, 200}), message)
    end

    -- include file with ToT table as _G
    local function include(file)
        Ext.Utils.Include(ModuleUUID, file, Mods.ToT)
    end

    -- On mod active check what mods are loaded and include addons
    Mods.ToT.Event.On("ModActive", function()
        if Ext.Mod.IsModLoaded("49a94025-c3e4-461f-bc08-2de6a629666c") then
            log("AdditionalEnemies detected.")

            -- include file with ToT table as _G
            include("Mods/AdditionalEnemies.lua")
        end
    end, true)
end)
