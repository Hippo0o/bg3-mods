local persistentUnlocks = IO.LoadJson("Save/Unlocks.json") or {}
local function persistUnlock(unlock)
    persistentUnlocks[unlock.Id] = unlock.Bought

    IO.SaveJson("Save/Unlocks.json", persistentUnlocks)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Unlock : Struct
---@field Id string
---@field Name string
---@field Icon string
---@field Cost integer
---@field Amount integer|nil
---@field Bought integer
---@field BoughtBy table<string, bool> -- Character GUID
---@field Character boolean
---@field Unlocked boolean
---@field Requirement table|string|nil
---@field Persistent boolean
---@field OnBuy fun(self: Unlock, character: string)
---@field OnReapply fun(self: Unlock)
---@field OnInit fun(self: Unlock)
---@field Buy fun(self: Unlock)
local Object = Libs.Struct({
    Id = nil,
    Name = nil,
    Icon = nil,
    Cost = 0,
    Amount = nil,
    Character = false,
    Bought = 0,
    BoughtBy = {},
    Unlocked = false,
    Requirement = nil,
    Persistent = false,
    OnBuy = function() end,
    OnReapply = function() end,
    OnInit = function() end,
})

function Object:Buy(character)
    self.Bought = self.Bought + 1
    self.BoughtBy[U.UUID.Extract(character)] = true
    self.OnBuy(self, character)

    if self.Persistent then
        persistUnlock(self)
    end
end

function Object:Buyable()
    return self.Unlocked and (self.Amount == nil or self.Bought < self.Amount)
end

function Object:UpdateUnlocked()
    if self.Requirement == nil then
        self.Unlocked = true
        return
    end

    local function unlockByScore(requirement)
        if type(requirement) == "number" then
            return PersistentVars.RogueScore >= requirement
        end
    end
    local function unlockByBought(requirement)
        if type(requirement) == "string" then
            local u = table.find(Unlock.Get(), function(u)
                return u.Id == requirement
            end)
            return u and u.Bought > 0
        end
    end

    local requirement = self.Requirement
    if type(requirement) ~= "table" then
        requirement = { requirement }
    end

    local unlocked = true
    for _, r in pairs(requirement) do
        unlocked = unlocked and (unlockByScore(r) or unlockByBought(r))
    end

    self.Unlocked = unlocked and true or false
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Unlock.Restore(unlock)
    return Object.Init(unlock)
end

function Unlock.CalculateReward(scenario)
    local endRound = scenario.Round - 1
    local diff = endRound - scenario:TotalRounds()

    local rewardMulti = math.max(5 - diff, 1)
    local gained = math.max(PersistentVars.RogueScore / 2, scenario:KillScore() * rewardMulti)

    if PersistentVars.Unlocked.CurrencyMultiplier then
        gained = gained * 1.2
    end

    local prev = PersistentVars.Currency or 0
    Unlock.UpdateCurrency(prev + math.floor(gained))
end

function Unlock.UpdateCurrency(currency)
    local prev = PersistentVars.Currency or 0

    PersistentVars.Currency = currency

    if prev == currency then
        return
    end

    Event.Trigger("CurrencyChanged", prev, currency)

    Defer(1000, function()
        Player.Notify(__("Your Currency increased: %d -> %d!", prev, currency))
    end)
end

function Unlock.GetTemplates()
    return External.Templates.GetUnlocks()
end

function Unlock.Get()
    return PersistentVars.Unlocks
end

