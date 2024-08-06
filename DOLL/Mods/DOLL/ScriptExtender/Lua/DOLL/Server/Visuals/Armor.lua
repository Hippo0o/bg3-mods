-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class ArmorEntry
local ArmorEntry = Libs.Class({
    Uuid = nil,
    Slot = nil,
    DisplayName = nil,
    Name = nil,
    Icon = nil,
})

function ArmorEntry:Equip(character)
    Osi.TemplateAddTo(self.Uuid, character, 1)

    Async.WaitTicks(6, function()
        local uuid = Osi.GetItemByTemplateInInventory(self.Uuid, character)
        Osi.Equip(character, uuid)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class VisualsArmor
Armor = {}

local cached

function Armor.ClearCache()
    cached = nil
end

function Armor.LoadCache()
    local eq = UT.Map(Ext.Stats.GetStats("Armor"), function(name)
        local stats = Ext.Stats.Get(name)
        local template = Ext.Template.GetRootTemplate(stats.RootTemplate)
        if not template then
            return
        end

        local displayName = Ext.Loca.GetTranslatedString(template.DisplayName.Handle.Handle)

        return ArmorEntry.Init({
            Uuid = template.Id,
            Slot = stats.Slot,
            DisplayName = displayName,
            Name = name,
            Icon = template.Icon,
        }),
            name .. "_" .. template.Id
    end)

    cached = UT.GroupBy(eq, "Slot")
end

function Armor.GetSlots()
    if not cached then
        Armor.LoadCache()
    end

    return UT.Keys(cached)
end

function Armor.GetArmor(slot)
    if not cached then
        Armor.LoadCache()
    end

    return slot and cached[slot] or cached
end
