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
    TemplateId = { U.UUID.IsValid },
    Tier = { C.EnemyTier },
    IsBoss = { "nil", "boolean" },
    LevelOverride = { "nil", "number" },
    Equipment = { "nil", "string" },
    Stats = { "nil", "string" },
    SpellSet = { "nil", "string" },
    AiHint = { "nil", U.UUID.IsValid },
    Archetype = { "nil", "string" },
    CharacterVisualResourceID = { "nil", U.UUID.IsValid },
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
        { C.RoguelikeScenario },
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

local function validateAndError(validator, data)
    local ok, error = validator:Validate(data)
    if not ok then
        L.Error("Invalid data.", Ext.DumpExport({ Data = data, Error = { [tostring(k)] = error } }))
        return false
    end

    return true
end

local addedMaps = {}
function External.Templates.AddMap(data)
    if validateAndError(External.Validators.Map, data) then
        table.insert(addedMaps, data)
    end
end

local addedEnemies = {}
function External.Templates.AddEnemy(data)
    if validateAndError(External.Validators.Enemy, data) then
        table.insert(addedMaps, data)
    end
end

local addedScenarios = {}
function External.Templates.AddScenario(data)
    if validateAndError(External.Validators.Scenario, data) then
        table.insert(addedScenarios, data)
    end
end

local addedUnlocks = {}
function External.Templates.AddUnlock(data)
    if validateAndError(External.Validators.Unlock, data) then
        table.insert(addedUnlocks, data)
    end
end

function External.Templates.GetMaps()
    local exists = External.File.Exists("Maps")
    if not exists then
        return nil
    end

    local data = External.File.Import("Maps")
    if data == nil then
        data = {}
    end

    for _, map in ipairs(addedMaps) do
        table.insert(data, map)
    end

    for k, map in pairs(data) do
        if not validateAndError(External.Validators.Map, map) then
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
        data = {}
    end

    for _, scenario in ipairs(addedScenarios) do
        table.insert(data, scenario)
    end

    for k, scenario in pairs(data) do
        if not validateAndError(External.Validators.Scenario, scenario) then
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
        data = {}
    end

    for _, enemy in ipairs(addedEnemies) do
        table.insert(data, enemy)
    end

    for k, enemy in pairs(data) do
        if not validateAndError(External.Validators.Enemy, enemy) then
            return {}
        end
    end

    return data
end

function External.Templates.GetUnlocks()
    return addedUnlocks
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
