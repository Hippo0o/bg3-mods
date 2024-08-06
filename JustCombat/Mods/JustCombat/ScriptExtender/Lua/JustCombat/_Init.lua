---@diagnostic disable: undefined-global

---@type Mod
local Mod = Require("Shared/Mod")
Mod.ModPrefix = "JustCombat"
Mod.ModUUID = "e1fb0ff5-dd5e-471d-b2c4-c19c288fa5e7"

---@type Utils
local Utils = Require("Shared/Utils")

U = Utils
UT = Utils.Table
UE = Utils.Entity
US = Utils.String
L = Utils.Log

---@type Scenario|nil
S = nil

---@type Constants
C = Require("Shared/Constants")

UT.Merge(C, {
    ModUUID = Mod.ModUUID,
    EnemyFaction = "64321d50-d516-b1b2-cfac-2eb773de1ff6",
    NeutralFaction = "cfb709b3-220f-9682-bcfb-6f0d8837462e", -- NPC Neutral
    ItemRarity = {
        "Common",
        "Uncommon",
        "Rare",
        "VeryRare",
        "Legendary",
    },
    EnemyTier = {
        "low",
        "mid",
        "high",
        "ultra",
        "epic",
        "legendary",
    },
})

Mod.PersistentVarsTemplate = {
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = S,
}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Modules                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- lazy ass globals

---@type GameState
GameState = Require("Shared/GameState")

---@type Async
Async = Require("Shared/Async")
WaitFor = Async.WaitFor
RetryFor = Async.RetryFor
Schedule = Async.Schedule
Defer = Async.Defer

---@type Libs
Libs = Require("Shared/Libs")

Config = {
    ForceCombatRestart = false, -- restart combat every round to reroll initiative and let newly spawned enemies act immediately
    ForceEnterCombat = false, -- more continues battle between rounds at the cost of cheesy out of combat strats
    BypassStory = true, -- skip dialogues, combat and interactions that aren't related to a scenario
    BypassStoryAlways = false, -- always skip dialogues, combat and interactions even if no scenario is active
    LootIncludesCampSlot = false, -- include camp clothes in item lists
    Debug = false,
    RandomizeSpawnOffset = 3,
}
External = {}
Require("JustCombat/External")

External.LoadConfig()
External.File.ExportIfNeeded("Config", Config)

Player = {}
Scenario = {}
Enemy = {}
Map = {}
Item = {}
GameMode = {}

Require("JustCombat/Player")
Require("JustCombat/Scenario")
Require("JustCombat/Enemy")
Require("JustCombat/Map")
Require("JustCombat/Item")
Require("JustCombat/GameMode")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.RegisterSavingAction(function()
    PersistentVars.Scenario = S

    for obj, _ in pairs(PersistentVars.SpawnedEnemies) do
        if not Ext.Entity.Get(obj):IsAlive() then
            L.Debug("Cleaning up SpawnedEnemies", obj)
            PersistentVars.SpawnedEnemies[obj] = nil
        end
    end

    for obj, _ in pairs(PersistentVars.SpawnedItems) do
        if
            Item.IsOwned(obj) or Osi.IsItem(obj) == 0 -- was used
        then
            L.Debug("Cleaning up SpawnedItems", obj)
            PersistentVars.SpawnedItems[obj] = nil
        end
    end
end)

GameState.RegisterLoadingAction(function(state)
    if state.FromState == "Save" then
        return
    end

    External.LoadConfig()

    S = PersistentVars.Scenario
    if S ~= nil then
        Scenario.RestoreFromState(S)
    end
end)

GameState.RegisterUnloadingAction(function()
    S = nil
end)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Commands                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

