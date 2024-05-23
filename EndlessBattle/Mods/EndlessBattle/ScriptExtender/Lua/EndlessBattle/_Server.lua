Require("EndlessBattle/Shared")

---@type Scenario|nil
S = nil

Mod.PersistentVarsTemplate = {
    Active = nil,
    RogueModeActive = false,
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = S,
    RogueScore = 0,
    GUIOpen = false,
    Stats = {
        Looted = {},
        Killed = {},
    },
    Currency = 0,
    Unlocked = {
        ExpMultiplier = false,
        LootMultiplier = false,
        CurrencyMultiplier = false,
    },
    Unlocks = {},
}

DefaultConfig = {
    ForceCombatRestart = false, -- restart combat every round to reroll initiative and let newly spawned enemies act immediately
    ForceEnterCombat = true, -- more continues battle between rounds at the cost of cheesy out of combat strats
    BypassStory = true, -- skip dialogues, combat and interactions that aren't related to a scenario
    BypassStoryAlways = false, -- always skip dialogues, combat and interactions even if no scenario is active
    LootIncludesCampSlot = false, -- include camp clothes in item lists
    Debug = false,
    RandomizeSpawnOffset = 3,
    ExpMultiplier = 3,
    SpawnItemsAtPlayer = false,
}
Config = UT.DeepClone(DefaultConfig)

External = {}
Require("EndlessBattle/Server/External")

External.LoadConfig()
External.File.ExportIfNeeded("Config", Config)

Player = {}
Scenario = {}
Enemy = {}
Map = {}
Item = {}
GameMode = {}
StoryBypass = {}
Unlock = {}

-- wrap event handlers in IfActive to prevent them from running when the mod is not active
function IfActive(func)
    return function(...)
        if PersistentVars.Active then
            func(...)
        end
    end
end

Require("EndlessBattle/Server/Player")
Require("EndlessBattle/Server/Scenario")
Require("EndlessBattle/Server/Enemy")
Require("EndlessBattle/Server/Map")
Require("EndlessBattle/Server/Item")
Require("EndlessBattle/Server/StoryBypass")
Require("EndlessBattle/Server/GameMode")
Require("EndlessBattle/Server/NetEvents")
Require("EndlessBattle/Server/Unlock")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.OnSave(function()
    PersistentVars.Scenario = S

    for obj, _ in pairs(PersistentVars.SpawnedEnemies) do
        if not Ext.Entity.Get(obj):IsAlive() then
            L.Debug("Cleaning up SpawnedEnemies", obj)
            PersistentVars.SpawnedEnemies[obj] = nil
        end
    end

    for obj, _ in pairs(PersistentVars.SpawnedItems) do
        if
            Item.IsOwned(obj) or Osi.IsItem(obj) ~= 1 -- was used
        then
            L.Debug("Cleaning up SpawnedItems", obj)
            PersistentVars.SpawnedItems[obj] = nil
        end
    end
end)

GameState.OnSessionLoad(function()
    External.LoadConfig()

    Async.Run(function() -- runs on OnLoad instead of OnSessionLoad
        if PersistentVars.Active == nil then
            GameMode.AskOnboarding()
        end

        S = PersistentVars.Scenario
        if S ~= nil then
            Scenario.RestoreFromState(S)
        end
    end)
end)

GameState.OnLoad(IfActive(function()
    if PersistentVars.GUIOpen then
        Defer(1000, function()
            Net.Send("OpenGUI")
        end)
    end
end))

GameState.OnUnload(function()
    if PersistentVars then
        PersistentVars.Scenario = S
    end
end)

Event.On("ModActive", function()
    if not PersistentVars.Active then
        Player.Notify(__("Endless Battle is now active."), true)
    end
    PersistentVars.Active = true
end)

Event.On("ModDeactive", function()
    if PersistentVars.Active then
        Player.Notify(__("Endless Battle is now inactive. Good bye!"), true)
    end

    PersistentVars.Active = false
    if PersistentVars.GUIOpen then
        Net.Send("CloseGUI")
    end
end)

Event.On("ScenarioLoot", function(_, loot)
    for _, item in ipairs(loot) do
        table.insert(PersistentVars.Stats.Looted, item)
    end
end)

Event.On("ScenarioEnemyKilled", function(_, enemy)
    table.insert(PersistentVars.Stats.Killed, enemy)
end)

do
    local count = 0
    local reset = Async.Debounce(5000, function()
        count = 0
    end)
    U.Osiris.On(
        "StatusApplied",
        4,
        "after",
        IfActive(function(object, status, causee, applyStoryActionID)
            if status == "NON_LETHAL" and U.UUID.Equals(Player.Host(), object) then
                --- deactivate automated rogue mode
            end
        end)
    )
    U.Osiris.On(
        "StatusRemoved",
        4,
        "after",
        IfActive(function(object, status, causee, applyStoryActionID)
            if status == "NON_LETHAL" and U.UUID.Equals(Player.Host(), object) then
                count = count + 1
                if count >= 3 then
                    Net.Send("OpenGUI")
                end
                reset()
            end
        end)
    )
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Commands                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

