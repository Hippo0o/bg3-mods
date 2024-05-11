-- Purpose: lazily call Osi functions from the client
Net.On("RCE", function(event)
    local code = event.Payload

    local res = UT.Pack(pcall(Ext.Utils.LoadString(code)))

    Net.Respond(event, res)
end)

Net.On("Selection", function(event)
    Net.Respond(event, {
        Scenarios = UT.Map(Scenario.GetTemplates(), function(v, k)
            return { Id = k, Name = v.Name }
        end),
        Maps = UT.Map(Map.GetTemplates(), function(v, k)
            return { Id = k, Name = v.Name }
        end),
    })
end)

Net.On("Templates", function(event)
    Net.Respond(event, {
        Scenarios = Scenario.GetTemplates(),
        Maps = Map.GetTemplates(),
        Enemies = Enemy.GetTemplates(),
    })
end)

Net.On("Items", function(event)
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

Net.On("State", function(event)
    Net.Respond(event, PersistentVars)
end)
