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
    External.Templates.PatchEnemies(function(e)
        return UT.Contains(customEnemies, e) and e or nil
    end)
end

local function ReplaceUnlocks()
    local customUnlocks = Require("Mods/AdvancedTTSpells/Templates/Unlocks.lua")
    UT.Each(customUnlocks, External.Templates.AddUnlock)
    -- bcs we replace all unlocks, we need to filter here
    External.Templates.PatchUnlocks(function(u)
        return UT.Contains(customUnlocks, u) and u or nil
    end)
end

local function ExtendItemFilter()
    local itemFilter = Require("Mods/AdvancedTTSpells/Templates/ItemBlacklist.lua")
    External.Templates.AddItemFilter({ Names = itemFilter })
end

ReplaceEnemies()
ExtendItemFilter()
