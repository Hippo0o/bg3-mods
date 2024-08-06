---@type Mod
local Mod = Require("Hlib/Mod")

local tt = Libs.TypedTable

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            File                                             --
--                                                                                             --
-------------------------------------------------------------------------------------------------

External.File = {}

local function filePath(name, dir)
    if name:sub(-5) ~= ".json" then
        name = name .. ".json"
    end

    if US.Contains(name, { "Enemies", "Maps", "Scenarios" }) then
        name = string.format("v%d.%d/%s", Mod.Version.major, Mod.Version.minor, name)
    end

    return name
end

function External.File.Exists(name)
    return IO.Exists(filePath(name))
end

function External.File.Import(name)
    local filePath = filePath(name)

    if External.File.Exists(name) then
        local ok, result = pcall(IO.LoadJson, filePath)
        if not ok then
            L.Error("Failed to parse file.", filePath, result)
            return
        end

        return result
    end
end

function External.File.Export(name, data)
    return IO.SaveJson(filePath(name), data)
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
    ExpMultiplier = { "nil", "number" },
    ForceEnterCombat = { "nil", "boolean" },
    BypassStory = { "nil", "boolean" },
    LootIncludesCampSlot = { "nil", "boolean" },
    SpawnItemsAtPlayer = { "nil", "boolean" },
    Debug = { "nil", "boolean" },
    TurnOffNotifications = { "nil", "boolean" },
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
    Race = { "nil", U.UUID.IsValid },
    Icon = { "nil", "string" },
})

local positionTimelineType = { "nil", tt({ "nil", "number" }, true) }

local posType = tt({
    { "number" }, -- x
    { "number" }, -- y
    { "number" }, -- z
})

External.Validators.Map = tt({
    Region = { "string" },
    Enter = { posType },
    Spawns = tt(posType, true),
    Timeline = positionTimelineType,
    Author = { "nil", "string" },
})

local function validateTimelineEntry(value)
    if type(value) == "string" and Enemy.Find(value) ~= nil then
        return true
    end

    return false, "value needs to be [" .. table.concat(C.EnemyTier, " ") .. "], a name or templateId"
end
External.Validators.Scenario = tt({
    Name = { "string" },
    Timeline = {
        "function",
        tt({
            tt({ "nil", C.EnemyTier, validateTimelineEntry }, true),
        }, true),
    },
    Positions = positionTimelineType,
    Map = { "nil", "string" },
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

local function validateAndError(validator, data, key)
    local ok, error = validator:Validate(data)
    if not ok then
        L.Error("Invalid data.", Ext.DumpExport({ Data = data, Error = { [tostring(key)] = error } }))
        return false
    end

    return true
end

local addedMaps = {}
function External.Templates.AddMap(data)
    if validateAndError(External.Validators.Map, data, "AddMap") then
        table.insert(addedMaps, data)
    end
end

local addedEnemies = {}
function External.Templates.AddEnemy(data)
    if validateAndError(External.Validators.Enemy, data, "AddEnemy") then
        table.insert(addedMaps, data)
    end
end

local addedScenarios = {}
function External.Templates.AddScenario(data)
    if validateAndError(External.Validators.Scenario, data, "AddScenario") then
        table.insert(addedScenarios, data)
    end
end

local addedUnlocks = {}
function External.Templates.AddUnlock(data)
    if validateAndError(External.Validators.Unlock, data, "AddUnlock") then
        table.insert(addedUnlocks, data)
    end
end

function External.Templates.GetMaps(defaults)
    local exists = External.File.Exists("Maps")
    if not exists then
        return UT.Combine({}, addedMaps, defaults)
    end

    local data = External.File.Import("Maps")
    if data == nil then
        data = {}
    end

    data = UT.Combine({}, addedMaps, data)

    for k, map in pairs(data) do
        if not validateAndError(External.Validators.Map, map, k) then
            return {}
        end
    end

    return data
end

function External.Templates.GetScenarios(defaults)
    local exists = External.File.Exists("Scenarios")
    if not exists then
        return UT.Combine({}, addedScenarios, defaults)
    end

    local data = External.File.Import("Scenarios")
    if data == nil then
        data = {}
    end

    data = UT.Combine({}, addedScenarios, data)

    for k, scenario in pairs(data) do
        if not validateAndError(External.Validators.Scenario, scenario, k) then
            return {}
        end
    end

    return data
end

function External.Templates.GetEnemies(default)
    local exists = External.File.Exists("Enemies")
    if not exists then
        return UT.Combine({}, addedEnemies, default)
    end

    local data = External.File.Import("Enemies")
    if data == nil then
        data = {}
    end

    data = UT.Combine({}, addedEnemies, data)

    for k, enemy in pairs(data) do
        if not validateAndError(External.Validators.Enemy, enemy, k) then
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

    Event.Trigger("ConfigChanged", Config)
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
