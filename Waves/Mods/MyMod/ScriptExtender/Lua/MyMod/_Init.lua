---@diagnostic disable: undefined-global

---@type Mod
local Mod = Require("Shared/Mod")
Mod.ModPrefix = "MyMod"
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
    CombatWorkaround = false, -- restart combat every round to reroll initiative and let newly spawned enemies act immediately
    ForceEnterCombat = false, -- more continues battle between rounds at the cost of cheesy out of combat strats
    BypassStory = false, -- skip dialogues, combat and interactions that aren't related to a scenario
    ItemsIncludeClothes = false, -- include clothes in item lists
    ItemRarity = {
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
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
    Config = {},
}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Modules                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- lazy ass globals

---@type Async
Async = Require("Shared/Async")
WaitFor = Async.WaitFor
RetryFor = Async.RetryFor
Schedule = Async.Schedule
Defer = Async.Defer

---@type Libs
Libs = Require("Shared/Libs")

Player = {}
Scenario = {}
Enemy = {}
Map = {}
Item = {}

Require("MyMod/Player")
Require("MyMod/Scenario")
Require("MyMod/Enemy")
Require("MyMod/Map")
Require("MyMod/Item")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@type GameState
local GameState = Require("Shared/GameState")
GameState.RegisterSavingAction(function()
    PersistentVars.Scenario = S
    PersistentVars.Config.BypassStory = C.BypassStory
    PersistentVars.Config.CombatWorkaround = C.CombatWorkaround
    PersistentVars.Config.ForceEnterCombat = C.ForceEnterCombat

    for obj, _ in pairs(PersistentVars.SpawnedEnemies) do
        if not Ext.Entity.Get(obj):IsAlive() then
            L.Debug("Cleaning up SpawnedEnemies", obj)
            PersistentVars.SpawnedEnemies[obj] = nil
        end
    end

    for obj, _ in pairs(PersistentVars.SpawnedItems) do
        if
            Item.IsOwned(obj) == 1 or Osi.IsItem(obj) == 0 -- was used
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

    S = PersistentVars.Scenario
    if S ~= nil then
        Scenario.RestoreFromState(S)
    end

    if PersistentVars.Config then
        C.BypassStory = PersistentVars.Config.BypassStory or false
        C.CombatWorkaround = PersistentVars.Config.CombatWorkaround or false
        C.ForceEnterCombat = PersistentVars.Config.ForceEnterCombat or false
    end
end)

GameState.RegisterUnloadingAction(function()
    S = nil
end)

