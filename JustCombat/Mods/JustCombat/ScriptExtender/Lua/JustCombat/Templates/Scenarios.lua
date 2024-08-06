local low, medium, high, ultra, epic, legendary =
    C.EnemyTier[1], C.EnemyTier[2], C.EnemyTier[3], C.EnemyTier[4], C.EnemyTier[5], C.EnemyTier[6]

local defaultLoot = {
    Objects = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        VeryRare = 10,
        -- Legendary = 0,
    },
    Armor = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        VeryRare = 10,
        Legendary = 0,
    },
    Weapons = {
        Common = 50,
        Uncommon = 30,
        Rare = 20,
        VeryRare = 10,
        Legendary = 0,
    },
}

return {
    {
        Name = "level 1",

        -- Spawns per Round
        Timeline = {
            { low },
            { low },
            { low },
        },

        Loot = defaultLoot,
    },
    {
        Name = "level 1 - 3",

        -- Spawns per Round
        Timeline = {
            { low, low, low },
            {},
            { low, low },
            {},
            { low },
        },

        Loot = defaultLoot,
    },
    {
        Name = "level 3 - 5",

        -- Spawns per Round
        Timeline = {
            { low, low },
            { low, low },
            {},
            { low, low, low },
            { low },
        },

        Loot = defaultLoot,
    },
    {
        Name = "level 5 - 7",

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
        Name = "level 7 - 9",

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
        Name = "level 8 - 10",

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
        Name = "level 10 - 12",

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
        Name = "very hard",

        Timeline = {
            { high, high, high },
            { high, high, high },
            { ultra, ultra },
            {},
            { epic, epic },
        },

        Loot = defaultLoot,
    },
    {
        Name = "ultra",

        Timeline = {
            { ultra },
            { ultra, ultra },
            {},
            { ultra, ultra },
        },

        Loot = defaultLoot,
    },
    {
        Name = "epic",

        Timeline = {
            { epic },
            {},
            { epic, epic },
        },

        Loot = defaultLoot,
    },
    {
        Name = "legendary",

        Timeline = {
            { legendary },
        },

        Loot = defaultLoot,
    },
    {
        Name = "impossible",

        Timeline = {
            { legendary, legendary, legendary },
            {},
            { legendary, legendary },
            {},
            { legendary },
        },

        Loot = defaultLoot,
    },
}
