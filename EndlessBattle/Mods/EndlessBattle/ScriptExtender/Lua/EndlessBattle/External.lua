---@type Mod
local Mod = Require("Hlib/Mod")

---@type LibsTypedTable
local tt = Libs.TypedTable

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            File                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

External.File = {}

local function filePath(name)
    if name:sub(-5) ~= ".json" then
        name = name .. ".json"
    end
    return name
end

function External.File.Exists(name)
    return IO.Exists(filePath(name))
end

function External.File.Import(name)
    name = filePath(name)

    if External.File.Exists(name) then
        local ok, result = pcall(IO.LoadJson, name)
        if not ok then
            L.Error("Failed to parse file.", name, result)
            return
        end

        return result
    end
end

function External.File.Export(name, data)
    return IO.SaveJson(filePath(name), data)
end

function External.File.ExportIfNeeded(name, data)
    name = filePath(name)

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
    ExpMultiplier = { "nil", "number" },
    ForceEnterCombat = { "nil", "boolean" },
    BypassStory = { "nil", "boolean" },
    BypassStoryAlways = { "nil", "boolean" },
    LootIncludesCampSlot = { "nil", "boolean" },
    SpawnItemsAtPlayer = { "nil", "boolean" },
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
    Timeline = {
        { "roguelike" },
        tt({
            tt({
                { "nil", C.EnemyTier, validateTimelineEntry },
            }, true),
        }, true),
    },
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

    External.ApplyConfig(c)

    return true
end

function External.ApplyConfig(config)
    local ok, error = External.Validators.Config:Validate(config)
    if not ok then
        L.Error("Invalid config data.", Ext.DumpExport({ Data = config, Error = error }))
        return
    end

    for _, field in pairs(External.Validators.Config:GetFields()) do
        if config[field] ~= nil then
            if field == "Debug" then
                Mod.Debug = config[field]
            end
            Config[field] = config[field]
        end
    end

    for key, value in pairs(config) do
        if key == "BypassStory" then
            if value == false then
                Config.BypassStoryAlways = false
            end
        end
        if key == "BypassStoryAlways" then
            if value == true then
                Config.BypassStory = true
            end
        end
    end
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