do
    local Commands = {}
    Api = Commands -- Mods.EndlessBattle.Api

    -- Net.On("Api", function(event)
    --     local fn = event.Payload.Command
    --     if fn == nil or Commands[fn] == nil then
    --         Net.Respond(event, { "Available Commands: ", UT.Keys(Commands) })
    --         return
    --     end
    --
    --     Net.Respond(event, Commands[fn](table.unpack(event.Payload.Args or {})))
    -- end)

    function Commands.UI()
        Event.Trigger("ModActive")
        if PersistentVars.GUIOpen then
            Net.Send("CloseGUI")
        else
            Net.Send("OpenGUI")
        end
    end

    function Commands.Activate()
        Event.Trigger("ModActive")
    end

    function Commands.Deactivate()
        Event.Trigger("ModDeactive")
    end

    function Commands.Roguelike()
        Event.Trigger("ModActive")
        PersistentVars.RogueModeActive = not PersistentVars.RogueModeActive
        L.Info(string.format("Roguelike mode is %s", PersistentVars.RogueModeActive and "active" or "inactive"))
        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
    end

    function Commands.Debug()
        local oed = Require("Hlib/OsirisEventDebug")

        if #oed.Listeners > 0 then
            oed.Detach()
        else
            oed.Attach()
        end
    end

    function Commands.Loca()
        Localization.BuildLocaFile()
    end

    local start = 0
    function Commands.Dev(new_start, amount)
        L.Info(":)")
        Mod.Dev = true
        Mod.Debug = true
        Config.Debug = true

        -- local e = {}
        -- for i, v in Enemy.Iter() do
        --     v:SyncTemplate()
        --     table.insert(e, v)
        -- end
        -- External.File.Export("Enemies", e)

        -- _D(Ext.Template.GetRootTemplate(Item.Armor("Legendary")[1].RootTemplate))
        -- for _, e in ipairs(UE.GetNearby(Player.Host(), 10, true, "DisplayName")) do
        --     -- L.Dump(Osi.ResolveTranslatedString(e.Entity.DisplayName.NameKey.Handle.Handle))
        --     L.Dump(Ext.Loca.GetTranslatedString(e.Entity.DisplayName.NameKey.Handle.Handle))
        -- end

        -- Osi.TeleportToWaypoint(Player.Host(), C.Waypoints.Act3b.GreyHarbor)

        -- local dump = Ext.DumpExport(_C().ServerCharacter.Template)
        -- local parts = US.Split(dump, "\n")
        -- for _, part in ipairs(parts) do
        --     Osi.AddEntryToCustomBook("EndlessBattle", part .. "\n")
        -- end
        -- Osi.OpenCustomBookUI(GetHostCharacter(), "EndlessBattle")

        -- Require("Hlib/OsirisEventDebug").Attach()
        -- GameMode.AskUnlockAll()
        -- Osi.Use(GetHostCharacter(), "S_CHA_WaypointShrine_Top_PreRecruitment_b3c94e77-15ab-404c-b215-0340e398dac0", "")
        --
        -- new_start = tonumber(new_start) or start
        -- amount = tonumber(amount) or 100

        -- local j = 0
        -- local templates = {}
        -- for i, v in Enemy.Iter() do
        --     table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
        --     -- if i > new_start and (i - new_start) <= amount then
        --     --     j = j + 1
        --     -- end
        -- end
        -- start = new_start + j
        --
        -- local enemies = Enemy.GenerateEnemyList(templates)
        --
        -- Enemy.TestEnemies(enemies)

        local enemies = Enemy.GenerateEnemyList(Ext.Template.GetAllRootTemplates())
        Enemy.TestEnemies(enemies, false)

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
        RetryUntil(function()
            L.Info("Pinging spawns.")
            local mapId = tonumber(mapId)
            if not mapId then
                S.Map:PingSpawns()
                return
            end

            Map.Get()[tonumber(mapId)]:PingSpawns()
        end, { retries = tonumber(repeats) or 3 })
    end

    function Commands.Maps(id)
        local region = Player.Region()
        L.Info("Region: " .. region)

        local maps = Map.GetTemplates(region)
        if maps == nil then
            L.Error("No maps found.")
            return
        end

        L.Info("ID", "Name", "!EB Maps [id]")

        for i, v in pairs(maps) do
            if id and i == tonumber(id) then
                L.Info(i, v.Name, Ext.DumpExport(v))
            else
                L.Info(i, v.Name)
            end
        end
    end

    function Commands.Scenarios(id)
        L.Info("ID", "Name", "!EB Scenarios [id]")
        for i, v in pairs(Scenario.GetTemplates()) do
            if id and i == tonumber(id) then
                L.Info(i, v.Name, Ext.DumpExport(v))
            else
                L.Info(i, v.Name)
            end
        end
    end

    function Commands.Start(scenarioId, mapId)
        L.Info("!EB Scenarios", "List scenarios")
        L.Info("!EB Maps", "List maps")
        L.Info("!EB Start [scenarioId] [mapId]")
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

    Ext.RegisterConsoleCommand("EB", function(_, fn, ...)
        if fn == nil or Commands[fn] == nil then
            L.Dump("Available Commands", UT.Keys(Commands))
            return
        end

        Commands[fn](...)
    end)
end
