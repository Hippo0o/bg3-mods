function SyncState()
    PersistentVars.OldItems = Item.OldItems()
    Net.Send(
        "SyncState",
        UT.Filter(PersistentVars, function(v, k)
            if k == "SpawnedEnemies" and UT.Size(v) > 30 then
                return false
            end
            return true
        end, true)
    )
end
Net.On("SyncState", SyncState)

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
        Net.Respond(event, { false, __("Scenario not found.") })
        return
    end
    if mapName and map == nil then
        Net.Respond(event, { false, __("Map not found.") })
        return
    end

    Scenario.Start(template, map)
    Net.Respond(event, { true, __("Scenario %s started.", template.Name) })
end)

Net.On("Stop", function(event)
    Scenario.Stop()
    Net.Respond(event, { true, __("Scenario stopped.") })
end)

Net.On("ToCamp", function(event)
    if Player.InCombat() and not Mod.Debug then
        Net.Respond(event, { false, __("Cannot teleport while in combat.") })
        return
    end
    Player.ReturnToCamp()

    Net.Respond(event, { true })
end)

Net.On("ResumeCombat", function(event)
    if Player.InCombat() and not Mod.Debug then
        Net.Respond(event, { false, __("Cannot force next round while in combat.") })
        return
    end
    if not S or S.Round < 1 then
        Net.Respond(event, { false, __("Scenario not started.") })
        return
    end
    Scenario.ResumeCombat()

    Net.Respond(event, { true })
end)

Net.On("Teleport", function(event)
    local mapName = event.Payload.Map

    local map = UT.Find(Map.Get(), function(v)
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

Net.On("PingSpawns", function(event)
    local mapName = event.Payload.Map
    local map = UT.Find(Map.Get(), function(v)
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
        local c = UT.DeepClone(Config)
        c.RoguelikeMode = PersistentVars.RogueModeActive
        c.HardMode = PersistentVars.HardMode
        c.Debug = Mod.Debug

        Net.Send("Config", c)
    end)
end

Event.On("RogueModeChanged", broadcastConfig)

Event.On("ScenarioStarted", broadcastState)
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

Net.On("RemoveAllEntities", function(event)
    local count = #StoryBypass.RemoveAllEntities()
    Net.Respond(event, { true, string.format("Removing %d entities.", count) })
end)

Net.On("RecruitOrigin", function(event)
    local name = event.Payload
    local char = UT.Find(C.OriginCharacters, function(v, k)
        return k == name
    end)
    if char then
        GameMode.RecruitOrigin(name)
        Net.Respond(event, { true, string.format("Recruiting %s.", name) })
    else
        Net.Respond(event, { false, string.format("Origin %s not found.", name) })
    end
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

---@deprecated
Net.On("UpdateLootFilter", function(event)
    local rarity, type, bool = table.unpack(event.Payload)
    PersistentVars.LootFilter[type][rarity] = bool

    broadcastState()
end)

Net.On("PickupAll", function(event)
    Player.PickupAll(event:Character())
end)

---@deprecated
Net.On("Pickup", function(event)
    local rarity, type = table.unpack(event.Payload)
    Item.PickupAll(event:Character(), rarity, type)
end)

---@deprecated
Net.On("DestroyLoot", function(event)
    local rarity, type = table.unpack(event.Payload)
    Item.DestroyAll(rarity, type)
end)
