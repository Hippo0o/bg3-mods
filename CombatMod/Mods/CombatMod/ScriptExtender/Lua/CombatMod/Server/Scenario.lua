local scenarioTemplates = Require("CombatMod/Templates/Scenarios.lua")
External.File.ExportIfNeeded("Scenarios", scenarioTemplates)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Scenario: LibsClass
---@field Name string
---@field Enemies table<number, Enemy[]>
---@field KilledEnemies Enemy[]
---@field SpawnedEnemies Enemy[]
---@field Map Map
---@field CombatId string
---@field Round integer
---@field Timeline table<string, number> Round, Amount of enemies
---@field Positions table<number, number> Index, Spawn
---@field LootRates table<string, table<string, number>>
---@field OnMap boolean
---@field RogueMode boolean
---@field New fun(self): self
local Object = Libs.Class({
    Name = nil,
    Enemies = {},
    KilledEnemies = {},
    SpawnedEnemies = {},
    Map = nil,
    CombatId = nil,
    OnMap = false,
    RogueMode = false,
    Round = 0,
    Timeline = {},
    Positions = {},
    LootRates = {},
})

---@param round number
---@param enemy Enemy
function Object:AddEnemy(round, enemy)
    self.Enemies[round] = self.Enemies[round] or {}
    table.insert(self.Enemies[round], enemy)
end

---@return Enemy[]
function Object:SpawnsForRound()
    return self.Enemies[self.Round] or {}
end

function Object:GetPosition(enemyIndex)
    local posIndex = 0
    for round, enemies in pairs(self.Enemies) do
        if round < self.Round then
            posIndex = posIndex + #enemies
        end
    end

    return self.Positions[posIndex + enemyIndex] or -1
end

function Object:TotalRounds()
    return #self.Timeline
end

function Object:HasMoreRounds()
    return self.Round < self:TotalRounds()
end

function Object:HasStarted()
    return #self.SpawnedEnemies > 0 or self.Round > 0
end

function Object:IsRunning()
    return #self.SpawnedEnemies > 0 or self:HasMoreRounds()
end

---@return Scenario
local function Current()
    assert(S ~= nil, "Scenario not started.")

    return S
end

