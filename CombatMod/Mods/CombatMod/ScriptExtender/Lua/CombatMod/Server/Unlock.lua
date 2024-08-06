local unlocks = Require("CombatMod/Templates/Unlocks.lua")

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

---@class Unlock : LibsStruct
---@field Id string
---@field Name string
---@field Icon string
---@field Cost integer
---@field Amount integer|nil
---@field Bought integer
---@field BoughtBy table<string, bool> -- Character GUID
---@field Character boolean
---@field Unlocked boolean
---@field Requirement string|nil
---@field Persistent boolean
---@field OnBuy fun(self: Unlock)
---@field OnReapply fun(self: Unlock)
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
            local u = UT.Find(Unlock.Get(), function(u)
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
    if PersistentVars.Unlocked.CurrencyMultiplier then
        rewardMulti = rewardMulti * 1.2
    end

    local gained = math.floor(scenario:KillScore() * rewardMulti)

    local prev = PersistentVars.Currency or 0
    PersistentVars.Currency = prev + gained

    Player.Notify(__("Your Currency increased: %d -> %d!", prev, PersistentVars.Currency))
end

function Unlock.GetTemplates()
    return UT.Combine({}, unlocks, External.Templates.GetUnlocks())
end

function Unlock.Get()
    return PersistentVars.Unlocks
end

function Unlock.Sync()
    for _, unlockTemplate in pairs(Unlock.GetTemplates()) do
        local existing = UT.Find(PersistentVars.Unlocks, function(p)
            return p.Id == unlockTemplate.Id
        end)

        if not existing then
            table.insert(PersistentVars.Unlocks, unlockTemplate)
        else
            -- update keys from template that aren't stateful
            UT.Merge(existing, unlockTemplate)
            -- only key that can be nil on template
            if not unlockTemplate.Amount then
                existing.Amount = nil
            end
        end
    end

    local unlocks = {}
    UT.Each(PersistentVars.Unlocks, function(u)
        if u.Persistent then
            if persistentUnlocks[u.Id] and persistentUnlocks[u.Id] > 0 then
                u.Bought = persistentUnlocks[u.Id]
            else
                u.Bought = 0
            end
        end

        local existing = UT.Find(Unlock.GetTemplates(), function(p)
            return p.Id == u.Id
        end)

        if not existing then
            u.Amount = -1
            u.Requirement = ""
            if tonumber(u.Bought) < 1 then
                return
            end
        end

        table.insert(unlocks, Unlock.Restore(u))
    end)

    PersistentVars.Unlocks = unlocks

    Unlock.UpdateUnlocked()
end

function Unlock.UpdateUnlocked()
    for _, u in pairs(Unlock.Get()) do
        u:UpdateUnlocked()
    end
    for _, u in pairs(Unlock.Get()) do
        u:OnReapply()
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Event.On("ModActive", function()
    Unlock.Sync()
end)

GameState.OnLoad(IfActive(Unlock.Sync))

GameState.OnSave(IfActive(function()
    for i, u in ipairs(PersistentVars.Unlocks) do
        PersistentVars.Unlocks[i] = UT.Clean(u)
    end
end))

Event.On("ScenarioTeleport", Unlock.UpdateUnlocked)
Event.On("ScenarioStarted", Unlock.UpdateUnlocked)
Event.On("RogueScoreChanged", Unlock.UpdateUnlocked)

Event.On("ScenarioEnded", function(scenario)
    Unlock.CalculateReward(scenario)
end)


Net.On("BuyUnlock", function(event)
    local unlock = UT.Find(Unlock.Get(), function(u)
        return u.Id == event.Payload.Id
    end)

    local function soundFail()
        Osi.PlaySoundResource(event:Character(), "294bbcfa-fd7b-d8bf-bba1-5b790f8518af")
    end
    local function soundSuccess()
        Osi.PlaySoundResource(event:Character(), "a6571b9a-0b79-6712-6326-a0e3134ed0ad")
    end

    Unlock.UpdateUnlocked()

    if Osi.IsInCombat(event:Character()) == 1 or (S and S:HasStarted()) then
        Net.Respond(event, { false, __("Cannot buy while in combat.") })
        soundFail()
        return
    end

    if unlock == nil then
        Net.Respond(event, { false, __("Unlock not found.") })
        soundFail()
        return
    end

    if not unlock:Buyable() then
        Net.Respond(event, { false, __("Unlock out of stock.") })
        soundFail()
        return
    end

    if unlock.Character and (not event.Payload.Character or Osi.IsPlayer(event.Payload.Character) ~= 1) then
        Net.Respond(event, { false, __("Unlock needs a character.") })
        soundFail()
        return
    end

    if unlock.Cost > PersistentVars.Currency then
        Net.Respond(event, { false, __("Not enough currency.") })
        soundFail()

        return
    end

    unlock:Buy(event.Payload.Character or event:Character())
    PersistentVars.Currency = PersistentVars.Currency - unlock.Cost
    soundSuccess()

    Net.Respond(event, { true, PersistentVars.Currency })
    Unlock.UpdateUnlocked()

    SyncState()
end)
