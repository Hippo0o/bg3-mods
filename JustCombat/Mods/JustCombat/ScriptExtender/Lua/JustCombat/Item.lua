---@diagnostic disable: undefined-global

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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Item : LibsObject
---@field Name string
---@field Type string
---@field RootTemplate string
---@field Rarity string
---@field GUID string|nil
local Object = Libs.Object({
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

    local target = Osi.GetClosestAlivePlayer(Player.Host())
    local radius = 3
    local avoidDangerousSurfaces = 1
    x, y, z = Osi.FindValidPosition(x, y, z, radius, target, avoidDangerousSurfaces)

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

    RetryFor(function()
        UE.Remove(guid)
        return Osi.IsItem(guid) == 0
    end, {
        success = function()
            PersistentVars.SpawnedItems[guid] = nil
        end,
        failed = function()
            L.Error("Failed to delete item: ", guid, self.Name)
        end,
        immediate = true,
    })
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

        if name:match("^DLC_") then
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
                    cat:match("^Food")
                    or cat:match("^Drink")
                    or cat:match("^Ingredient")
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

        if stat.Rarity == "" or stat.RootTemplate == "" then
            return false
        end

        if rarity ~= nil and stat.Rarity ~= rarity then
            return false
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
        if
            not Config.LootItemsIncludeClothes
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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener(
    "AddedTo",
    3,
    "before",
    Async.Throttle(1000, function(object, inventoryHolder, addType) -- avoid recursion
        if addType ~= "Regular" or UE.IsNonPlayer(inventoryHolder, true) then
            return
        end

        local items = UT.Map(PersistentVars.SpawnedItems, function(item)
            return U.UUID.GetGUID(item.GUID)
        end)

        if UT.Contains(items, U.UUID.GetGUID(object)) then
            L.Debug("Auto pickup:", object, inventoryHolder)
            for _, item in ipairs(items) do
                if not Item.IsOwned(item) then
                    Osi.ToInventory(item, inventoryHolder)
                    Schedule(function()
                        if Item.IsOwned(item) then
                            PersistentVars.SpawnedItems[item] = nil
                        end
                    end)
                end
            end
        end
    end)
)
