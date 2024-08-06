Net.On("IsHost", function(event)
    Net.Respond(event, event:IsHost())
end)

Net.On("GetSelection", function(event)
    Net.Respond(event, {
        Scenarios = UT.Map(Scenario.GetTemplates(), function(v, k)
            return { Id = k, Name = v.Name }
        end),
        Maps = UT.Map(Map.GetTemplates(), function(v, k)
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
        Scenario.ExportTemplates()
    end
    if event.Payload.Maps then
        Map.ExportTemplates()
    end
    if event.Payload.Enemies then
        Enemy.ExportTemplates()
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

Net.On("GetUnlocks", function(event)
    Net.Respond(event, Unlock.Get())
end)

Net.On("Start", function(event)
    local scenarioName = event.Payload.Scenario
    local mapName = event.Payload.Map

    local template = UT.Find(Scenario.GetTemplates(), function(v)
        return v.Name == scenarioName
    end)

    local map = UT.Find(Map.Get(), function(v)
        return v.Name == mapName
    end)

    if template == nil then
        Net.Respond(event, { false, "Scenario not found." })
        return
    end
    if mapName and map == nil then
        Net.Respond(event, { false, "Map not found." })
        return
    end

    Scenario.Start(template, map)
    Net.Respond(event, { true })
end)

Net.On("Stop", function(event)
    Scenario.Stop()
    Net.Respond(event, { true })
end)

Net.On("Teleport", function(event)
    local mapName = event.Payload.Map

    local map = UT.Find(Map.Get(), function(v)
        return v.Name == mapName
    end)

    if map == nil then
        Net.Respond(event, { false, "Map not found." })
        return
    end

    if S and U.Equals(map, S.Map) then
        Scenario.Teleport(event:Character())
    else
        Map.TeleportTo(map, event:Character(), false)
    end

    Net.Respond(event, { true })
end)

Net.On("WindowOpened", function(event)
    PersistentVars.GUIOpen = true
    Event.Trigger("ModActive")
end)
Net.On("WindowClosed", function(event)
    PersistentVars.GUIOpen = false
end)

Net.On("KillSpawned", function(event)
    Enemy.KillSpawned()

    Net.Respond(event, { true })
end)

Net.On("PingSpawns", function(event)
    local mapName = event.Payload.Map
    local map = UT.Find(Map.Get(), function(v)
        return v.Name == mapName
    end)
    if map == nil then
        Net.Respond(event, { false, "Map not found." })
        return
    end

    map:PingSpawns()
    Net.Respond(event, { true })
end)

Net.On("SyncState", function(event)
    Net.Respond(event, PersistentVars)
end)

Event.On("ScenarioStarted", function()
    Schedule(function()
        Net.Send("SyncState", PersistentVars)
    end)
end)

Event.On("ScenarioCombatStarted", function()
    Schedule(function()
        Net.Send("SyncState", PersistentVars)
    end)
end)

Event.On("ScenarioEnded", function()
    Schedule(function()
        Net.Send("SyncState", PersistentVars)
    end)
end)

Event.On("RogueScoreChanged", function()
    Net.Send("SyncState", PersistentVars)
end)

Event.On("ScenarioStopped", function()
    Schedule(function()
        Net.Send("SyncState", PersistentVars)
    end)
end)

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
        end
    end

    local c = UT.DeepClone(Config)
    c.RoguelikeMode = PersistentVars.RogueModeActive
    c.Debug = Mod.Debug

    Net.Respond(event, c)
end)

Net.On("KillNearby", function(event)
    StoryBypass.ClearArea(event:Character())
end)
