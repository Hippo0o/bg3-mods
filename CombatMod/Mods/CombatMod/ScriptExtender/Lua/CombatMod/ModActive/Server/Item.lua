local weapons = nil
local armor = nil
local objects = nil
local function loadItems()
    weapons = Ext.Stats.GetStats("Weapon")
    armor = Ext.Stats.GetStats("Armor")
    objects = Ext.Stats.GetStats("Object")

    L.Debug("Item lists loaded.", #objects, #armor, #weapons)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Item : Struct
---@field Name string
---@field Type string
---@field RootTemplate string
---@field Rarity string
---@field GUID string|nil
---@field Slot string|nil
---@field Mod table
local Object = Libs.Struct({
    Name = nil,
    Type = nil,
    RootTemplate = "",
    Rarity = C.ItemRarity[1],
    GUID = nil,
    Slot = nil,
    Tab = nil,
    Mod = {},
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
        o.Tab = item.InventoryTab

        if type == "Armor" or type == "Weapon" then
            o.Slot = item.Slot
        end
        if type == "Object" or type == "CombatObject" then
            o.Slot = item.ItemUseType
        end

        local mod = Ext.Mod.GetMod(item.ModId)
        local modName = "Invalid Mod UUID"
        if mod then
            modName = mod.Info.Directory
        end

        o.Mod = { item.ModId, modName }
    end

    o.GUID = nil

    return o
end

function Object:ModifyTemplate()
    local template = self:GetTemplate()

    if template.Stats ~= self.Name then
        Event.Trigger("TemplateOverwrite", self.RootTemplate, "Stats", self.Name)
    end
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

    self:ModifyTemplate()

    x, y, z = Osi.FindValidPosition(x, y, z, 100, C.NPCCharacters.Volo, 1)
    if not x or not y or not z then
        L.Error("Failed to find valid position for: ", self.Name)
        return false
    end

    self.GUID = Osi.CreateAt(self.RootTemplate, x, y, z, 0, 1, "")

    if self:IsSpawned() then
        PersistentVars.SpawnedItems[self.GUID] = self

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
        return Osi.IsItem(guid) ~= 1
    end, { immediate = true }):After(function()
        PersistentVars.SpawnedItems[guid] = nil
    end):Catch(function()
        L.Error("Failed to delete item: ", guid, self.Name)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Item.Create(name, type, rootTemplate, rarity)
    local item = Object.New(name, type, true)
    item.RootTemplate = rootTemplate
    item.Rarity = rarity

    return item
end

local itemCache = {
    Objects = {},
    Armor = {},
    Weapons = {},
    CombatObjects = {},
    ModList = nil,
}

function Item.ClearCache()
    itemCache = {
        Objects = {},
        Armor = {},
        Weapons = {},
        CombatObjects = {},
        ModList = nil,
    }
end

function Item.Get(items, type, rarity)
    return table.map(items, function(name)
        local item = Object.New(name, type)

        if rarity == nil or item.Rarity == rarity then
            return item
        end
    end)
end

function Item.Objects(rarity, forCombat)
    local cacheKey = forCombat and "CombatObjects" or "Objects"
    local type = forCombat and "CombatObject" or "Object"

    if #itemCache[cacheKey] > 0 then
        return Item.Get(itemCache[cacheKey], type, rarity)
    end

    if objects == nil then
        loadItems()
    end

    local itemFilters = External.Templates.GetItemFilters()

    local items = table.filter(objects, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end
        local cat = stat.ObjectCategory
        local tab = stat.InventoryTab
        local type = stat.ItemUseType

        if string.contains(stat.ModId, itemFilters.Mods, true, true) then
            return false
        end

        if string.contains(name, itemFilters.Names, true) then
            return false
        end

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
                    ((cat:match("^Food") or cat:match("^Drink")) and name:match("^CONS_"))
                    -- or cat:match("^Drink")
                    -- alchemy items
                    or name:match("^ALCH_Ingredient")
                )
            then
                return false
            end
        end

        local temp = Ext.Template.GetTemplate(stat.RootTemplate)
        if not temp or temp.Name:match("DONOTUSE$") then
            return false
        end

        local a = Ext.Stats.TreasureCategory.GetLegacy("I_" .. name)
        local b = Ext.Stats.TreasureCategory.GetLegacy("I_" .. temp.Name)
        local c = false
        for _, v in pairs(string.split(stat.ObjectCategory, ";")) do
            c = Ext.Stats.TreasureCategory.GetLegacy(v)
            if c then
                break
            end
        end
        if not a and not b and not c then
            return false
        end

        return true
    end)

    itemCache[cacheKey] = items

    return Item.Get(items, type, rarity)
end

function Item.Armor(rarity)
    if #itemCache.Armor > 0 then
        return Item.Get(itemCache.Armor, "Armor", rarity)
    end

    if armor == nil then
        loadItems()
    end

    local itemFilters = External.Templates.GetItemFilters()

    local items = table.filter(armor, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end
        local slot = stat.Slot

        if string.contains(stat.ModId, itemFilters.Mods, true, true) then
            return false
        end

        if string.contains(name, itemFilters.Names, true) then
            return false
        end

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

        -- doesnt exist iirc
        if stat.UseConditions ~= "" then
            return false
        end

        local temp = Ext.Template.GetTemplate(stat.RootTemplate)
        if not temp or temp.Name:match("DONOTUSE$") then
            return false
        end

        return true
    end)

    itemCache.Armors = items

    return Item.Get(items, "Armor", rarity)
end

function Item.Weapons(rarity)
    if #itemCache.Weapons > 0 then
        return Item.Get(itemCache.Weapons, "Weapon", rarity)
    end

    if weapons == nil then
        loadItems()
    end

    local itemFilters = External.Templates.GetItemFilters()

    local items = table.filter(weapons, function(name)
        local stat = Ext.Stats.Get(name)
        if not stat then
            return false
        end

        if string.contains(stat.ModId, itemFilters.Mods, true, true) then
            return false
        end

        if string.contains(name, itemFilters.Names, true) then
            return false
        end

        if name:match("^_") then
            return false
        end

        if stat.Rarity == "" or stat.RootTemplate == "" then
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

        return true
    end)

    itemCache.Weapons = items

    return Item.Get(items, "Weapon", rarity)
end

-- not used
function Item.Cleanup()
    for guid, item in pairs(PersistentVars.SpawnedItems) do
        Object.Init(item):Clear()
    end
end

function Item.DestroyAll(rarity, type)
    local count = 0
    for guid, item in pairs(PersistentVars.SpawnedItems) do
        if item.Rarity == rarity and not GU.Object.IsOwned(item.GUID) and (not type or item.Type == type) then
            Object.Init(item):Clear()
            count = count + 1
        end
    end

    return count
end

function Item.PickupAll(character, rarity, type)
    local count = 0

    for _, item in pairs(PersistentVars.SpawnedItems) do
        if
            not GU.Object.IsOwned(item.GUID)
            and (type == nil or item.Type == type)
            and (rarity == nil or item.Rarity == rarity)
        then
            Osi.ToInventory(item.GUID, GC.GetPlayer(character))
            count = count + 1
            Schedule(function()
                if GU.Object.IsOwned(item.GUID) or Osi.IsItem(item.GUID) ~= 1 then
                    PersistentVars.SpawnedItems[item.GUID] = nil
                end
            end)
        end
    end

    return count
end

function Item.PickupLoot(character)
    for type, data in pairs(PersistentVars.LootFilter) do
        for rarity, pickup in pairs(data) do
            if pickup then
                Item.PickupAll(character or Player.Host(), rarity, type)
            else
                Item.DestroyAll(rarity, type)
            end
        end
    end
end

function Item.SpawnLoot(loot, x, y, z, autoPickup)
    local i = 0
    local pingedLoot = {}
    for _, item in pairs(loot) do
        if item.Type ~= "Object" then
            table.insert(pingedLoot, item)
        else
            item:Spawn(x, y, z)
        end
    end

    if #pingedLoot == 0 then
        return
    end

    Async.Interval(300 - (#pingedLoot * 2), function(self)
        i = i + 1

        if i > #pingedLoot then
            self:Clear()
            if autoPickup and Player.InCamp() then
                Item.PickupLoot()
            end

            return
        end

        if pingedLoot[i] == nil then
            L.Error("Loot was empty.", i, #pingedLoot)
            return
        end

        local x2 = x + math.random() * math.random(-1, 1)
        local z2 = z + math.random() * math.random(-1, 1)
        local item = pingedLoot[i]

        if item:Spawn(x2, y, z2) then
            Osi.RequestPing(x2, y, z2, item.GUID, "")
        end
    end)
end

function Item.GenerateSimpleLoot(rolls, chanceFood, lootRates)
    local loot = {}

    if not lootRates then
        lootRates = C.LootRates
    end

    rolls = rolls or 1

    chanceFood = chanceFood or 0.5

    for i = 1, rolls do
        local items = Item.Objects(nil, false)

        local isFood = math.random() < chanceFood

        items = table.filter(items, function(item)
            if isFood then
                return item.Tab == "Consumable"
            else
                return item.Tab ~= "Consumable"
            end
        end)

        L.Debug("Rolling kill loot items:", #items, "Object")
        if #items > 0 then
            table.insert(loot, table.deepclone(items[math.random(#items)]))
        end
    end

    return table.deepclone(loot)
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
    local rarities = {}
    for _, category in ipairs({ "CombatObject", "Weapon", "Armor" }) do
        local rarity = {}

        for _, r in ipairs(C.ItemRarity) do
            if category == "CombatObject" and lootRates.Objects[r] then
                add(rarity, r, lootRates.Objects[r])
            elseif category == "Weapon" and lootRates.Weapons[r] then
                add(rarity, r, lootRates.Weapons[r])
            elseif category == "Armor" and lootRates.Armor[r] then
                add(rarity, r, lootRates.Armor[r])
            end
        end

        rarities[category] = rarity
    end

    local lastCategory = nil
    local function rollCategory()
        return ({ "CombatObject", "CombatObject", "Weapon", "Armor", "Weapon", "Armor", "Armor" })[math.random(7)]
    end

    for i = 1, rolls do
        local items = {}
        local fail = 0

        local rarity = nil
        -- avoid 0 rolls e.g. legendary objects dont exist
        while #items == 0 and fail < 10 do
            fail = fail + 1

            local category = rollCategory()
            if category == lastCategory then
                category = rollCategory()
            end
            lastCategory = category

            rarity = rarities[category][math.random(#rarities[category])]

            if category == "CombatObject" then
                items = Item.Objects(rarity, true)
                if #items > 0 then
                    local bySlot = UT.GroupBy(items, "Slot")
                    local slots = table.keys(bySlot)
                    local randomSlot = slots[math.random(#slots)]
                    L.Debug("Rolling CombatObject loot slot:", randomSlot, rarity)

                    if randomSlot == "Potion" and math.random() < 0.40 then
                        items = table.filter(items, function(item)
                            return item.Name:match("^OBJ_Potion_Healing")
                        end)
                    else
                        items = table.values(bySlot[randomSlot])
                    end
                end
            elseif category == "Weapon" then
                items = Item.Weapons(rarity)
            elseif category == "Armor" then
                items = Item.Armor(rarity)
                if #items > 0 then
                    local bySlot = UT.GroupBy(items, "Slot")
                    local slots = table.keys(bySlot)
                    local randomSlot = slots[math.random(#slots)]
                    L.Debug("Rolling Armor loot slot:", randomSlot, rarity)
                    items = table.values(bySlot[randomSlot])
                end
            end

            L.Debug("Rolling bonus loot items:", #items, category, rarity)
        end

        if #items > 0 then
            local random = items[math.random(#items)]

            if table.contains(PersistentVars.RandomLog.Items, random.Name) then
                random = items[math.random(#items)]
            end
            LogRandom("Items", random.Name, 100)

            table.insert(loot, table.deepclone(random))
        end
    end

    return table.deepclone(loot)
end

function Item.GetModList()
    if itemCache.ModList then
        return itemCache.ModList
    end

    local mods = {}

    for _, l in ipairs({ Item.Armor(), Item.Weapons(), Item.Objects(nil, false), Item.Objects(nil, true) }) do
        for _, item in ipairs(l) do
            if item.Mod[1] then
                mods[item.Mod[1]] = item.Mod[2]
            end
        end
    end

    itemCache.ModList = mods

    return mods
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.OnUnload(Item.ClearCache)

Ext.Osiris.RegisterListener(
    "RequestCanPickup",
    3,
    "after",
    Throttle( -- avoid recursion
        10,
        function(character, object, requestID)
            if GC.IsNonPlayer(character, true) then
                return
            end

            local item = table.find(PersistentVars.SpawnedItems, function(item)
                return U.UUID.Equals(item.GUID, object)
            end)

            if item then
                L.Debug("Auto pickup:", object, character)
                Item.PickupAll(character, item.Rarity, item.Type)
            end
        end
    )
)

Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "after", function(uuid)
    if U.UUID.Equals(uuid, Player.Host()) then
        Item.PickupLoot()
    end
end)
Event.On("ReturnToCamp", Item.PickupLoot)

Event.On("ScenarioEnemyKilled", function(scenario, enemy)
    local nr = #scenario.KilledEnemies

    local chanceFood = 1
    if nr <= 6 then
        chanceFood = 0.9
    else
        chanceFood = math.max(1, 10 - nr) / 10
    end

    if PersistentVars.Unlocked.LootMultiplier then
        rolls = nr % 2 == 0 and 2 or 1
    end

    local loot = Item.GenerateSimpleLoot(rolls, chanceFood, scenario.LootRates)

    local x, y, z = Osi.GetPosition(enemy.GUID)

    Item.SpawnLoot(loot, x, y, z)
end)

Event.On(
    "ScenarioEnded",
    Async.Wrap(function(scenario)
        Player.Notify(__("Dropping loot."), true)

        local lootMultiplier = 1
        if PersistentVars.Unlocked.LootMultiplier then
            lootMultiplier = 1.5
        end

        local rolls = math.floor(scenario:KillScore() * lootMultiplier)

        local function rollsToChunks()
            local size = 20
            local chunks = {}

            for i = 1, math.floor(rolls / size) do
                table.insert(chunks, size)
            end

            local mod = rolls % size
            if mod > 0 then
                table.insert(chunks, mod)
            end

            return chunks
        end

        local results = {
            Async.SyncAll(table.map(rollsToChunks(), function(chunk)
                return Defer(100, U.Bind(Item.GenerateLoot, chunk, scenario.LootRates))
            end)),
        }

        local loot = {}
        for _, r in ipairs(results) do
            table.extend(loot, r[1])
        end

        L.Dump("Loot", loot, scenario.LootRates, rolls, #loot)

        local map = scenario.Map
        local x, y, z = map.Enter[1], map.Enter[2], map.Enter[3]
        if Config.SpawnItemsAtPlayer then
            x, y, z = Player.Pos()
        end

        Item.SpawnLoot(loot, x, y, z, true)
    end)
)
