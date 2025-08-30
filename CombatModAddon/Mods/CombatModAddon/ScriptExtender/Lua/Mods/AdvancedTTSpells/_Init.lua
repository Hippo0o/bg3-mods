-- ModUUID = "fa49db03-caa7-49c8-7c76-e6c38b60267a"

local External = Mods.ToT.External
local UT = Mods.ToT.UT

local function ReplaceEnemies()
    local customEnemies = Require("Mods/AdvancedTTSpells/Templates/Enemies.lua")
    -- first approach
    -- force export our list to overwrite existing file
    -- is not needed if second approach overwrites templates at runtime
    External.File.Export("Enemies", customEnemies)
    -- second approach
    UT.Each(customEnemies, External.Templates.AddEnemy)
    -- bcs we replace existing enemies too, we need to filter here
    local reg = UT.Invert(customEnemies)
    External.Templates.PatchEnemies(function(e)
        return reg[e] and e or nil
    end)
end

local function ReplaceUnlocks()
    local customUnlocks = Require("Mods/AdvancedTTSpells/Templates/Unlocks.lua")
    UT.Each(customUnlocks, External.Templates.AddUnlock)
    -- bcs we replace all unlocks, we need to filter here
    local reg = UT.Invert(customEnemies)
    External.Templates.PatchUnlocks(function(u)
        return reg[u] and u or nil
    end)
end

local function ExtendItemFilter()
    local itemFilter = Require("Mods/AdvancedTTSpells/Templates/ItemBlacklist.lua")
    External.Templates.AddItemFilter({ Names = itemFilter })
end

local function RegisterLoneWolfMode()
    local GameMode = Mods.ToT.GameMode
    -- special list of enemy templates for LoneWolf mode
    local templates = Require("Mods/AdvancedTTSpells/Templates/LoneWolfEnemies.lua")

    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(self)
            GameMode.StartRoguelike(self)
        end,

        Name = Mods.ToT.C.RoguelikeScenario .. " (LoneWolf)",
        Map = GameMode.GetRandomMap,

        Enemies = function(self)
            return GameMode.GetFilteredEnemies(self._Timeline, templates)
        end,

        -- Spawns per Round
        _Timeline = nil,
        Timeline = function(self)
            self._Timeline = GameMode.GenerateTimeline(0)
            return self._Timeline
        end,
    })
end

ReplaceEnemies()
ExtendItemFilter()
RegisterLoneWolfMode()