function Unlock.Sync()
    for _, unlockTemplate in pairs(Unlock.GetTemplates()) do
        local existing = table.find(PersistentVars.Unlocks, function(p)
            return p.Id == unlockTemplate.Id
        end)

        if not existing then
            table.insert(PersistentVars.Unlocks, unlockTemplate)
        else
            -- update keys from template that aren't stateful
            table.merge(existing, unlockTemplate)
            -- only key that can be nil on template
            if not unlockTemplate.Amount then
                existing.Amount = nil
            end
        end
    end

    local unlocks = {}
    local removedUnlocks = {}
    table.each(PersistentVars.Unlocks, function(u)
        if u.Persistent then
            if persistentUnlocks[u.Id] and persistentUnlocks[u.Id] > 0 then
                u.Bought = persistentUnlocks[u.Id]
            else
                u.Bought = 0
            end
        end

        local existing, index = table.find(Unlock.GetTemplates(), function(p)
            return p.Id == u.Id
        end)

        if not existing then
            u.Amount = -1
            u.Requirement = ""
            if tonumber(u.Bought) < 1 then
                return
            end

            table.insert(removedUnlocks, Unlock.Restore(u))
            return
        end

        unlocks[index] = Unlock.Restore(u)
    end)

    PersistentVars.Unlocks = table.extend(unlocks, removedUnlocks)

    Unlock.UpdateUnlocked()
end

local initialized = {}
function Unlock.UpdateUnlocked()
    for _, u in pairs(Unlock.Get()) do
        if not initialized[u.Id] then
            xpcall(u.OnInit, function(err)
                L.Error(err)
            end, u)

            initialized[u.Id] = true
        end
    end

    for _, u in pairs(Unlock.Get()) do
        xpcall(u.UpdateUnlocked, function(err)
            L.Error(err)
        end, u)
    end

    for _, u in pairs(Unlock.Get()) do
        xpcall(u.OnReapply, function(err)
            L.Error(err)
        end, u)
    end

    SyncState()
end

function Unlock.Buy(unlockId, buyer, target)
    local unlock = table.find(Unlock.Get(), function(u)
        return u.Id == unlockId
    end)

    local function soundFail()
        Osi.PlaySoundResource(buyer, "294bbcfa-fd7b-d8bf-bba1-5b790f8518af")
    end
    local function soundSuccess()
        Osi.PlaySoundResource(buyer, "a6571b9a-0b79-6712-6326-a0e3134ed0ad")
    end

    if Config.MulitplayerRestrictUnlocks and not GU.Character.IsHost(buyer) then
        soundFail()
        return false, __("Host has restricted buying unlocks.")
    end

    if Osi.IsInCombat(buyer) == 1 or Scenario.HasStarted() then
        soundFail()
        return false, __("Cannot buy while in combat.")
    end

    if unlock == nil then
        soundFail()
        return false, __("Unlock not found.")
    end

    Schedule(Unlock.UpdateUnlocked)

    if not unlock:Buyable() then
        soundFail()
        return false, __("Unlock out of stock.")
    end

    if unlock.Character and not target then
        soundFail()
        return false, __("Unlock needs a character.")
    end

    if unlock.Cost > PersistentVars.Currency then
        soundFail()
        return false, __("Not enough currency.")
    end

    local character = target or buyer

    unlock:Buy(character)
    Unlock.UpdateCurrency(PersistentVars.Currency - unlock.Cost)

    soundSuccess()

    Osi.ApplyStatus(buyer, "WAR_GODS_BLESSING", 1)
    if unlock.Character then
        Osi.ApplyStatus(character, "WAR_GODS_BLESSING", 1)
    end

    return true, PersistentVars.Currency
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.OnLoad(Unlock.Sync)

GameState.OnSave(function()
    for i, u in ipairs(PersistentVars.Unlocks) do
        PersistentVars.Unlocks[i] = UT.Clean(u)
    end
end)

Event.On("ScenarioTeleporting", Unlock.UpdateUnlocked)
Event.On("ScenarioStarted", Unlock.UpdateUnlocked)
Event.On("RogueScoreChanged", Unlock.UpdateUnlocked)
Event.On("TeleportedToAct", Unlock.UpdateUnlocked)
Ext.Osiris.RegisterListener("LongRestFinished", 0, "after", Unlock.UpdateUnlocked)
Ext.Osiris.RegisterListener("CombatRoundStarted", 2, "after", Unlock.UpdateUnlocked)

Event.On("ScenarioEnded", function(scenario)
    Unlock.CalculateReward(scenario)
end)