do -- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
    local function ifBypassStory(func)
        return function(...)
            if C.BypassStory then
                func(...)
            end
        end
    end
    Ext.Osiris.RegisterListener(
        "DialogActorJoined",
        4,
        "after",
        ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
            local paidActor = US.Contains(actor, "_Daisy_")

            if Enemy.IsValid(actor) or UE.IsPlayable(actor) then
                return
            end

            if
                -- prevent wither softlock
                dialog:match("^CHA_Crypt_SkeletonRisingCinematic")
                or actor:match("^CHA_Crypt_SkeletonRisingCinematic")
                or dialog:match("Jergal")
                or actor:match("Jergal")
            then
                return
            end

            if paidActor then
                L.Info("To disable story bypass, use !MM DisableStoryBypass")
            end

            Osi.DialogRequestStopForDialog(dialog, actor)

            if not paidActor and UE.IsNonPlayer(actor, true) then
                L.Debug("DialogActorJoined", dialog, actor, instanceID, speakerIndex)
                Osi.DialogRemoveActorFromDialog(instanceID, actor)
                L.Info("Removing", actor)
                UE.Remove(actor)
                Player.Notify(
                    "Skipped interaction with "
                        .. Osi.ResolveTranslatedString(Ext.Entity.Get(actor).DisplayName.NameKey.Handle.Handle),
                    true
                )
            end
        end)
    )
    Ext.Osiris.RegisterListener(
        "UseFinished",
        3,
        "before",
        ifBypassStory(function(character, item, sucess)
            if UE.IsNonPlayer(character) then
                return
            end
            if Osi.IsLocked(item) == 1 then
                L.Debug("Auto unlocking", item)
                L.Info("To disable story bypass, use !MM DisableStoryBypass")
                Player.Notify("Auto unlocking", true)
                Osi.Unlock(item, character)
            end
            if Osi.IsTrapArmed(item) == 1 then
                L.Debug("Auto disarming", item)
                L.Info("To disable story bypass, use !MM DisableStoryBypass")
                Player.Notify("Auto disarming", true)
                Osi.SetTrapArmed(item, 0)
            end
        end)
    )
    Ext.Osiris.RegisterListener(
        "EnteredCombat",
        2,
        "after",
        ifBypassStory(function(object, combatGuid)
            Schedule(function()
                if not Enemy.IsValid(object) and UE.IsNonPlayer(object, true) then
                    L.Info("Removing", object)
                    Osi.LeaveCombat(object)
                    UE.Remove(object)
                    Player.Notify(
                        "Skipped combat with "
                            .. Osi.ResolveTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle),
                        true
                    )
                end
            end)
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
    Api = Commands -- Mods.MyMod.Api

    local start = 0
    function Commands.Debug(new_start, amount)
        -- local enemies = Enemy.GenerateEnemyList(Ext.Template.GetAllRootTemplates())
        -- Enemy.TestEnemies(enemies, false)

        -- new_start = tonumber(new_start) or start
        -- amount = tonumber(amount) or 100
        --
        -- local j = 1
        -- local templates = {}
        -- for i, v in Enemy.Iter() do
        --     if i >= new_start and (i - new_start) <= amount then
        --         table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
        --         j = j + 1
        --     end
        -- end
        --
        -- start = new_start + j

        local templates = {}
        for i, v in Enemy.Iter() do
            table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
        end
        local enemies = Enemy.GenerateEnemyList(templates)

        Enemy.TestEnemies(enemies)

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

    function Commands.Map(id)
        local region = Osi.GetRegion(Player.Host())
        L.Info("Region", region)

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

    function Commands.Kill()
        Enemy.KillSpawned()
    end

    function Commands.Clear()
        Enemy.Cleanup()
    end

    function Commands.Spawns(mapId)
        RetryFor(function()
            L.Info("Pinging spawns.")
            local mapId = tonumber(mapId)
            if not mapId then
                S.Map:PingSpawns()
                return
            end

            Map.GetByIndex(tonumber(mapId)):PingSpawns()
        end)
    end

    function Commands.Maps(id)
        local region = Osi.GetRegion(Player.Host())
        L.Info("Region: " .. region)

        local maps = Map.Get(region)
        if maps == nil then
            L.Error("No maps found.")
            return
        end

        L.Info("ID", "Name")

        for i, v in pairs(maps) do
            L.Info(i, v.Name)
            if id and i == tonumber(id) then
                L.Dump(v)
            end
        end
    end

    function Commands.Scenarios(id)
        L.Info("ID", "Name")
        for i, v in pairs(Scenario.Get()) do
            L.Info(i, v.Name)
            if id and i == tonumber(id) then
                L.Dump(v)
            end
        end
    end

    function Commands.Start(scenarioId, mapId)
        if not scenarioId then
            scenarioId = 1
        end
        if not mapId then
            mapId = 1
        end

        local map = Map.Get(Osi.GetRegion(Player.Host()))[tonumber(mapId)]
        local template = Scenario.Get()[tonumber(scenarioId)]
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

    function Commands.State()
        L.Dump(S)
    end

    function Commands.DumpPV()
        L.Dump(PersistentVars)
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
        L.Debug("Region", Osi.GetRegion(Player.Host()))
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

    function Commands.CombatWorkaround(flag)
        C.CombatWorkaround = ("true" == flag or tonumber(flag) == 1) and true or false
        L.Info("Combat workaround is", C.CombatWorkaround and "enabled" or "disabled")
    end

    function Commands.StoryBypass(flag)
        C.BypassStory = ("true" == flag or tonumber(flag) == 1) and true or false
        L.Info("Story bypass is", C.BypassStory and "enabled" or "disabled")
    end
    function Commands.EnableStoryBypass()
        Commands.StoryBypass(1)
    end
    function Commands.DisableStoryBypass()
        Commands.StoryBypass(0)
    end

    Ext.RegisterConsoleCommand("MM", function(_, fn, ...)
        if fn == nil or Commands[fn] == nil then
            L.Dump(UT.Keys(Commands))
            return
        end

        Commands[fn](...)
    end)
end
