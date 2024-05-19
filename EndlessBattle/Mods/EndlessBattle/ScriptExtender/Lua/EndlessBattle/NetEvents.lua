Net.On("GetSelection", function(event)
    Net.Respond(event, {
        Scenarios = UT.Map(Scenario.GetTemplates(), function(v, k)
            return { Id = k, Name = v.Name, Roguelike = v.Timeline == C.RoguelikeScenario }
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
        Enemies = Enemy.GetTemplates(),
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
    if map == nil then
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
        Scenario.Teleport(Player.Host(event:UserId()))
    else
        Map.TeleportTo(map, Player.Host(event:UserId()), false)
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

Net.On("GetState", function(event)
    Mod.Vars.State.Active = true

    Net.Respond(event, PersistentVars)
end)

Net.On("Config", function(event)
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
    end

    Net.Respond(event, Config)
end)

Net.On("KillNearby", function(event)
    local nearby = UE.GetNearby(Player.Host(event:UserId()), 50, true)

    for _, v in ipairs(nearby) do
        if v.Entity.IsCharacter and UE.IsNonPlayer(v.Guid) then
            UE.Remove(v.Guid)
        end
    end
end)
