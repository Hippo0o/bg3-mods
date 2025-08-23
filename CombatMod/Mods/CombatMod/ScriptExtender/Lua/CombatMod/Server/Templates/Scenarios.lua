local low, medium, high, ultra, epic, legendary, mythical, divine =
    C.EnemyTier[1], C.EnemyTier[2], C.EnemyTier[3], C.EnemyTier[4], C.EnemyTier[5], C.EnemyTier[6], C.EnemyTier[7], C.EnemyTier[8]

local defaultLoot = C.LootRates

return {
    {
        Name = "level 1",

        -- Spawns per Round
        Timeline = {
            { low },
            { low },
            { low },
        },

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
    },
    {
        Name = "ultra",

        Timeline = {
            { ultra },
            { ultra, ultra },
            {},
            { ultra, ultra },
        },
    },
    {
        Name = "epic",

        Timeline = {
            { epic },
            {},
            { epic, epic },
        },
    },
    {
        Name = "legendary",

        Timeline = {
            { legendary },
        },
    },
    {
        Name = "impossible",

        Timeline = {
            { legendary, legendary, legendary },
            {},
            { legendary, legendary },
            {},
            { mythical },
        },
    },
    {
        Name = "demigods",

        Timeline = {
            { legendary, legendary, legendary },
            {},
            { mythical, mythical },
            {},
            { divine },
        },
    }
}
