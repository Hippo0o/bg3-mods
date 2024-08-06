---@type Mod
local Mod = Require("Shared/Mod")

local tt = Libs.TypedTable

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            File                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

External.File = {}

local function filePath(name)
    return Mod.ModPrefix .. "/" .. name .. ".json"
end

function External.File.Exists(name)
    return Ext.IO.LoadFile(filePath(name)) ~= nil
end

function External.File.Import(name)
    if External.File.Exists(name) then
        local ok, result = pcall(Ext.Json.Parse, Ext.IO.LoadFile(filePath(name)))
        if not ok then
            L.Error("Failed to parse file.", filePath(name), result)
            return
        end

        return result
    end
end

function External.File.Export(name, data)
    return Ext.IO.SaveFile(filePath(name), Ext.Json.Stringify(data))
end

function External.File.ExportIfNeeded(name, data)
    if not External.File.Exists(name) then
        External.File.Export(name, data)
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Validators                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

External.Validators = {}

External.Validators.Config = tt({
    -- ForceCombatRestart = { "nil", "boolean" },
    RandomizeSpawnOffset = { "nil", "number" },
    ForceEnterCombat = { "nil", "boolean" },
    BypassStory = { "nil", "boolean" },
    BypassStoryAlways = { "nil", "boolean" },
    LootIncludesCampSlot = { "nil", "boolean" },
    Debug = { "nil", "boolean" },
})

External.Validators.Enemy = tt({
    Name = { "string" },
    TemplateId = { U.UUID.IsGUID },
    Tier = { C.EnemyTier },
    IsBoss = { "nil", "boolean" },
    LevelOverride = { "nil", "number" },
    Equipment = { "nil", "string" },
    Stats = { "nil", "string" },
    SpellSet = { "nil", "string" },
    AiHint = { "nil", U.UUID.IsGUID },
    Archetype = { "nil", "string" },
    CharacterVisualResourceID = { "nil", U.UUID.IsGUID },
    Icon = { "nil", "string" },
})

local posType = tt({
    { "number" }, -- x
    { "number" }, -- y
    { "number" }, -- z
})

External.Validators.Map = tt({
    Region = { "string" },
    Enter = { posType },
    Spawns = tt(posType, true),
})

local function validateTimelineEntry(value)
    if Enemy.Find(value) ~= nil then
        return true
    end

    return false, "value needs to be [" .. table.concat(C.EnemyTier, " ") .. "], a name or templateId"
end
External.Validators.Scenario = tt({
    Name = { "string" },
    Timeline = tt({
        tt({
            { "nil", C.EnemyTier, validateTimelineEntry },
        }, true),
    }, true),
    Loot = tt({
        Objects = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
        Armor = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
        Weapons = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
    }),
})

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                      Template Loaders                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

External.Templates = {}

function External.Templates.GetMaps()
    local exists = External.File.Exists("Maps")
    if not exists then
        return nil
    end

    local data = External.File.Import("Maps")
    if data == nil then
        return {}
    end

    for k, map in pairs(data) do
        local ok, error = External.Validators.Map:Validate(map)
        if not ok then
            L.Error("Invalid map data.", Ext.DumpExport({ Data = map, Error = { [tostring(k)] = error } }))
            return {}
        end
    end

    return data
end

function External.Templates.GetScenarios()
    local exists = External.File.Exists("Scenarios")
    if not exists then
        return nil
    end

    local data = External.File.Import("Scenarios")
    if data == nil then
        return {}
    end

    for k, scenario in pairs(data) do
        local ok, error = External.Validators.Scenario:Validate(scenario)
        if not ok then
            L.Error("Invalid scenario data.", Ext.DumpExport({ Data = scenario, Error = { [tostring(k)] = error } }))
            return {}
        end
    end

    return data
end

function External.Templates.GetEnemies()
    local exists = External.File.Exists("Enemies")
    if not exists then
        return nil
    end

    local data = External.File.Import("Enemies")
    if data == nil then
        return {}
    end

    for k, enemy in pairs(data) do
        local ok, error = External.Validators.Enemy:Validate(enemy)
        if not ok then
            L.Error("Invalid enemy data.", Ext.DumpExport({ Data = enemy, Error = { [tostring(k)] = error } }))
            return {}
        end
    end

    return data
end

function External.LoadConfig()
    local c = External.File.Import("Config")
    if c == nil then
        External.SaveConfig()
        return
    end

    local ok, error = External.Validators.Config:Validate(c)
    if not ok then
        L.Error("Invalid config data.", Ext.DumpExport({ Data = c, Error = error }))
        return
    end

    for _, field in pairs(External.Validators.Config:GetFields()) do
        if c[field] ~= nil then
            if field == "Debug" then
                Mod.Debug = c[field]
            end
            Config[field] = c[field]
        end
    end

    return true
end

function External.SaveConfig()
    local ok, error = External.Validators.Config:Validate(Config)
    if not ok then
        L.Error("Invalid config data.", Ext.DumpExport({ Data = c, Error = error }))
        return
    end

    local config = UT.Filter(Config, function(value, key)
        return UT.Contains(External.Validators.Config:GetFields(), key)
    end, true)
    External.File.Export("Config", config)
end
