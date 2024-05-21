local function getUnlocks()
    return Unlock.Get()
end

return {
    {
        Id = "UnlockTadpole",
        Name = "Unlock Tadpole",
        Icon = "GEN_Armor",
        Cost = 10,
        Amount = nil,
        Character = true,
        OnActivate = function(self, character)
            Osi.SetTag(character, "089d4ca5-2cf0-4f54-84d9-1fdea055c93f")
            Osi.SetTag(character, "efedb058-d4f5-4ab8-8add-bd5e32cdd9cd")
            Osi.SetTag(character, "c15c2234-9b19-453e-99cc-00b7358b9fce")
            Osi.SetTadpoleTreeState(character, 2)
            Osi.AddTadpole(character, 1)
            Osi.AddTadpolePower(character, "TAD_IllithidPersuasion", 1)
            Osi.SetFlag("GLO_Daisy_State_AstralIndividualAccepted_9c5367df-18c8-4450-9156-b818b9b94975", character)
        end,
    },
    {
        Id = "Tadpole",
        Name = "Get a tadpole",
        Icon = "GEN_Armor",
        Cost = 100,
        Amount = nil,
        Character = false,
        OnActivate = function(self, character)
            Osi.AddTadpole(character, 1)
        end,
    },
    {
        Id = "MOD_BOOSTS",
        Name = "Unlock Multipliers",
        Icon = "GEN_Armor",
        Cost = 10000,
        Amount = 1,
        Character = false,
        Persistent = true,
        Requirement = 100,
    },
    {
        Id = "ExpMultiplier",
        Name = "Gain double XP",
        Icon = "GEN_Armor",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = "MOD_BOOSTS",
    },
    {
        Id = "LootMultiplier",
        Name = "Gain 50% more loot",
        Icon = "GEN_Armor",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = { "MOD_BOOSTS", 20 },
    },
    {
        Id = "CurrencyMultiplier",
        Name = "Gain 20% more currency",
        Icon = "GEN_Armor",
        Cost = 100,
        Amount = 1,
        Character = false,
        Requirement = "MOD_BOOSTS",
    },
}
