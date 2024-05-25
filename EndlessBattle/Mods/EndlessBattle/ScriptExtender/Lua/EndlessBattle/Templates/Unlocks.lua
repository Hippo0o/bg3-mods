local function getUnlocks()
    return Unlock.Get()
end

local function unlockTadpole(object)
    Osi.SetTag(object, "089d4ca5-2cf0-4f54-84d9-1fdea055c93f")
    Osi.SetTag(object, "efedb058-d4f5-4ab8-8add-bd5e32cdd9cd")
    Osi.SetTag(object, "c15c2234-9b19-453e-99cc-00b7358b9fce")
    Osi.SetTadpoleTreeState(object, 2)
    Osi.AddTadpole(object, 1)
    Osi.AddTadpolePower(object, "TAD_IllithidPersuasion", 1)
    Osi.SetFlag("GLO_Daisy_State_AstralIndividualAccepted_9c5367df-18c8-4450-9156-b818b9b94975", object)
end

return {
    {
        Id = "UnlockTadpole",
        Name = __("Unlock Tadpole Power"),
        Icon = "TadpoleSuperPower_IllithidPowers",
        Cost = 10,
        Amount = nil,
        Character = true,
        OnActivate = function(self, character)
            unlockTadpole(character)
        end,
    },
    {
        Id = "TadpoleCeremorph",
        Name = __("Start Ceremorphosis"),
        Icon = "TadpoleSuperPower_IllithidPersuasion",
        Description = __("Includes %s", __("Unlock Tadpole Power")),
        Cost = 300,
        Amount = nil,
        Character = true,
        Requirement = 45,
        OnActivate = function(self, character)
            unlockTadpole(character)
            Osi.SetTag(character, "c0cd4ed8-11d1-4fb1-ae3a-3a14e41267c8")
            Osi.ApplyStatus(character, "TAD_PARTIAL_CEREMORPH", -1)
        end,
    },
    {
        Id = "TadAwaken",
        Name = __("Awakened Illithid Powers"),
        Icon = "PassiveFeature_CRE_GithInfirmary_Awakened",
        Description = __("Use all Illithid Powers with Bonus Actions."),
        Cost = 100,
        Amount = 1,
        Character = true,
        OnActivate = function(self, character)
            Osi.AddPassive(character, "CRE_GithInfirmary_Awakened")
        end,
    },
    {
        Id = "Tadpole",
        Name = "Tadpole",
        Icon = "Item_LOOT_Druid_Autopsy_Set_Tadpole",
        Cost = 30,
        Amount = nil,
        Character = false,
        OnActivate = function(self, character)
            Osi.AddTadpole(character, 1)
        end,
    },
    {
        Id = "BuyGold",
        Name = "100 Gold",
        Icon = "Item_LOOT_COINS_Gold_Pile_Single_A",
        Cost = 5,
        Amount = nil,
        Character = false,
        OnActivate = function(self, character)
            Osi.AddGold(character, 100)
        end,
    },
    {
        Id = "BuyLoot",
        Name = "Roll Loot 10x",
        Icon = "Action_Dash_Bonus",
        Cost = 30,
        Amount = 10,
        Character = false,
        OnActivate = function(self, character)
            local loot = Item.GenerateLoot(10, C.LootRates)

            local x, y, z = Osi.GetPosition(character)
            Item.SpawnLoot(loot, x, y, z)
        end,
    },
    {
        Id = "BuyExp",
        Name = "1000 EXP",
        Icon = "Action_Dash_Bonus",
        Cost = 40,
        Amount = 3,
        Character = false,
        OnActivate = function(self, character)
            for _, p in pairs(U.DB.GetPlayers()) do
                Osi.AddExplorationExperience(p, 1000)
            end
        end,
    },
    -- PROC_CAMP_GiveFreeSupplies()
    {
        Id = "BreakOath",
        Name = __("Break Oath"),
        Icon = "statIcons_OathBroken",
        Description = __("Needs to be a Paladin."),
        Cost = 10,
        Amount = nil,
        Character = true,
        OnActivate = function(self, character)
            Osi.PROC_GLO_PaladinOathbreaker_BrokeOath(character)
            Osi.PROC_GLO_PaladinOathbreaker_BecomesOathbreaker(character)
            -- Osi.RequestRespec(character)
            -- Osi.StartRespec(character)
            -- Osi.StartRespecToOathbreaker(character)
        end,
    },
    {
        Id = "MOD_BOOSTS",
        Name = __("Unlock Multipliers"),
        Icon = "PassiveFeature_Generic_Explosion",
        Cost = 2000,
        Amount = 1,
        Character = false,
        Persistent = true,
        Requirement = 100,
    },
    {
        Id = "ExpMultiplier",
        Name = __("Gain double XP"),
        Icon = "Spell_MagicJar",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = "MOD_BOOSTS",
        OnActivate = function(self, character)
            PersistentVars.Unlocked.ExpMultiplier = true
        end,
    },
    {
        Id = "LootMultiplier",
        Name = __("Gain 50%% more loot"),
        Icon = "Spell_Transmutation_FleshToGold",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = { "MOD_BOOSTS", 20 },
        OnActivate = function(self, character)
            PersistentVars.Unlocked.LootMultiplier = true
        end,
    },
    {
        Id = "CurrencyMultiplier",
        Name = __("Gain 20%% more Currency"),
        Icon = "Item_LOOT_COINS_Electrum_Pile_Small_A",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = { "MOD_BOOSTS", 40 },
        OnActivate = function(self, character)
            PersistentVars.Unlocked.CurrencyMultiplier = true
        end,
    },
    {
        Id = "NEWGAME_PLUS",
        Name = __("Unlock New Game+"),
        Icon = "PassiveFeature_Generic_Explosion",
        Cost = 2000,
        Amount = 1,
        Character = false,
        Persistent = true,
        Requirement = 300,
    },
    {
        Id = "BuyExpPlus",
        Name = "1000 EXP",
        Icon = "Action_Dash",
        Cost = 0,
        Amount = 3,
        Character = false,
        Requirement = "NEWGAME_PLUS",
        OnActivate = function(self, character)
            for _, p in pairs(U.DB.GetPlayers()) do
                Osi.AddExplorationExperience(p, 1000)
            end
        end,
    },
    {
        Id = "ScoreMultiplier",
        Name = __("Gain double RogueScore"),
        Icon = "Action_EndGameAlly_ShadowAdepts",
        Cost = 0,
        Amount = 1,
        Character = false,
        Requirement = "NEWGAME_PLUS",
        OnActivate = function(self, character)
            PersistentVars.Unlocked.RogueScoreMultiplier = true
        end,
    },
}
