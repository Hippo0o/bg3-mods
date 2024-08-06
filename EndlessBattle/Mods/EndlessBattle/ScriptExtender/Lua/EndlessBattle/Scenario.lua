local scenarioTemplates = Require("EndlessBattle/Templates/Scenarios.lua")
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
---@field LootObjects table<string, number>
---@field LootArmor table<string, number>
---@field LootWeapons table<string, number>
---@field OnMap boolean
---@field New fun(self): self
local Object = Libs.Class({
    Name = nil,
    Enemies = {},
    KilledEnemies = {},
    SpawnedEnemies = {},
    Map = nil,
    CombatId = nil,
    OnMap = false,
    Round = 0,
    Timeline = {},
    LootObjects = {},
    LootArmor = {},
    LootWeapons = {},
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

function Object:HasMoreRounds()
    return self.Round < #self.Timeline
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
    return function(...)
        if S == nil then
            return
        end
        func(...)
    end
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

    local loot = {}
    for _, e in pairs(scenario.KilledEnemies) do
        -- each kill gets an object/weapon/armor roll
        -- TODO drop gold

        local fixed = {}
        local bonusRolls = 1

        for k, v in ipairs(C.EnemyTier) do
            if e.Tier == v then
                -- k is higher for higher tier
                bonusRolls = k
                break
            end
        end

        local function add(t, rarity, amount)
            for i = 1, amount do
                table.insert(t, rarity)
            end

            return t
        end

        -- build rarity roll tables from template e.g. { "Common", "Common", "Uncommon", "Rare" }
        -- if rarity is 0 it will be at least added once
        -- if rarity is not defined it will not be added
        for _, r in ipairs(C.ItemRarity) do
            if scenario.LootObjects[r] then
                fixed = add(fixed, r, scenario.LootObjects[r])
            end
        end

        for i = 1, bonusRolls do
            do
                local rarity = fixed[U.Random(#fixed)]
                local items = Item.Objects(rarity, false)

                L.Debug("Rolling fixed loot items:", #items, "Object", rarity)
                if #items > 0 then
                    table.insert(loot, items[U.Random(#items)])
                end
            end

            local items = {}
            local fail = 0
            local bonusCategory = nil
            local rarity = nil
            -- avoid 0 rolls e.g. legendary objects dont exist
            while #items == 0 and fail < 3 do
                fail = fail + 1

                bonusCategory = ({ "Object", "Weapon", "Armor" })[U.Random(3)]
                local bonus = {}

                for _, r in ipairs(C.ItemRarity) do
                    if bonusCategory == "Object" and scenario.LootObjects[r] then
                        bonus = add(bonus, r, scenario.LootObjects[r])
                    elseif bonusCategory == "Weapon" and scenario.LootWeapons[r] then
                        bonus = add(bonus, r, scenario.LootWeapons[r])
                    elseif bonusCategory == "Armor" and scenario.LootArmor[r] then
                        bonus = add(bonus, r, scenario.LootArmor[r])
                    end
                end

                rarity = bonus[U.Random(#bonus)]
                if bonusCategory == "Object" then
                    items = Item.Objects(rarity, true)
                elseif bonusCategory == "Weapon" then
                    items = Item.Weapons(rarity)
                elseif bonusCategory == "Armor" then
                    items = Item.Armor(rarity)
                end
            end

            L.Debug("Rolling bonus loot items:", #items, bonusCategory, rarity)
            if #items > 0 then
                table.insert(loot, items[U.Random(#items)])
            end
        end
    end

    L.Dump("Loot", loot)
    return loot
end

function Action.SpawnLoot()
    Player.Notify(__("Dropping loot."))

    local map = Current().Map
    local loot = Action.CalculateLoot()
    local i = 0
    Async.Interval(300 - (#loot * 2), function(self)
        i = i + 1

        if i > #loot then
            self:Clear()

            return
        end

        if loot[i] == nil then
            L.Error("Loot was empty.", i, #loot)
            return
        end
        map:SpawnLoot(loot[i])
    end)
end

function Action.EmptyArea()
    if not Config.BypassStory then
        return
    end

    local toRemove = UT.Filter(UE.GetNearby(Player.Host(), 50, true), function(v)
        return v.Entity.IsCharacter and UE.IsNonPlayer(v.Guid)
    end)

    for _, v in pairs(toRemove) do
        L.Debug("Removing entity.", v.Guid)
        -- UE.Remove(v.Guid)
        Osi.SetOnStage(v.Guid, 0)
        Osi.DisappearOutOfSightTo(v.Guid, Player.Host(), "Run", 1, "")
    end
end

function Action.StartCombat()
    if Current().CombatId ~= nil then
        L.Error("Combat already started.")
        return
    end

    -- remove corpses from previous combat
    Enemy.Cleanup()
    -- remove all non-player characters
    Action.EmptyArea()

    Current().Map:PingSpawns()

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
        Async.Run(function()
            RetryFor(function()
                L.Debug("Spawning enemy.", e:GetId())
                return s.Map:SpawnIn(e, -1)
            end, {
                immediate = true,
                retries = #Current().Map.Spawns,
                interval = 500,
                success = function()
                    Player.Notify(__("Enemy %s spawned.", e:GetTranslatedName()), true, e:GetId())
                    if Config.ForceEnterCombat or Player.InCombat() then
                        Scenario.CombatSpawned(e)
                    end
                end,
                failed = function()
                    L.Error("Spawn limit exceeded.", e:GetId())
                    UT.Remove(s.SpawnedEnemies, e)
                end,
            })
        end)
        table.insert(s.SpawnedEnemies, e)
    end

    L.Debug("Enemies queued for spawning.", #toSpawn)
end

function Action.ResumeCombat()
    local s = Current()
    if not s:IsRunning() then
        L.Error("Scenario has ended.")
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

    Action.ResumeCombat()
end

function Action.StartRound()
    Current().Round = Current().Round + 1
    Player.Notify(__("Round %d", Current().Round))

    Action.SpawnRound()
end

function Action.MapEntered()
    if S:HasStarted() then
        return
    end

    local x, y, z = Player.Pos()
    RetryFor(function(self, tries)
        if S == nil then -- scenario stopped
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
        success = ifScenario(function()
            Action.StartCombat()
        end),
        failed = function()
            Scenario.Stop()
            Player.Notify(__("Scenario canceled due to timeout."))
        end,
    })
end

function Action.Failsafe(enemy)
    local s = Current()

    local list = enemy and { enemy } or s.SpawnedEnemies
    if #list > 0 then
        L.Dump("Running failsafe.", list)

        for _, e in pairs(list) do
            if not e:IsSpawned() then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                UT.Remove(s.SpawnedEnemies, e)
            elseif Osi.IsDead(e.GUID) == 0 and Osi.IsInCombat(e.GUID) == 0 then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                Osi.SetVisible(e.GUID, 1) -- sneaky shits never engage combat
                e:Combat(true)

                Schedule(function()
                    if Osi.IsInCombat(e.GUID) == 1 then
                        return
                    end

                    s.Map:Teleport(e.GUID)
                    e:Combat(true)

                    Defer(1000, function()
                        if Osi.IsInCombat(e.GUID) == 0 then
                            UT.Remove(s.SpawnedEnemies, e)
                            e:Clear()
                        end
                    end)
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
    return External.Templates.GetScenarios() or scenarioTemplates
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

        if not S:HasStarted() and S.OnMap then
            Action.MapEntered()
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
---@param map Map
function Scenario.Start(template, map)
    if S ~= nil then
        L.Error("Scenario already started.")
        return
    end

    ---@type Enemy[]
    local enemies = {}

    local scenario = Object.New()
    scenario.Name = template.Name
    scenario.Map = map
    scenario.Timeline = template.Timeline
    scenario.LootObjects = template.Loot.Objects
    scenario.LootArmor = template.Loot.Armor
    scenario.LootWeapons = template.Loot.Weapons

    for round, definition in pairs(template.Timeline) do
        local enemyCount = #definition
        for i = 1, enemyCount do
            local e
            if UT.Contains(C.EnemyTier, definition[i]) then
                e = Enemy.Random(function(e)
                    return e.Tier == definition[i]
                end)
            else
                e = Enemy.Find(definition[i])
            end

            if e == nil then
                L.Error("Starting scenario failed.", "Enemy configuration is wrong.")
                return
            end
            scenario:AddEnemy(round, e)
        end
    end

    Player.Notify(__("Scenario %s started.", template.Name))
    S = scenario
    PersistentVars.Scenario = S
    Player.Notify(__("Leave camp to join the battle."))

    Enemy.Cleanup()
end

function Scenario.End()
    Action.SpawnLoot()
    S = nil
    PersistentVars.Scenario = nil
    Player.Notify(__("Scenario ended."))
end

function Scenario.Stop()
    Enemy.Cleanup()
    S = nil
    PersistentVars.Scenario = nil
    Player.Notify(__("Scenario stopped."))
end

function Scenario.Teleport(uuid)
    local s = Current()
    Map.TeleportTo(s.Map, uuid, true)
end

---@param specific Enemy
-- we want to have all enemies on the map in combat
function Scenario.CombatSpawned(specific)
    local enemies = UT.Filter(Current().SpawnedEnemies, function(e)
        return specific == nil or U.Equals(e, specific)
    end)

    L.Debug("Combat spawned.", #enemies)

    local target = Player.InCombat() or Player.Host()
    for _, enemy in ipairs(enemies) do
        RetryFor(function()
            if not enemy:IsSpawned() then
                return false
            end

            if Osi.IsDead(enemy.GUID) == 1 then
                return true
            end

            enemy:Combat(Config.ForceEnterCombat)
            Osi.EnterCombat(enemy.GUID, target)

            return Osi.IsInCombat(enemy.GUID) == 1
        end, {
            immediate = true,
            retries = 5,
            interval = 1000,
            failed = ifScenario(function()
                if Player.InCombat() or Config.ForceEnterCombat then
                    Action.Failsafe(enemy)
                end
            end),
        })
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

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

        local guid = U.UUID.GetGUID(object)

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
        Enemy.CreateTemporary(guid)
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
            --- empty round wont progress the combat
            if s:HasMoreRounds() and #s:SpawnsForRound() == 0 then
                Action.ResumeCombat()
                return
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

        Scenario.Teleport(uuid)
    end)
)

Event.On(
    "ScenarioTeleport",
    ifScenario(function(target)
        if not S.OnMap and U.UUID.Equals(target, Player.Host()) then
            S.OnMap = true
            Defer(2000, Action.MapEntered)
        end
    end)
)

U.Osiris.On(
    "TeleportedToCamp",
    1,
    "after",
    ifScenario(function(uuid)
        if S.OnMap and U.UUID.Equals(uuid, Player.Host()) then
            Scenario.Stop()
            Player.Notify(__("Returned to camp."))
        end
    end)
)

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

                Player.Notify(__("Enemy %s killed.", e:GetTranslatedName()), true)
                spawnedKilled = true
                break
            end
        end

        if not spawnedKilled then
            L.Debug("Non-spawned enemy killed.", uuid)
            return
        end

        Action.CheckEnded()

        if #s.SpawnedEnemies == 0 and s:HasMoreRounds() then
            Action.ResumeCombat()
        end
    end)
)
