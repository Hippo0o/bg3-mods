local weapons = nil
local armor = nil
local objects = nil
if Ext.Mod.IsModLoaded(C.ModUUID) then
    weapons = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Weapon")
    armor = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Armor")
    objects = Ext.Stats.GetStatsLoadedBefore(C.ModUUID, "Object")
else
    L.Debug("Mod not loaded. Using all items.")
    weapons = Ext.Stats.GetStats("Weapon")
    armor = Ext.Stats.GetStats("Armor")
    objects = Ext.Stats.GetStats("Object")
end

L.Debug("Item lists loaded.", #objects, #armor, #weapons)

local itemBlacklist = {
    "^DLC_", -- DLC items
    "OBJ_BloodPotion_", -- we ain't roleplaying
    "GLO_", -- useless
    "OBJ_FreezingSphere", -- explodes on pickup
    "LOW_DeadMansSwitch_Shield", -- a bomb
    "MAG_OfTheShapeshifter_Mask", -- DLC mask
    "ARM_Breastplate_Body_Githyanki", -- invalid template
    "LOW_RamazithsTower_Nightsong_Silver_Shield", -- %%% in name
    "TWN_TollCollector_", -- useless
    "WPN_KingsKnife", -- its common bro, should be very rare
    "_Destroyed$", -- junk
    "_REF$", -- junk
    "^Quest_", -- junk
    "OBJ_Bomb_Orthon",
    "CONS_FOOD_Soup_Tomato", -- invalid template
    "ARM_Vanity_Body_Shar", -- invalid template
    "WPN_LightCrossbow_Makeshift", -- broken model
    "MAG_TheClover_Scimitar", -- unfinished dupe of existing
    "DEN_VoloOperation_ErsatzEye", -- vololo
    "SHA_SharSpear", -- shar does not give us permission
    "MAG_Cunning_HandCrossbow", -- does not work
    "LOW_OskarsBeloved_",
    "WPN_Dart", -- unfinished
    "WPN_Sling", -- unfinished
    "MAG_Harpers_SingingSword", -- unfinished
    -- "_Myrmidon_ConjureElemental$",
    -- "_Myrmidon_WildShape$",
    "_AnimateDead$",
    "_Pact$",
    "_FlameBlade",
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
---@field Slot string|nil
local Object = Libs.Class({
    Name = nil,
    Type = nil,
    RootTemplate = "",
    Rarity = C.ItemRarity[1],
    GUID = nil,
    Slot = nil,
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
        if type == "Armor" or type == "Weapon" then
            o.Slot = item.Slot
        end
        if type == "Object" then
            o.Slot = item.InventoryTab
        end
    end

    o.GUID = nil

    return o
end

function Object:IsSpawned()
    return self.GUID ~= nil
end

function Object:GetTemplate()
    return Ext.Template.GetTemplate(self.RootTemplate)
end

function Object:GetTranslatedName()
    local handle
    if self:IsSpawned() then
        handle = Osi.GetDisplayName(self.GUID)
    else
        handle = self:GetTemplate().DisplayName.Handle.Handle
    end
    return Osi.ResolveTranslatedString(handle)
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
        GU.Object.Remove(guid)
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

local function parseEquipment()
    local e1 = Ext.IO.LoadFile("Public/Shared/Stats/Generated/Equipment.txt", "data")
    local e2 = Ext.IO.LoadFile("Public/SharedDev/Stats/Generated/Equipment.txt", "data")
    local e3 = Ext.IO.LoadFile("Public/Gustav/Stats/Generated/Equipment.txt", "data")
    local e4 = Ext.IO.LoadFile("Public/GustavDev/Stats/Generated/Equipment.txt", "data")

    local equipment = {}
    for _, eqFile in ipairs({ e1, e2, e3, e4 }) do
        if eqFile then
            local arr = US.Split(eqFile, "\n")
            for _, a in ipairs(arr) do
                local eq = a:match('equipment entry "(%S*)"')
                if eq then
                    table.insert(equipment, eq)
                end
            end
        end
    end

    return equipment
end

local cache = nil
function Item.EquipmentList()
    if cache then
        return cache
    end
    cache = parseEquipment()

    return cache
end

function Item.Create(name, type, fake)
    return Object.New(name, type, fake)
end

local itemCache = {
    Objects = {},
    Armor = {},
    Weapons = {},
    CombatObjects = {},
}

function Item.Objects(rarity, forCombat)
    local cacheKey = forCombat and "CombatObjects" or "Objects"
    if #itemCache[cacheKey] > 0 then
        return UT.Filter(itemCache[cacheKey], function(item)
            return rarity == nil or item.Rarity == rarity
        end)
    end

    local items = UT.Filter(objects, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end
        local cat = stat.ObjectCategory
        local tab = stat.InventoryTab
        local type = stat.ItemUseType

        if name:match("^_") then
            return false
        end

        if stat.Rarity == "" or stat.RootTemplate == "" then
            return false
        end

        if forCombat then
            if not (type == "Potion" or tab == "Magical") then
                return false
            end
        else
            if
                not (
                    (cat:match("^Food") and name:match("^CONS_"))
                    -- or cat:match("^Drink")
                    or cat:match("^Ingredient")
                    or cat == "PotionHealing"
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

        local temp = Ext.Template.GetTemplate(stat.RootTemplate)
        if not temp or temp.Name:match("DONOTUSE$") then
            return false
        end

        local inList = UT.Contains(Item.EquipmentList(), name)
        if not inList then
            local a = Ext.Stats.TreasureCategory.GetLegacy("I_" .. name)
            local b = Ext.Stats.TreasureCategory.GetLegacy("I_" .. temp.Name)
            local c = false

            for _, v in pairs(US.Split(stat.ObjectCategory, ";")) do
                c = Ext.Stats.TreasureCategory.GetLegacy(v)
                if c then
                    break
                end
            end

            if not a and not b and not c then
                return false
            end
        end

        if US.Contains(name, itemBlacklist, true) then
            L.Debug("Objects blacklisted", name)
            return false
        end

        return true
    end)

    itemCache[cacheKey] = UT.Map(items, function(name)
        return Object.New(name, "Object")
    end)

    return Item.Objects(rarity, forCombat)
end

function Item.Armor(rarity)
    if #itemCache.Armor > 0 then
        return UT.Filter(itemCache.Armor, function(item)
            return rarity == nil or item.Rarity == rarity
        end)
    end

    local items = UT.Filter(armor, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end
        local slot = stat.Slot

        if name:match("^_") then
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

        local temp = Ext.Template.GetTemplate(stat.RootTemplate)
        if not temp or temp.Name:match("DONOTUSE$") then
            return false
        end

        local inList = UT.Contains(Item.EquipmentList(), name)
        if not inList then
            if name:match("^ARM_") then
                local a = Ext.Stats.TreasureCategory.GetLegacy("I_" .. name)
                local b = Ext.Stats.TreasureCategory.GetLegacy("I_" .. temp.Name)

                if not a and not b then
                    return false
                end
            end
        end

        if US.Contains(name, itemBlacklist, true) then
            L.Debug("Armor blacklisted", name)
            return false
        end

        return true
    end)

    itemCache.Armor = UT.Map(items, function(name)
        return Object.New(name, "Object")
    end)

    return Item.Armor(rarity)
end

function Item.Weapons(rarity)
    if #itemCache.Weapons > 0 then
        return UT.Filter(itemCache.Weapons, function(item)
            return rarity == nil or item.Rarity == rarity
        end)
    end

    local items = UT.Filter(weapons, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end

        if name:match("^_") then
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

        local temp = Ext.Template.GetTemplate(stat.RootTemplate)
        if not temp or temp.Name:match("DONOTUSE$") then
            return false
        end

        if name:match("^WPN_") then
            local inList = UT.Contains(Item.EquipmentList(), name)
            if not inList then
                local a = Ext.Stats.TreasureCategory.GetLegacy("I_" .. name)
                local b = Ext.Stats.TreasureCategory.GetLegacy("I_" .. temp.Name)
                if not a and not b then
                    return false
                end
            end
        end

        if US.Contains(name, itemBlacklist, true) then
            L.Debug("Weapons blacklisted", name)
            return false
        end

        return true
    end)

    itemCache.Weapons = UT.Map(items, function(name)
        return Object.New(name, "Weapon")
    end)

    return Item.Weapons(rarity)
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
            GU.Object.Remove(guid)
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

function Item.SpawnLoot(loot, x, y, z, autoPickup)
    local i = 0
    Async.Interval(300 - (#loot * 2), function(self)
        i = i + 1

        if i > #loot then
            self:Clear()
            if autoPickup and Player.InCamp() then
                Player.PickupAll()
            end

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
        add(fixed, "Nothing", math.ceil(sum / 2)) -- make a chance to get nothing
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
                if #items > 0 then
                    local bySlot = UT.GroupBy(items, "Slot")
                    local slots = UT.Keys(bySlot)
                    local randomSlot = slots[U.Random(#slots)]
                    L.Debug("Rolling Armor loot slot:", randomSlot, rarity)
                    items = UT.Values(bySlot[randomSlot])
                end
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
            if GC.IsNonPlayer(character, true) then
                return
            end

            local item = UT.Find(PersistentVars.SpawnedItems, function(item)
                return U.UUID.Equals(item.GUID, object)
            end)

            if item then
                L.Debug("Auto pickup:", object, character)
                Item.PickupAll(character, item.Rarity)
            end
        end)
    )
)
