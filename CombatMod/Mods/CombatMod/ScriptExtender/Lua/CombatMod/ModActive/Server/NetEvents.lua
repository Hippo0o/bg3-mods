function SyncState(peerId)
    Net.Send(
        "SyncState",
        table.filter(PersistentVars, function(v, k)
            if k == "SpawnedEnemies" and table.size(v) > 30 then
                return false
            end
            return true
        end, true),
        nil,
        peerId
    )
end

Net.On("SyncState", function(event)
    SyncState(event.PeerId)
end)

Net.On("IsHost", function(event)
    Net.Respond(event, event:IsHost())
end)

Net.On("GUIReady", function(event)
    if PersistentVars.GUIOpen then
        Net.Send("OpenGUI")
    end
end)

Net.On("GetSelection", function(event)
    Net.Respond(event, {
        Scenarios = table.map(Scenario.GetTemplates(), function(v, k)
            if PersistentVars.RogueModeActive and not v.RogueLike then
                return nil
            end
            return { Id = k, Name = v.Name }
        end),
        Maps = table.map(Map.GetTemplates(), function(v, k)
            return { Id = k, Name = v.Name }
        end),
    })
end)

Net.On("GetTemplates", function(event)
    Net.Respond(event, {
        Scenarios = Scenario.GetTemplates(),
        Maps = Map.GetTemplates(),
        -- Enemies = Enemy.GetTemplates(),
    })
end)

Net.On("ResetTemplates", function(event)
    if event.Payload.Scenarios then
        Templates.ExportScenarios()
    end
    if event.Payload.Maps then
        Templates.ExportMaps()
    end
    if event.Payload.Enemies then
        Templates.ExportEnemies()
    end
    if event.Payload.LootRates then
        Templates.ExportLootRates()
    end

    Net.Respond(event, { true })
end)

Net.On("GetEnemies", function(event)
    local tier = event.Payload and event.Payload.Tier

    local grouped = {}
    for _, v in ipairs(Enemy.GetTemplates()) do
        if not tier or v.Tier == tier then
            if not grouped[v.Tier] then
                grouped[v.Tier] = {}
            end
            table.insert(grouped[v.Tier], v)
        end
    end

    Net.Respond(event, grouped)
end)

Net.On("GetItems", function(event)
    local rarity = event.Payload and event.Payload.Rarity
    Net.Respond(event, {
        Objects = Item.Objects(rarity, false),
        CombatObjects = Item.Objects(rarity, true),
        Armor = Item.Armor(rarity),
        Weapons = Item.Weapons(rarity),
    })
end)

Net.On("Start", function(event)
    local scenarioName = event.Payload.Scenario
    local mapName = event.Payload.Map

    local template = table.find(Scenario.GetTemplates(), function(v)
        return v.Name == scenarioName
    end)

    local map = table.find(Map.Get(), function(v)
        return v.Name == mapName
    end)

    if template == nil then
        Net.Respond(event, { false, "Scenario error" })
        return
    end
    if mapName and map == nil then
        Net.Respond(event, { false, "Map error" })
        return
    end
    Scenario.Start(template, map)

    Net.Respond(event, { true, __("Scenario %s started.", template.Name) })
end)

Net.On("Stop", function(event)
    local s = Scenario.Current()

    if not s then
        Net.Respond(event, { false, __("Scenario not started.") })
        return
    end

    if s:HasStarted() and not Mod.Debug then
        Net.Respond(event, { false, __("Cannot stop while in progress.") })
        return
    end

    Scenario.Stop()
    Net.Respond(event, { true, __("Scenario stopped.") })
end)

Net.On("ToCamp", function(event)
    if Player.Region() == C.Regions.Act0 then
        Intro.AskTutSkip()
        Net.Send("CloseGUI")
        return
    end

    if Player.InCombat() and not Mod.Debug then
        Net.Respond(event, { false, __("Cannot teleport while in combat.") })
        return
    end
    Player.ReturnToCamp()

    Net.Respond(event, { true })
end)

Net.On("ForwardCombat", function(event)
    local s = Scenario.Current()

    if not s then
        Net.Respond(event, { false, __("Scenario not started.") })
        return
    end

    Scenario.ForwardCombat()

    Net.Respond(event, { true })
end)

