local tt = Libs.TypedTable

External.Validators = {}

External.Validators.Config = tt({
    CombatWorkaround = { "boolean" },
    ForceEnterCombat = { "boolean" },
    BypassStory = { "boolean" },
    BypassStoryAlways = { "boolean" },
    ItemsIncludeClothes = { "boolean" },
})

External.Validators.Enemy = tt({
    Name = { "string" },
    TemplateId = { U.UUID.IsGUID },
    Tier = { C.EnemyTier },
    IsBoss = { "boolean", "nil" },
    LevelOverride = { "number", "nil" },
    Equipment = { "string", "nil" },
    Stats = { "string", "nil" },
    SpellSet = { "string", "nil" },
    AiHint = { "nil", U.UUID.IsGUID },
    Archetype = { "string", "nil" },
    CharacterVisualResourceID = { "nil", U.UUID.IsGUID },
    Icon = { "string", "nil" },
})

local posType = tt({
    { "number" }, -- x
    { "number" }, -- y
    { "number" }, -- z
})

External.Validators.Map = tt({
    Region = { "string" },
    Enter = { posType },
    Spawns = tt(posType, true),
})

External.Validators.Scenario = tt({
    Name = { "string" },
    Timeline = tt({
        tt({
            { C.EnemyTier, "nil" },
        }, true),
    }, true),
    Loot = tt({
        Objects = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
        Armor = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
        Weapons = tt({
            Common = { "nil", "number" },
            Uncommon = { "nil", "number" },
            Rare = { "nil", "number" },
            VeryRare = { "nil", "number" },
            Legendary = { "nil", "number" },
        }),
    }),
})


