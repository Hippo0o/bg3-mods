local low, medium, high, ultra, epic, legendary =
    C.EnemyTier[1], C.EnemyTier[2], C.EnemyTier[3], C.EnemyTier[4], C.EnemyTier[5], C.EnemyTier[6]

local defaultLoot = {
    Objects = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        -- Epic = 10,
        -- Legendary = 0,
    },
    Armor = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        -- Epic = 10,
        Legendary = 0,
    },
    Weapons = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        Epic = 10,
        Legendary = 0,
    },
}

return {
    {
        Name = "Scenario 1",

        -- Spawns per Round
        Timeline = {
            { low, low, low },
            {},
            { low, low },
            {},
            { low },
        },

        -- Amount of enemies decide the amount of loot
        Loot = defaultLoot,
    },
    {
        Name = "Scenario 2",

        Timeline = {
            { low, low, low },
            { low, low, medium, low, low, low, low, low, low },
            { low },
            {},
            { medium },
            { low, low, high },
            { low, low },
            { high },
        },

        Loot = defaultLoot,
    },
    {
        Name = "Scenario 3",

        Timeline = {
            { medium, medium, medium },
            { medium, medium, medium, medium, medium, low, low },
            { medium },
            {},
            { medium },
            { medium, medium, high },
            { medium, medium },
            { high },
        },

        Loot = defaultLoot,
    },
    {
        Name = "Scenario 4",

        Timeline = {
            { medium, medium, medium, medium, medium, low, low },
            { high, high, high },
            { medium },
            {},
            { high, high, high },
            { medium, medium, high },
            { medium, low },
            { ultra },
        },

        Loot = defaultLoot,
    },
    {
        Name = "Scenario 5",

        Timeline = {
            { medium, medium, high, medium, medium, ultra, ultra },
            { high, high, high },
            { medium, medium },
            { epic },
            { high, high, high },
            { high, medium, high },
            { medium, ultra },
            { ultra },
        },

        Loot = defaultLoot,
    },
    {
        Name = "high",

        -- Spawns per Round
        Timeline = {
            { high, high, high },
            { high, high, high },
            { ultra, ultra },
            {},
            { epic, epic },
        },

        -- Amount of enemies decide the amount of loot
        Loot = defaultLoot,
    },
}
