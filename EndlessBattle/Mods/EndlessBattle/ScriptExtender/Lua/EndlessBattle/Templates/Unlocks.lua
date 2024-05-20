local function getUnlocks()
    return PersistentVars.Unlocks
end

return {
    {
        Id = "BOB_1",
        Name = "Unlock 1",
        Icon = "GEN_Armor",
        Cost = 100,
        Amount = 10,
        Bought = 0,
        Character = false,
        Unlocked = true,
        OnActivate = function(self, character)
            Osi.ShowNotification(character, "Bought " .. self.Name)
        end,
    },
    {
        Id = "BOB_2",
        Name = "Unlock Inf",
        Icon = "GEN_Armor",
        Cost = 333,
        Amount = nil,
        Bought = 0,
        Character = false,
        Unlocked = true,
        OnActivate = function(self, character)
            Osi.ShowNotification(character, "Bought " .. self.Name)
        end,
    },
    {
        Id = "AOSAD",
        Name = "Unlock More",
        Icon = "GEN_Armor",
        Cost = 1000,
        Amount = 1,
        Bought = 0,
        Character = false,
        Unlocked = true,
        OnActivate = function(self, character)
            for _, unlock in pairs(getUnlocks()) do
                if US.Contains(unlock.Id, { "PEPGA", "PEPGA2" }) then
                    unlock.Unlocked = true
                end
            end
        end,
    },
    {
        Id = "PEPGA2",
        Name = "Character UP",
        Icon = "GEN_Armor",
        Cost = 1337,
        Amount = 2,
        Bought = 0,
        Character = true,
        Unlocked = false,
    },
    {
        Id = "PEPGA",
        Name = "Character UP",
        Icon = "GEN_Armor",
        Cost = 10000,
        Amount = nil,
        Bought = 0,
        Character = true,
        Unlocked = false,
    },
}
