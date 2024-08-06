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

    if US.Contains(name, { "Enemies", "Maps", "Scenarios", "LootRates" }) then
        name = string.format("v%d.%d/%s", Mod.Version.Major, Mod.Version.Minor, name)
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
    RandomizeSpawnOffset = { "nil", "number" },
    ExpMultiplier = { "nil", "number" },
    BypassStory = { "nil", "boolean" },
    LootIncludesCampSlot = { "nil", "boolean" },
    SpawnItemsAtPlayer = { "nil", "boolean" },
    Debug = { "nil", "boolean" },
    TurnOffNotifications = { "nil", "boolean" },
    ClearAllEntities = { "nil", "boolean" },
    MulitplayerRestrictUnlocks = { "nil", "boolean" },
    AutoTeleport = { "nil", "number" },
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

local lootRatesType = tt({
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
})

External.Validators.LootRates = lootRatesType

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
    Loot = {
        "nil",
        lootRatesType,
    },
})
External.Validators.Unlock = tt({
    Id = { "string" },
    Name = { "string" },
    Icon = { "string" },
    Cost = { "number" },
    Amount = { "nil", "number" },
    Character = { "boolean" },
    Requirement = { "nil", "number", "string", tt({ "number", "string" }, true) },
    Persistent = { "nil", "boolean" },
    OnBuy = { "nil", "function" },
    OnReapply = { "nil", "function" },
    -- set by system
    Bought = { "nil" },
    BoughtBy = { "nil" },
    Unlocked = { "nil" },
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
        table.insert(addedEnemies, data)
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

local patchMaps = {}
function External.Templates.PatchMaps(func)
    assert(type(func) == "function", "PatchMaps(func) needs to be a function.")
    table.insert(patchMaps, func)
end

local patchScenarios = {}
function External.Templates.PatchScenarios(func)
    assert(type(func) == "function", "PatchScenarios(func) needs to be a function.")
    table.insert(patchScenarios, func)
end

local patchEnemies = {}
function External.Templates.PatchEnemies(func)
    assert(type(func) == "function", "PatchEnemies(func) needs to be a function.")
    table.insert(patchEnemies, func)
end

local patchUnlocks = {}
function External.Templates.PatchUnlocks(func)
    assert(type(func) == "function", "PatchUnlocks(func) needs to be a function.")
    table.insert(patchUnlocks, func)
end

function External.Templates.GetMaps()
    local data = External.File.Import("Maps") or Templates.GetMaps()

    data = UT.Combine({}, addedMaps, data)

    for k, map in pairs(data) do
        for _, patch in ipairs(patchMaps) do
            xpcall(function()
                map = patch(map)
            end, function(e)
                L.Error("Failed to patch map.", Ext.DumpExport({ Map = map, Error = e }))
            end)
        end

        if not map or not validateAndError(External.Validators.Map, map, k) then
            data[k] = nil
        end
    end

    return UT.Values(data)
end

function External.Templates.GetScenarios()
    local data = External.File.Import("Scenarios") or Templates.GetScenarios()

    data = UT.Combine({}, addedScenarios, data)

    for k, scenario in pairs(data) do
        for _, patch in ipairs(patchScenarios) do
            xpcall(function()
                scenario = patch(scenario)
            end, function(e)
                L.Error("Failed to patch scenario.", Ext.DumpExport({ Scenario = scenario, Error = e }))
            end)
        end

        if not scenario or not validateAndError(External.Validators.Scenario, scenario, k) then
            data[k] = nil
        end
    end

    return UT.Values(data)
end

function External.Templates.GetEnemies()
    local data = External.File.Import("Enemies") or Templates.GetEnemies()

    data = UT.Combine({}, addedEnemies, data)

    for k, enemy in pairs(data) do
        for _, patch in ipairs(patchEnemies) do
            xpcall(function()
                enemy = patch(enemy)
            end, function(e)
                L.Error("Failed to patch enemy.", Ext.DumpExport({ Enemy = enemy, Error = e }))
            end)
        end

        if not enemy or not validateAndError(External.Validators.Enemy, enemy, k) then
            data[k] = nil
        end
    end

    return UT.Values(data)
end

function External.Templates.GetUnlocks()
    local data = UT.Combine({}, addedUnlocks, Templates.GetUnlocks())

    for k, unlock in pairs(data) do
        for _, patch in ipairs(patchUnlocks) do
            xpcall(function()
                unlock = patch(unlock)
            end, function(e)
                L.Error("Failed to patch unlock.", Ext.DumpExport({ Unlock = unlock, Error = e }))
            end)
        end

        if not unlock or not validateAndError(External.Validators.Unlock, unlock, k) then
            data[k] = nil
        end
    end

    return UT.Values(data)
end

function External.LoadLootRates()
    local data = External.File.Import("LootRates") or {}

    if not validateAndError(External.Validators.LootRates, data, "LootRates") then
        return
    end

    local orig = UT.DeepClone(C.LootRates)
    local ok = xpcall(function()
        C.LootRates = UT.Merge(C.LootRates, data)
    end, function(e)
        C.LootRates = orig
    end)

    return ok
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
