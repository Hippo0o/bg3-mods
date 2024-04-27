---@diagnostic disable: undefined-global

local data = Require("MyMod/Templates/Scenarios.lua")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Structures                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Scenario: LibsObject
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
local Object = Libs.Object({
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
            -- avoid 0 rolls e.g. epic armor doesnt exist
            while #items == 0 and fail < 3 do
                fail = fail + 1

                bonusCategory = ({ "Object", "Weapon", "Armor" })[U.Random(3)]
                local bonus = {}

                for _, r in ipairs(C.ItemRarity) do
                    if bonusCategory == "Object" and scenario.LootObjects[r] then
                        bonus = add(bonus, r, 1 + scenario.LootObjects[r])
                    elseif bonusCategory == "Weapon" and scenario.LootWeapons[r] then
                        bonus = add(bonus, r, 1 + scenario.LootWeapons[r])
                    elseif bonusCategory == "Armor" and scenario.LootArmor[r] then
                        bonus = add(bonus, r, 1 + scenario.LootArmor[r])
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
    Player.Notify("Dropping loot.")

    local map = Current().Map
    local loot = Action.CalculateLoot()
    local i = 1
    Async.Interval(300 - (#loot * 2), function(self)
        i = i + 1
        map:SpawnLoot(loot[i])
        if i == #loot then
            self:Clear()
        end
    end)
end

function Action.EmptyArea()
    if not C.BypassStory then
        return
    end

    local toRemove = UT.Filter(UE.GetNearby(Player.Host(), 100, true), function(v)
        return v.Entity.IsCharacter and UE.IsNonPlayer(v.Guid)
    end)

    -- TODO maybe only use Osi.SetOnStage
    for _, v in pairs(toRemove) do
        UE.Remove(v.Guid)
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

    Player.Notify("Combat is Starting.")
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
                retries = 3,
                interval = 500,
                success = function()
                    if C.ForceEnterCombat or Player.InCombat() then
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
        if C.ForceEnterCombat then
            Scenario.CombatSpawned()
        end
        return
    end

    Action.ResumeCombat()
end

function Action.StartRound()
    Current().Round = Current().Round + 1
    Player.Notify("Round " .. Current().Round)

    Action.SpawnRound()
end

function Action.MapEntered()
    local x, y, z = Player.Pos()
    RetryFor(function(_, tries)
        if tries % 10 == 0 then
            Player.Notify("Move to start scenario", true)
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
            Player.Notify("Scenario canceled due to timeout.")
        end,
    })
end

function Action.Failsafe()
    local s = Current()

    if #s.SpawnedEnemies > 0 and not s:HasMoreRounds() then
        L.Debug("Running failsafe.", #s.SpawnedEnemies)

        for _, e in pairs(s.SpawnedEnemies) do
            L.Error("Failsafe triggered.", e:GetId(), e.GUID)

            if not e:IsSpawned() then
                UT.Remove(s.SpawnedEnemies, e)
            elseif Osi.IsInCombat(e.GUID) == 0 then
                Schedule(function() -- pyramid of please combat me daddy
                    Osi.SetVisible(e.GUID, 1) -- sneaky shits never engage combat
                    e:Combat(true)

                    Schedule(function()
                        if Osi.IsInCombat(e.GUID) == 1 then
                            return
                        end

                        s.Map:Teleport(e.GUID)
                        e:Combat(true)

                        Schedule(function()
                            if Osi.IsInCombat(e.GUID) == 0 then
                                UT.Remove(s.SpawnedEnemies, e)
                                e:Clear()
                            end
                        end)
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
            Player.Notify("All enemies are dead.")
            Scenario.End()
        else
            Player.Notify(#s.SpawnedEnemies .. " enemies left.")
        end
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@return table
function Scenario.Get()
    return data
end

---@param state Scenario
function Scenario.RestoreFromState(state)
    xpcall(function()
        S = Scenario.Restore(state)
        Player.Notify("Scenario restored.")

        if not S:HasStarted() and S.OnMap then
            Action.MapEntered()
        end
    end, function(err)
        L.Error(err)
        Enemy.Cleanup()
        S = nil
        Player.Notify("Failed to restore scenario.")
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
    scenario.Map = map
    scenario.Timeline = template.Timeline
    scenario.LootObjects = template.Loot.Objects
    scenario.LootArmor = template.Loot.Armor
    scenario.LootWeapons = template.Loot.Weapons

    for round, tiers in pairs(template.Timeline) do
        local enemyCount = #tiers
        for i = 1, enemyCount do
            local e = Enemy.Random(function(e)
                return e.Tier == tiers[i]
            end)
            assert(e ~= nil, "Enemy configuration is wrong.")
            scenario:AddEnemy(round, e)
        end
    end

    Player.Notify("Scenario started.")
    S = scenario
    Player.Notify("Leave camp to join the battle.")

    Enemy.Cleanup()
end

function Scenario.End()
    Action.SpawnLoot()
    S = nil
    Player.Notify("Scenario ended.")
end

function Scenario.Stop()
    Enemy.Cleanup()
    S = nil
    Player.Notify("Scenario stopped.")
end

function Scenario.Teleport(uuid)
    Current().Map:Teleport(uuid)
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

            enemy:Combat(C.ForceEnterCombat)
            Osi.EnterCombat(enemy.GUID, target)

            return Osi.IsInCombat(enemy.GUID) == 1
        end, { immediate = true, retries = 5, interval = 500 })
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener(
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

        if C.CombatWorkaround then
            if round > 1 then
                for _, e in pairs(s.SpawnedEnemies) do
                    -- should always be spawned
                    if e:IsSpawned() then
                        Osi.LeaveCombat(e.GUID)
                        e:Combat(true)
                    end
                end
                s.CombatId = nil
            end
        end

        -- first round is usually the manual start
        if round > 1 then
            Action.StartRound()
        end
    end)
)

Ext.Osiris.RegisterListener(
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

        if not Enemy.IsValid(object) then
            return
        end

        if UT.Contains(s.SpawnedEnemies, function(e)
            return U.UUID.Equals(e.GUID, object)
        end) then
            return
        end

        if PersistentVars.SpawnedEnemies[object] then
            return
        end

        L.Debug("Entered combat.", object, combatGuid)
        Enemy.CreateTemporary(object)
    end)
)

Ext.Osiris.RegisterListener(
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
            Player.Notify("Combat started.")
        end
    end)
)

Ext.Osiris.RegisterListener(
    "CombatEnded",
    1,
    "after",
    ifScenario(function(combatGuid)
        L.Debug("Combat ended.", combatGuid)

        local s = Current()
        if s.CombatId == combatGuid then
            -- TODO failsafe interval
            s.CombatId = nil
            --- empty round wont progress the combat
            if s:HasMoreRounds() and #s:SpawnsForRound() == 0 then
                Action.ResumeCombat()
                return
            end

            Defer(1000, function()
                ifScenario(Action.Failsafe)
                ifScenario(Action.CheckEnded)
            end)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "TeleportedFromCamp",
    1,
    "before",
    ifScenario(function(uuid)
        if UE.IsNonPlayer(uuid) then
            return
        end

        S.OnMap = true
        Scenario.Teleport(uuid)
    end)
)

Ext.Osiris.RegisterListener(
    "TeleportedFromCamp",
    1,
    "after",
    ifScenario(function(uuid)
        if S.OnMap and U.UUID.Equals(uuid, Player.Host()) then
            Action.MapEntered()
        end
    end)
)

Ext.Osiris.RegisterListener(
    "TeleportedToCamp",
    1,
    "after",
    ifScenario(function(uuid)
        if S.OnMap and U.UUID.Equals(uuid, Player.Host()) then
            Scenario.Stop()
            Player.Notify("Returned to camp.")
        end
    end)
)

Ext.Osiris.RegisterListener(
    "Died",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        for i, e in ipairs(s.SpawnedEnemies) do
            if U.UUID.Equals(e.GUID, uuid) then
                table.insert(s.KilledEnemies, e)
                table.remove(s.SpawnedEnemies, i)

                Player.Notify("Enemy killed.")
                break
            end
        end

        Action.CheckEnded()

        if #s.SpawnedEnemies == 0 and s:HasMoreRounds() then
            Action.ResumeCombat()
        end
    end)
)