local function ifScenario(func)
    return IfActive(function(...)
        if S == nil then
            return
        end
        func(...)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Actions                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------
-- functions that only get called as part of events

local Action = {}

function Action.CalculateLoot()
    local scenario = Current()

    local lootMultiplier = 1
    if PersistentVars.Unlocked.LootMultiplier then
        lootMultiplier = 1.5
    end

    local rolls = 0

    for _, e in pairs(scenario.KilledEnemies) do
        -- each kill gets an object/weapon/armor roll

        for k, v in ipairs(C.EnemyTier) do
            if e.Tier == v then
                -- k is higher for higher tier
                rolls = rolls + math.ceil(k * lootMultiplier)
                break
            end
        end
    end

    local loot = Item.GenerateLoot(rolls, scenario.LootRates)
    L.Dump("Loot", loot, rolls, scenario.LootRates)
    return loot
end

function Action.SpawnLoot()
    Player.Notify(__("Dropping loot."))

    local map = Current().Map
    local loot = Action.CalculateLoot()
    Event.Trigger("ScenarioLoot", Current(), loot)

    map:SpawnLoot(loot)
end

function Action.StartCombat()
    if Current().CombatId ~= nil then
        L.Error("Combat already started.")
        return
    end

    -- remove corpses from previous combat
    Enemy.Cleanup()

    Schedule(function()
        for _, p in pairs(UE.GetParty()) do
            Osi.ForceTurnBasedMode(p.Uuid.EntityUuid, 0)
        end
    end)

    Current().Map:PingSpawns()

    Event.Trigger("ScenarioCombatStarted", Current())

    Player.Notify(__("Combat is Starting."), true)
    -- Osi.ForceTurnBasedMode(Player.Host(), 1)
    Action.StartRound()
end

function Action.SpawnRound()
    local s = Current()
    local toSpawn = s:SpawnsForRound()

    if #toSpawn == 0 then
        L.Debug("No enemies to spawn.", s.Round)
        return
    end

    for i, e in pairs(toSpawn) do
        -- spawning multiple enemies at once will cause bugs when templates get overwritten
        RetryUntil(function()
            local posIndex = s:GetPosition(i)
            L.Debug("Spawning enemy.", e:GetId(), posIndex)
            return s.Map:SpawnIn(e, posIndex)
        end, {
            immediate = true,
            retries = #s.Map.Spawns,
            interval = 500,
        }).After(function()
            Player.Notify(__("Enemy %s spawned.", e:GetTranslatedName()), true, e:GetId())
            Event.Trigger("ScenarioEnemySpawned", Current(), e)

            Action.EnemyAdded(e)
        end).Catch(function()
            L.Error("Spawn limit exceeded.", e:GetId())
            UT.Remove(s.SpawnedEnemies, e)
            Action.EnemyRemoved()
        end)
        table.insert(s.SpawnedEnemies, e)
    end

    L.Debug("Enemies queued for spawning.", #toSpawn)
end

function Action.StartRound()
    Current().Round = Current().Round + 1
    Player.Notify(__("Round %d", Current().Round))

    Event.Trigger("ScenarioRoundStarted", Current())

    Action.SpawnRound()
end

function Action.NotifyStarted()
    local id = tostring(S)

    return RetryUntil(function(self)
        if tostring(S) ~= id then
            self:Clear()
            return
        end
        if S.OnMap then
            return true
        end

        Player.Notify(__("Leave camp to join the battle."))

        return false
    end, {
        retries = 10,
        interval = 15000,
        immediate = true,
    })
end

-- map entered from camp or teleport
function Action.MapEntered()
    if Current():HasStarted() then
        return
    end

    Event.Trigger("ScenarioMapEntered", Current())

    local x, y, z = Player.Pos()

    local id = tostring(S)
    RetryUntil(function(self, tries)
        if tostring(S) ~= id then -- scenario stopped
            self:Clear()
            return
        end
        if tries % 10 == 0 then
            Player.Notify(__("Move to start scenario."), true)
        end
        local x2, y2, z2 = Player.Pos()
        return x ~= x2 or z ~= z2
    end, {
        retries = 120,
        interval = 1000,
    }).After(ifScenario(function()
        Action.StartCombat()
    end)).Catch(function(_, err)
        L.Error(err)
        Scenario.Stop()
        Player.Notify(__("Scenario canceled due to timeout."))
    end)
end

function Action.EnemyAdded(enemy)
    if Config.ForceEnterCombat or Player.InCombat() then
        Scenario.CombatSpawned(enemy)
    end
end

-- Enemy died or couldnt spawn
function Action.EnemyRemoved()
    local s = Current()

    Action.CheckEnded()

    if #s.SpawnedEnemies == 0 and s:HasMoreRounds() then
        Scenario.ResumeCombat()
    end
end

-- Enemy spawned but is out of bounds
-- Player needs to be in combat for this to work
function Action.Failsafe(enemy)
    if not Player.InCombat() then
        return
    end

    local s = Current()

    local list = enemy and { enemy } or s.SpawnedEnemies
    if #list > 0 then
        L.Dump("Running failsafe.", list)

        for _, e in pairs(list) do
            if not e:IsSpawned() then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                UT.Remove(s.SpawnedEnemies, e)
            elseif Osi.IsDead(e.GUID) ~= 1 and Osi.IsInCombat(e.GUID) ~= 1 then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                Osi.SetVisible(e.GUID, 1) -- sneaky shits never engage combat

                local x, y, z = s.Map:GetSpawn(-1)
                Osi.TeleportToPosition(e.GUID, x, y, z, "", 1, 1, 1)

                e:Combat(true)

                Defer(2000).After(function()
                    if Osi.IsInCombat(e.GUID) == 1 then
                        return
                    end

                    L.Error("Failsafe 2 triggered.", e:GetId(), e.GUID)

                    e:Combat(true)

                    return Defer(3000)
                end).After(function()
                    if Osi.IsInCombat(e.GUID) ~= 1 then
                        L.Error("Failsafe 3 triggered.", e:GetId(), e.GUID)

                        UT.Remove(s.SpawnedEnemies, e)
                        e:Clear()
                    end
                end)
            end
        end
    end
end

function Action.CheckEnded()
    local s = Current()
    if not s:HasMoreRounds() then
        if #s.SpawnedEnemies == 0 then
            Player.Notify(__("All enemies are dead."))
            Scenario.End()
        else
            Player.Notify(__("%d enemies left.", #s.SpawnedEnemies), true)
        end
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@return table
function Scenario.GetTemplates()
    return External.Templates.GetScenarios(scenarioTemplates)
end

function Scenario.ExportTemplates()
    External.File.Export("Scenarios", scenarioTemplates)
end

---@param state Scenario
function Scenario.RestoreFromState(state)
    xpcall(function()
        S = Scenario.Restore(state)
        PersistentVars.Scenario = S

        Player.Notify(__("Scenario restored."))

        if not S:HasStarted() then
            if S.OnMap then
                Action.MapEntered()
            else
                Action.NotifyStarted()
            end
        end
    end, function(err)
        L.Error(err)
        Enemy.Cleanup()
        S = nil
        PersistentVars.Scenario = nil
        Player.Notify(__("Failed to restore scenario."))
    end)
end

---@param scenario Scenario
---@return Scenario
function Scenario.Restore(scenario)
    local s = Object.Init(scenario)

    s.KilledEnemies = UT.Map(s.KilledEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.SpawnedEnemies = UT.Map(s.SpawnedEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.Enemies = UT.Map(s.Enemies, function(v, k)
        return UT.Map(v, function(e)
            return Enemy.Restore(e)
        end), tonumber(k)
    end)

    s.Timeline = UT.Map(s.Timeline, function(v, k)
        return v, tonumber(k)
    end)

    s.Map = Map.Restore(scenario.Map)

    return s
end

---@param template table
---@param map Map|nil
function Scenario.Start(template, map)
    if S ~= nil then
        L.Error("Scenario already started.")
        return
    end

    ---@type Enemy[]
    local enemies = {}

    ---@type Scenario
    local scenario = Object.New()

    local timeline = template.Timeline

    local maps = Map.Get()
    if #maps == 0 then
        L.Error("Starting scenario failed.", "No maps found.")
        return
    end

    if template.Map ~= nil then
        map = UT.Find(maps, function(m)
            return m.Name == template.Map
        end) or map
    end

    if map == nil then
        map = maps[U.Random(#maps)]
    end

    if type(timeline) == "function" then
        timeline = timeline(template, map)
    end

    scenario.Name = template.Name
    scenario.Map = map
    scenario.Timeline = timeline
    scenario.Positions = template.Positions or {}

    scenario.LootRates = template.Loot or C.LootRates

    local enemyCount = 0
    for round, definitions in pairs(scenario.Timeline) do
        L.Dump("Adding enemies for round.", round, definitions)
        for _, definition in pairs(definitions) do
            local e
            if UT.Contains(C.EnemyTier, definition) then
                e = Enemy.Random(function(e)
                    return e.Tier == definition and Ext.Template.GetTemplate(e.TemplateId) ~= nil
                end)
            else
                e = Enemy.Find(definition)
            end

            if e == nil then
                L.Error("Starting scenario failed.", "Enemy configuration is wrong.")
                return
            end
            enemyCount = enemyCount + 1
            scenario:AddEnemy(round, e)
        end
    end

    if map.Timeline and UT.Size(map.Timeline) > 0 then
        -- pad positions from the map timeline
        if UT.Size(scenario.Positions) < UT.Size(map.Timeline) then
            UT.Merge(scenario.Positions, map.Timeline)
        end

        -- append the map timeline until we have enough positions
        while UT.Size(scenario.Positions) < enemyCount do
            UT.Combine(scenario.Positions, map.Timeline)
        end
    end
    while UT.Size(scenario.Positions) < enemyCount do
        table.insert(scenario.Positions, U.Random(#map.Spawns))
    end

    Player.Notify(__("Scenario %s started.", template.Name))
    S = scenario
    PersistentVars.Scenario = S

    Action.NotifyStarted()

    Enemy.Cleanup()
    Event.Trigger("ScenarioStarted", Current())
end

function Scenario.End()
    local s = Current()
    Event.Trigger("ScenarioEnded", s)
    Action.SpawnLoot()

    PersistentVars.LastScenario = S
    S = nil
    PersistentVars.Scenario = nil
    Player.Notify(__("Scenario ended."))
end

function Scenario.Stop()
    Event.Trigger("ScenarioStopped", Current())
    Enemy.Cleanup()
    S = nil
    PersistentVars.Scenario = nil
    Player.Notify(__("Scenario stopped."))
end

Scenario.Teleport = Async.Throttle(3000, function()
    local s = Current()

    for _, character in pairs(U.DB.GetPlayers()) do
        Map.TeleportTo(s.Map, character)
    end
end)

-- TODO check if breaks when used manually
function Scenario.ResumeCombat()
    local s = Current()
    if not s:IsRunning() then
        L.Error("Scenario has ended.")
        return
    end

    if not s.OnMap then
        return
    end

    s.CombatId = nil
    Action.StartRound()

    if not s:HasMoreRounds() then
        return
    end

    local amount = #s.SpawnedEnemies
    if amount > 0 then
        if Config.ForceEnterCombat then
            Scenario.CombatSpawned()
        end
        return
    end

    Scenario.ResumeCombat()
end

---@param specific Enemy|nil
-- we want to have all enemies on the map in combat
function Scenario.CombatSpawned(specific)
    local enemies = UT.Filter(Current().SpawnedEnemies, function(e)
        return specific == nil or U.Equals(e, specific)
    end)

    L.Debug("Combat spawned.", #enemies)

    local target = Player.InCombat() or Player.Host()
    for _, enemy in ipairs(enemies) do
        RetryUntil(function()
            if not S then
                return true
            end

            if not enemy:IsSpawned() then
                return false
            end

            if Osi.IsDead(enemy.GUID) == 1 then
                return true
            end

            enemy:Combat(Config.ForceEnterCombat)
            if S.CombatId then -- TODO check if works
                Osi.PROC_EnterCombatByID(enemy.GUID, S.CombatId)
            end

            return Osi.IsInCombat(enemy.GUID) == 1
        end, {
            immediate = true,
            retries = 5,
            interval = 1000,
        }).Catch(ifScenario(function()
            Action.Failsafe(enemy)
        end))
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Event.On("ScenarioStarted", function()
    Player.ReturnToCamp()
end)

U.Osiris.On(
    "CombatRoundStarted",
    2,
    "before",
    ifScenario(function(combatGuid, round)
        local s = Current()
        if not s:HasStarted() then
            L.Error("Scenario has not started yet.")
            return
        end

        if s.CombatId == nil then
            return
        end

        if s.CombatId ~= combatGuid then
            L.Debug("Combat unrelated to the scenario.", combatGuid, s.combatId)
            -- try to restore the combat
            local guids = UT.Map(s.SpawnedEnemies, function(e)
                return e.GUID and Osi.CombatGetGuidFor(e.GUID) or nil
            end)
            if UT.Contains(guids, combatGuid) then
                s.CombatId = combatGuid
            else
                return
            end
        end

        Scenario.CombatSpawned()

        -- this is just for fun and too hard to maintain
        if Config.ForceCombatRestart then
            -- TODO fails when enemies don't enter combat
            if round > 1 then
                for _, e in pairs(s.SpawnedEnemies) do
                    -- should always be spawned
                    if e:IsSpawned() then
                        Osi.LeaveCombat(e.GUID)
                        e:Combat(true)
                    end
                end
                -- to not trigger this event again when still in combat
                s.CombatId = nil
            end
        end

        -- first round is usually the manual start
        if round > 1 then
            Action.StartRound()
        end
    end)
)

U.Osiris.On(
    "EnteredCombat",
    2,
    "after",
    ifScenario(function(object, combatGuid)
        local s = Current()
        if not s:HasStarted() then
            return
        end

        if s.CombatId ~= combatGuid then -- should not happen
            return
        end

        local guid = U.UUID.Extract(object)

        if not Enemy.IsValid(guid) then
            return
        end

        if UT.Find(s.SpawnedEnemies, function(e)
            return U.UUID.Equals(e.GUID, guid)
        end) then
            return
        end

        if PersistentVars.SpawnedEnemies[guid] then
            return
        end

        L.Debug("Entered combat.", guid, combatGuid)
        Schedule(function()
            Enemy.CreateTemporary(guid)
        end)
    end)
)

U.Osiris.On(
    "CombatStarted",
    1,
    "before",
    ifScenario(function(combatGuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        L.Debug("Combat started.", combatGuid)

        if s.CombatId ~= nil then
            return
        end

        s.CombatId = combatGuid
        if s.Round == 1 then
            Player.Notify(__("Combat started."))
        end
    end)
)

U.Osiris.On(
    "CombatEnded",
    1,
    "after",
    ifScenario(function(combatGuid)
        L.Debug("Combat ended.", combatGuid)

        local s = Current()
        if s.CombatId == combatGuid then
            s.CombatId = nil

            -- empty round wont progress the combat
            -- manually progress the combat
            if s:HasMoreRounds() and #s:SpawnsForRound() == 0 then
                Scenario.ResumeCombat()
            end
        end
    end)
)

U.Osiris.On(
    "TeleportedFromCamp",
    1,
    "before",
    ifScenario(function(uuid)
        if UE.IsNonPlayer(uuid) then
            return
        end

        Scenario.Teleport()
    end)
)

Event.On(
    "ScenarioTeleport",
    ifScenario(function(target)
        if not S.OnMap and U.UUID.Equals(target, Player.Host()) then
            S.OnMap = true
            Defer(2000).After(Action.MapEntered)
        end
    end)
)

U.Osiris.On(
    "TeleportedToCamp",
    1,
    "after",
    ifScenario(function(uuid)
        if S.OnMap and U.UUID.Equals(uuid, Player.Host()) then
            Defer(1000, function()
                if not Player.InCombat() then
                    Scenario.Stop()
                    Player.Notify(__("Returned to camp."))
                end
            end)
        end
    end)
)

-- TODO maybe move to entity events
U.Osiris.On(
    "Resurrected",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        for i, e in ipairs(s.KilledEnemies) do
            if U.UUID.Equals(e.GUID, uuid) then
                if Osi.IsDead(e.GUID) ~= 0 then
                    -- manually killed on resurrection
                    return
                end
                -- let it count twice for loot
                table.insert(s.SpawnedEnemies, e)
                Player.Notify(__("Enemy %s rejoined.", e:GetTranslatedName()), true)
                -- table.remove(s.KilledEnemies, i)

                Action.EnemyAdded(e)
                return
            end
        end
    end)
)

-- TODO maybe move to entity events
U.Osiris.On(
    "Died",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        local spawnedKilled = false
        for i, e in ipairs(s.SpawnedEnemies) do
            if U.UUID.Equals(e.GUID, uuid) then
                table.insert(s.KilledEnemies, e)
                table.remove(s.SpawnedEnemies, i)

                -- might revive and rejoin battle
                Player.Notify(__("Enemy %s killed.", e:GetTranslatedName()), true)
                Event.Trigger("ScenarioEnemyKilled", Current(), e)

                spawnedKilled = true
                break
            end
        end

        if not spawnedKilled then
            L.Debug("Non-spawned enemy killed.", uuid)
            return
        end

        Action.EnemyRemoved()
    end)
)