Net.On("Teleport", function(event)
    if Player.Region() == C.Regions.Act0 then
        Intro.AskTutSkip()
        Net.Send("CloseGUI")
        return
    end

    local mapName = event.Payload.Map

    local map = table.find(Map.Get(), function(v)
        return v.Name == mapName
    end)

    if map == nil then
        Net.Respond(event, { false, __("Map not found.") })
        return
    end

    if event.Payload.Restrict and Player.InCombat() and not Mod.Debug then
        Net.Respond(event, { false, __("Cannot teleport while in combat.") })
        return
    end

    local s = Scenario.Current()

    if s and U.Equals(map, s.Map) then
        Scenario.Teleport(event:Character())
    else
        map:Teleport(event:Character())
    end

    Net.Respond(event, { true })
end)

Net.On("WindowOpened", function(event)
    PersistentVars.GUIOpen = true
    Event.Trigger("ModActive")
    SyncState(event.PeerId)
end)
Net.On("WindowClosed", function(event)
    PersistentVars.GUIOpen = false
end)

Event.On("ScenarioStarted", function()
    Net.Send("OpenGUI", "Optional")
end)
Event.On("ScenarioMapEntered", function()
    Net.Send("CloseGUI", "Optional")
end)

Net.On("KillSpawned", function(event)
    Enemy.KillSpawned()

    Net.Respond(event, { true })
end)

Net.On("Ping", function(event)
    local target = event.Payload.Target
    if target then
        local character = event:Character()
        local x, y, z = Osi.GetPosition(target)
        Osi.RequestPing(x, y, z, target, character)
    end

    local pos = event.Payload.Pos
    if pos then
        Osi.RequestPing(pos[1], pos[2], pos[3], nil, event:Character())
    end

    Net.Respond(event, { true })
end)

Net.On("MarkSpawns", function(event)
    local mapName = event.Payload.Map
    local map = table.find(Map.Get(), function(v)
        return v.Name == mapName
    end)
    if map == nil then
        Net.Respond(event, { false, __("Map not found.") })
        return
    end

    map:VFXSpawns(table.keys(map.Spawns), 16)

    if Scenario.Current() then
        Scenario.MarkSpawns(Scenario.Current().Round + 1, 16)
    end

    Net.Respond(event, { true })
end)

Net.On("PingSpawns", function(event)
    local mapName = event.Payload.Map
    local map = table.find(Map.Get(), function(v)
        return v.Name == mapName
    end)
    if map == nil then
        Net.Respond(event, { false, __("Map not found.") })
        return
    end

    map:PingSpawns()

    Net.Respond(event, { true })
end)

local function broadcastState()
    Schedule(SyncState)
end

local function broadcastConfig()
    Schedule(function()
        local c = table.deepclone(Config)
        c.RoguelikeMode = PersistentVars.RogueModeActive
        c.HardMode = PersistentVars.HardMode
        c.Debug = Mod.Debug

        Net.Send("Config", c)
    end)
end

Event.On("RogueModeChanged", broadcastConfig)

Event.On("RogueModeChanged", broadcastState)
Event.On("ScenarioStarted", broadcastState)
Event.On("ScenarioMapEntered", broadcastState)
Event.On("ScenarioRoundStarted", broadcastState)
Event.On("ScenarioEnemyKilled", broadcastState)
Event.On("ScenarioCombatStarted", broadcastState)
Event.On("ScenarioEnded", broadcastState)
Event.On("ScenarioStopped", broadcastState)
Event.On("RogueScoreChanged", broadcastState)

Net.On("Config", function(event)
    if event:IsHost() then
        local config = event.Payload
        if config then
            if config.Default then
                config = DefaultConfig
            end

            External.ApplyConfig(config)

            if config.Persist then
                External.SaveConfig()
            end

            if config.Reset then
                External.LoadConfig()
            end

            if config.RoguelikeMode ~= nil then
                if PersistentVars.RogueModeActive ~= config.RoguelikeMode then
                    PersistentVars.RogueModeActive = config.RoguelikeMode
                    Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
                end
            end

            if config.HardMode ~= nil then
                PersistentVars.HardMode = config.HardMode
                broadcastState()
            end
        end
    end

    broadcastConfig()
end)