do
    local Commands = {}
    Api = Commands -- Mods.JustCombat.Api

    local start = 0
    function Commands.Dev(new_start, amount)
        L.Info(":)")

        -- Osi.SetEditionForCustomBook("JustCombat", 0)
        -- Osi.AddEntryToCustomBook("JustCombat", "123\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        -- Osi.AddEntryToCustomBook("JustCombat", "123\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        -- Osi.AddEntryToCustomBook("JustCombat", "123\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        -- Osi.AddEntryToCustomBook("JustCombat", "123\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        -- Osi.OpenCustomBookUI(GetHostCharacter(), "JustCombat")

        -- if start == 0 then
        --     start = 1
        --     Require("Shared/EventDebug").Attach()
        -- end
        GameMode.AskUnlockAll()

        -- new_start = tonumber(new_start) or start
        -- amount = tonumber(amount) or 100
        --
        -- local j = 0
        -- local templates = {}
        -- for i, v in Enemy.Iter() do
        --     if i > new_start and (i - new_start) <= amount then
        --         table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
        --         j = j + 1
        --     end
        -- end
        -- start = new_start + j
        --
        -- local enemies = Enemy.GenerateEnemyList(templates)
        --
        -- Enemy.TestEnemies(enemies)
        -- local enemies = Enemy.GenerateEnemyList(Ext.Template.GetAllRootTemplates())
        -- Enemy.TestEnemies(enemies, false)
        -- local templates = {}
        -- for i, v in Enemy.Iter() do
        --     table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
        -- end
        -- local enemies = Enemy.GenerateEnemyList(templates)
        --
        -- Enemy.TestEnemies(enemies)

        -- Osi.TeleportToPosition(Player.Host(), 0, 0, 0, "", 1, 1, 1, 1, 0)
        -- Osi.MakePlayer("S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12", Player.Host())
        -- Osi.MakePlayer("S_Player_Karlach_2c76687d-93a2-477b-8b18-8a14b549304c", Player.Host())

        -- local list = {}
        -- for i, v in Enemy.iter() do
        --     local key = v.TemplateId .. v.Stats .. v.Equipment .. v.Tier .. v.CharacterVisualResourceID .. v.Icon
        --     L.Dump(key, list[key])
        --     list[key] = v
        -- end
        -- Ext.IO.SaveFile(
        --     "enemies.json",
        --     Ext.DumpExport(UT.Map(list, function(v)
        --         return v
        --     end))
        -- )
    end

    function Commands.Spawn(guid)
        local x, y, z = Player.Pos()

        local e = Enemy.SpawnTemplate(guid, x, y, z)
        if e == nil then
            L.Error("Enemy not found.", guid)
            return
        end

        WaitFor(function()
            return e:IsSpawned() and e:Entity():IsAlive()
        end, function()
            L.Dump(e, e:Entity().ServerCharacter)
            e:Combat()
        end)

        -- Defer(1000, function()
        --     Ext.IO.SaveFile("spawn-" .. e:GetId() .. ".json", Ext.DumpExport(e:Entity():GetAllComponents()))
        -- end)
    end

    function Commands.ToMap(id)
        local region = Player.Region()
        L.Info("Region", region)

        if not id and S then
            S.Map:Teleport(Player.Host())
            return
        end

        local maps = Map.Get(region)
        id = tonumber(id or 1)
        if maps == nil then
            L.Error("No maps found.")
            return
        end

        local map = maps[id]
        if map == nil then
            L.Error("Map not found.")
            return
        end

        map:Teleport(Player.Host())
    end

    function Commands.Kill(guid)
        Enemy.KillSpawned(guid)
    end

    function Commands.Clear()
        Enemy.Cleanup()
    end

    function Commands.Spawns(mapId, repeats)
        RetryFor(function()
            L.Info("Pinging spawns.")
            local mapId = tonumber(mapId)
            if not mapId then
                S.Map:PingSpawns()
                return
            end

            Map.Get()[tonumber(mapId)]:PingSpawns()
        end, {
            retries = tonumber(repeats) or 3,
        })
    end

    function Commands.Maps(id)
        local region = Player.Region()
        L.Info("Region: " .. region)

        local maps = Map.GetTemplates(region)
        if maps == nil then
            L.Error("No maps found.")
            return
        end

        L.Info("ID", "Name", "!JC Maps [id]")

        for i, v in pairs(maps) do
            if id and i == tonumber(id) then
                L.Info(i, v.Name, Ext.DumpExport(v))
            else
                L.Info(i, v.Name)
            end
        end
    end

    function Commands.Scenarios(id)
        L.Info("ID", "Name", "!JC Scenarios [id]")
        for i, v in pairs(Scenario.GetTemplates()) do
            if id and i == tonumber(id) then
                L.Info(i, v.Name, Ext.DumpExport(v))
            else
                L.Info(i, v.Name)
            end
        end
    end

    function Commands.Start(scenarioId, mapId)
        L.Info("!JC Scenarios", "List scenarios")
        L.Info("!JC Maps", "List maps")
        L.Info("!JC Start [scenarioId] [mapId]")
        if not scenarioId then
            L.Error("Scenario ID is required.")
            return
        end
        if not mapId then
            L.Error("Map ID is required.")
            return
        end

        local map = Map.Get(Player.Region())[tonumber(mapId)]
        local template = Scenario.GetTemplates()[tonumber(scenarioId)]
        if map == nil then
            L.Error("Map not found.")
            return
        end
        if template == nil then
            L.Error("Scenario not found.")
            return
        end

        L.Dump("Starting scenario.", id, template, map)

        Scenario.Start(template, map)
    end

    function Commands.Stop()
        Scenario.Stop()
    end

    function Commands.Dump(file)
        for i, v in pairs(S.SpawnedEnemies) do
            if v:IsSpawned() then
                L.Dump(UT.Filter(v:Entity().ServerCharacter, function(v, k)
                    return k ~= "Template" and k ~= "TemplateUsedForSpells"
                end, true))
                if file then
                    Ext.IO.SaveFile("dump-" .. v:GetId() .. ".json", Ext.DumpExport(v:Entity():GetAllComponents()))
                end
            end
        end
    end

    function Commands.Pos()
        local x, y, z = Player.Pos()
        L.Debug("Region", Player.Region())
        L.Debug("Position", table.concat({ x, y, z }, ", "))
    end

    function Commands.Items(rarity, type)
        local w = Item.Weapons(rarity)
        local o = Item.Objects(rarity)
        local a = Item.Armor(rarity)
        if type == "w" then
            L.Dump("Weapons", w)
        elseif type == "o" then
            L.Dump("Objects", o)
        elseif type == "a" then
            L.Dump("Armor", a)
        else
            L.Dump("Weapons", w)
            L.Dump("Armor", a)
            L.Dump("Objects", o)
        end
    end

    function Commands.Reload()
        if External.LoadConfig() then
            L.Info("Config reloaded.")
        end

        local m = External.Templates.GetMaps()
        if m then
            L.Info(#m, "Maps loaded.")
        else
            Map.ExportTemplates()
        end

        local s = External.Templates.GetScenarios()
        if s then
            L.Info(#s, "Scenarios loaded.")
        else
            Scenario.ExportTemplates()
        end

        local e = External.Templates.GetEnemies()
        if e then
            L.Info(#e, "Enemies loaded.")
        else
            Enemy.ExportTemplates()
        end
    end

    function Commands.StoryBypass(flag)
        Config.BypassStory = ("true" == flag or tonumber(flag) == 1) and true or false
        L.Info("Story bypass is", Config.BypassStory and "enabled" or "disabled")
    end
    function Commands.EnableStoryBypass()
        Commands.StoryBypass(1)
    end
    function Commands.DisableStoryBypass()
        Commands.StoryBypass(0)
    end

    Ext.RegisterConsoleCommand("JC", function(_, fn, ...)
        if fn == nil or Commands[fn] == nil then
            L.Dump("Available Commands", UT.Keys(Commands))
            return
        end

        Commands[fn](...)
    end)
end
