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
        Name = "Unlock Tadpole Power",
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
        Name = "Start Ceremorphosis",
        Icon = "TadpoleSuperPower_IllithidPersuasion",
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
        Id = "Tadpole",
        Name = "Get a tadpole",
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
    {
        Id = "MOD_BOOSTS",
        Name = "Unlock Multipliers",
        Icon = "PassiveFeature_Generic_Explosion",
        Cost = 2000,
        Amount = 1,
        Character = false,
        Persistent = true,
        Requirement = 100,
    },
    {
        Id = "ExpMultiplier",
        Name = "Gain double XP",
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
        Name = "Gain 50% more loot",
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
        Name = "Gain 20% more currency",
        Icon = "Item_LOOT_COINS_Electrum_Pile_Small_A",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = { "MOD_BOOSTS", 40 },
        OnActivate = function(self, character)
            PersistentVars.Unlocked.CurrencyMultiplier = true
        end,
    },
}