Net.On("KillNearby", function(event)
    StoryBypass.ClearArea(event:Character())
end)

Net.On("ClearSurfaces", function(event)
    local s = Scenario.Current()
    if s then
        for i, guid in pairs(s.Map.Helpers) do
            WaitTicks(i, function()
                StoryBypass.ClearSurfaces(guid)
            end)
        end
    else
        StoryBypass.ClearSurfaces(event:Character())
    end

    Net.Respond(event, { true })
end)

Net.On("RemoveAllEntities", function(event)
    local count = #StoryBypass.RemoveAllEntities()
    Net.Respond(event, { true, string.format("Removing %d entities.", count) })
end)

Net.On("RecruitOrigin", function(event)
    local name = event.Payload
    local char = table.find(C.OriginCharacters, function(v, k)
        return k == name
    end)
    if char then
        Player.RecruitOrigin(name)
        Net.Respond(event, { true, __("Recruiting %s.", name) })
    else
        Net.Respond(event, { false, string.format("Origin %s not found.", name) })
    end
end)

Net.On("CancelLongRest", function(event)
    StoryBypass.EndLongRest()
    Net.Respond(event, { true })
end)

Net.On("CancelDialog", function(event)
    local dialog, instance = Osi.SpeakerGetDialog(event:Character(), 1)

    if dialog then
        StoryBypass.CancelDialog(dialog, instance)
        Net.Respond(event, { true, string.format("Dialog %s cancelled.", dialog) })
    else
        Net.Respond(event, { false, "No dialog found." })
    end
end)

Net.On("UpdateLootFilter", function(event)
    local rarity, type, bool = table.unpack(event.Payload)
    PersistentVars.LootFilter[type][rarity] = bool

    broadcastState()
    Net.Respond(event, { true, __("Loot filter updated") })
end)

Net.On("PickupAll", function(event)
    local count = 0
    for _, rarity in pairs(C.ItemRarity) do
        count = count + Item.PickupAll(event:Character())
    end

    Net.Respond(event, { true, __("Picked up %d items.", count) })
end)

Net.On("Pickup", function(event)
    local rarity, type = table.unpack(event.Payload)
    local count = Item.PickupAll(event:Character(), rarity, type)

    Net.Respond(event, { true, __("Picked up %d items.", count) })
end)

Net.On("DestroyAll", function(event)
    local count = 0
    for _, rarity in pairs(C.ItemRarity) do
        count = count + Item.DestroyAll(rarity)
    end

    Net.Respond(event, { true, __("Destroyed %d items.", count) })
end)

Net.On("DestroyLoot", function(event)
    local rarity, type = table.unpack(event.Payload)
    local count = Item.DestroyAll(rarity, type)

    Net.Respond(event, { true, __("Destroyed %d items.", count) })
end)

Net.On("GetFilterableModList", function(event)
    local list = {}

    local function t(modId, modName)
        return { Id = modId, Name = modName, Blacklist = false }
    end
    for modId, modName in pairs(Item.GetModList()) do
        if not string.contains(modName, { "Gustav", "GustavDev", "Shared", "SharedDev", "Honour" }) then
            list[modId] = t(modId, modName)
        end
    end

    local filters = External.Templates.GetItemFilters()
    for _, modId in pairs(filters.Mods) do
        if not list[modId] then
            local name = "Not loaded"
            if Ext.Mod.GetMod(modId) then
                name = Ext.Mod.GetMod(modId).Info.Directory
            end

            list[modId] = t(modId, name)
        end

        list[modId].Blacklist = true
    end

    Net.Respond(event, list)
end)

Net.On("UpdateModFilter", function(event)
    local modId, bool = table.unpack(event.Payload)
    local filters = External.Templates.GetItemFilters(true)

    if bool then
        table.insert(filters.Mods, modId)
    else
        table.removevalue(filters.Mods, modId)
    end

    External.File.Export("ItemFilters", filters)

    Item.ClearCache()

    Net.Respond(event, { true, "Mod filter updated" })
end)
