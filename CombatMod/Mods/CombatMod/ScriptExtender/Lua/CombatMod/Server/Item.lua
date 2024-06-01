local weapons = nil
local armor = nil
local objects = nil
-- if Ext.Mod.IsModLoaded(C.ModUUID) then
--     weapons = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Weapon")
--     armor = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Armor")
--     objects = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Object")
-- else
    L.Debug("Mod not loaded. Using all items.")
    weapons = Ext.Stats.GetStats("Weapon")
    armor = Ext.Stats.GetStats("Armor")
    objects = Ext.Stats.GetStats("Object")
-- end

L.Debug("Item lists loaded.", #objects, #armor, #weapons)

local itemBlacklist = {
    "OBJ_FreezingSphere", -- explodes on pickup
    "MAG_OfTheShapeshifter_Mask", -- DLC mask
    "ARM_Breastplate_Body_Githyanki", -- template invalid
    "LOW_RamazithsTower_Nightsong_Silver_Shield", -- %%% in name
    "TWN_TollCollector_", -- useless
    "WPN_KingsKnife", -- its common bro
    "_Destroyed$", -- junk
    "_REF$", -- junk
    "CONS_FOOD_Soup_Tomato", -- invalid template
    "ARM_Vanity_Body_Shar", -- invalid template
}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Item : LibsClass
---@field Name string
---@field Type string
---@field RootTemplate string
---@field Rarity string
---@field GUID string|nil
local Object = Libs.Class({
    Name = nil,
    Type = nil,
    RootTemplate = "",
    Rarity = C.ItemRarity[1],
    GUID = nil,
})

---@param name string
---@param type string
---@param fake boolean|nil
---@return Item
function Object.New(name, type, fake)
    local o = Object.Init()

    o.Name = name
    o.Type = type

    if not fake then
        local item = Ext.Stats.Get(name)
        o.RootTemplate = item.RootTemplate
        o.Rarity = item.Rarity
    end

    o.GUID = nil

    return o
end

function Object:IsSpawned()
    return self.GUID ~= nil
end

---@param x number
---@param y number
---@param z number
---@return boolean
function Object:Spawn(x, y, z)
    if self:IsSpawned() then
        return false
    end

    x, y, z = Osi.FindValidPosition(x, y, z, 10, "", 1)

    self.GUID = Osi.CreateAt(self.RootTemplate, x, y, z, 1, 1, "")

    if self:IsSpawned() then
        PersistentVars.SpawnedItems[self.GUID] = self

        Schedule(function() -- basically a pcall
            -- if UT.Set(C.ItemRarity)[self.Rarity] > 2 then
            Osi.RequestPing(x, y, z, self.GUID, "")
            -- end
        end)
        return true
    end

    L.Error("Failed to spawn: ", self.Name)

    return false
end

function Object:Clear()
    local guid = self.GUID
    self.GUID = nil

    RetryUntil(function()
        UE.Remove(guid)
        return Osi.IsItem(guid) ~= 0
    end, { immediate = true }).After(function()
        PersistentVars.SpawnedItems[guid] = nil
    end).Catch(function()
        L.Error("Failed to delete item: ", guid, self.Name)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Item.Create(name, type, fake)
    return Object.New(name, type, fake)
end

function Item.Objects(rarity, forCombat)
    local items = UT.Filter(objects, function(name)
        local stat = Ext.Stats.Get(name)
        local cat = stat.ObjectCategory

        if name:match("^_") or name:match("^DLC_") then
            return false
        end

        if US.Contains(name, itemBlacklist) then
            return false
        end

        if stat.Rarity == "" or stat.RootTemplate == "" then
            return false
        end

        if rarity ~= nil and stat.Rarity ~= rarity then
            return false
        end

        if forCombat then
            if
                not (
                    cat:match("Arrow")
                    or cat:match("Potion")
                    or cat:match("MagicScroll")
                    or cat:match("Poison")
                    or cat:match("Throwable")
                )
            then
                return false
            end
        else
            if
                not (
                    (cat:match("^Food") and name:match("^CONS_"))
                    -- or cat:match("^Drink")
                    or cat:match("^Ingredient")
                    or cat:match("Potion")
                    -- alchemy items
                    -- or name:match("^OBJ_Crystal_")
                    or name:match("^CONS_Mushrooms_")
                    or name:match("^CONS_Herbs_")
                    or name:match("^BOOK_Alchemy_") -- TODO add books and such
                )
            then
                return false
            end
        end

        return true
    end)

    return UT.Map(items, function(name)
        return Object.New(name, "Object")
    end)
end

function Item.Armor(rarity)
    local items = UT.Filter(armor, function(name)
        local stat = Ext.Stats.Get(name)
        local slot = stat.Slot

        if name:match("^_") or name:match("^DLC_") then
            return false
        end

        if US.Contains(name, itemBlacklist) then
            return false
        end

        if
            not Config.LootIncludesCampSlot
            and (slot:match("VanityBody") or slot:match("VanityBoots") or slot:match("Underwear"))
        then
            return false
        end

        if stat.Rarity == "" or stat.RootTemplate == "" then
            return false
        end

        if rarity ~= nil and stat.Rarity ~= rarity then
            return false
        end

        -- doesnt exist iirc
        if stat.UseConditions ~= "" then
            return false
        end

        return true
    end)

    return UT.Map(items, function(name)
        return Object.New(name, "Armor")
    end)
end

function Item.Weapons(rarity)
    local items = UT.Filter(weapons, function(name)
        local stat = Ext.Stats.Get(name)

        if name:match("^_") or name:match("^DLC_") then
            return false
        end

        if US.Contains(name, itemBlacklist) then
            return false
        end

        if stat.Rarity == "" or stat.RootTemplate == "" then
            return false
        end

        if rarity ~= nil and stat.Rarity ~= rarity then
            return false
        end

        -- weapons that can't be used by players
        if stat.UseConditions ~= "" then
            return false
        end

        return true
    end)

    return UT.Map(items, function(name)
        return Object.New(name, "Weapon")
    end)
end

function Item.IsOwned(obj)
    return Osi.IsInInventory(obj) == 1
        or Osi.GetInventoryOwner(obj) ~= nil
        or Osi.GetFirstInventoryOwnerCharacter(obj) ~= nil
end

-- not used
function Item.Cleanup()
    for guid, item in pairs(PersistentVars.SpawnedItems) do
        Object.Init(item):Clear()
    end
end

function Item.DestroyAll(rarity, type)
    for guid, item in pairs(PersistentVars.SpawnedItems) do
        if item.Rarity == rarity and not Item.IsOwned(item.GUID) and item.Type == type then
            UE.Remove(guid)
            PersistentVars.SpawnedItems[guid] = nil
        end
    end
end

function Item.PickupAll(character, rarity, type)
    for _, item in pairs(PersistentVars.SpawnedItems) do
        if
            not Item.IsOwned(item.GUID)
            and (type == nil or item.Type == type)
            and (rarity == nil or item.Rarity == rarity)
        then
            Osi.ToInventory(item.GUID, character)
            Schedule(function()
                if Item.IsOwned(item.GUID) then
                    PersistentVars.SpawnedItems[item.GUID] = nil
                end
            end)
        end
    end
end

function Item.SpawnLoot(loot, x, y, z)
    local i = 0
    Async.Interval(300 - (#loot * 2), function(self)
        i = i + 1

        if i > #loot then
            self:Clear()

            return
        end

        if loot[i] == nil then
            L.Error("Loot was empty.", i, #loot)
            return
        end

        local x2 = x + U.Random() * U.Random(-1, 1)
        local z2 = z + U.Random() * U.Random(-1, 1)

        loot[i]:Spawn(x2, y, z2)
    end)
end

function Item.GenerateLoot(rolls, lootRates)
    local loot = {}

    -- each kill gets an object/weapon/armor roll
    -- TODO drop gold
    if not lootRates then
        lootRates = C.LootRates
    end

    local function add(t, rarity, amount)
        for i = 1, amount do
            table.insert(t, rarity)
        end

        return t
    end

    -- build rarity roll tables from template e.g. { "Common", "Common", "Uncommon", "Rare" }
    -- if rarity is 0 it will be at least added once
    -- if rarity is not defined it will not be added
    local fixed = {}
    local sum = 0
    for _, r in ipairs(C.ItemRarity) do
        if lootRates.Objects[r] then
            local rate = lootRates.Objects[r]
            sum = sum + rate
            add(fixed, r, rate)
        end
        add(fixed, "Nothing", math.ceil(sum / 4)) -- make a chance to get nothing
    end

    local bonusRarities = {}
    for _, bonusCategory in ipairs({ "Object", "Weapon", "Armor" }) do
        local bonus = {}
        add(bonus, "Nothing", 10) -- make a chance to get nothing

        for _, r in ipairs(C.ItemRarity) do
            if bonusCategory == "Object" and lootRates.Objects[r] then
                add(bonus, r, lootRates.Objects[r])
            elseif bonusCategory == "Weapon" and lootRates.Weapons[r] then
                add(bonus, r, lootRates.Weapons[r])
            elseif bonusCategory == "Armor" and lootRates.Armor[r] then
                add(bonus, r, lootRates.Armor[r])
            end
        end

        bonusRarities[bonusCategory] = bonus
    end

    for i = 1, rolls do
        do
            local rarity = fixed[U.Random(#fixed)]
            local items = Item.Objects(rarity, false)

            L.Debug("Rolling fixed loot items:", #items, "Object", rarity)
            if #items > 0 then
                table.insert(loot, items[U.Random(#items)])
            end
        end

        local items = {}
        local fail = 0
        local bonusCategory = ({ "Object", "Weapon", "Armor" })[U.Random(3)]
        local rarity = nil
        -- avoid 0 rolls e.g. legendary objects dont exist
        while #items == 0 and fail < 3 do
            fail = fail + 1

            rarity = bonusRarities[bonusCategory][U.Random(#bonusRarities[bonusCategory])]

            if bonusCategory == "Object" then
                items = Item.Objects(rarity, true)
            elseif bonusCategory == "Weapon" then
                items = Item.Weapons(rarity)
            elseif bonusCategory == "Armor" then
                items = Item.Armor(rarity)
            end
        end

        L.Debug("Rolling bonus loot items:", #items, bonusCategory, rarity)
        if #items > 0 then
            table.insert(loot, items[U.Random(#items)])
        end
    end

    return loot
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

U.Osiris.On(
    "RequestCanPickup",
    3,
    "after",
    Async.Throttle( -- avoid recursion
        10,
        IfActive(function(character, object, requestID)
            if UE.IsNonPlayer(character, true) then
                return
            end

            local item = UT.Find(PersistentVars.SpawnedItems, function(item)
                return U.UUID.Equals(item.GUID, object)
            end)

            if item then
                L.Debug("Auto pickup:", object, character)
                Player.PickupAll()
            end
        end)
    )
)
