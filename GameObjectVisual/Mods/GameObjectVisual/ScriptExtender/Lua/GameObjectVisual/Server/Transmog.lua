---@class Transmog
Transmog = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class TransmogStruct
local Struct = Libs.Class({
    Uuid = nil,
    Slot = nil,
    DisplayName = nil,
    Name = nil,
    Icon = nil,
})

function Struct:Equip(character)
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

local cached

function Transmog.ClearCache()
    cached = nil
end

function Transmog.LoadCache()
    local eq = UT.Map(Ext.Stats.GetStats("Armor"), function(name)
        local stats = Ext.Stats.Get(name)
        local template = Ext.Template.GetRootTemplate(stats.RootTemplate)
        if not template then
            return
        end

        local displayName = Ext.Loca.GetTranslatedString(template.DisplayName.Handle.Handle)

        return Struct.Init({
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

function Transmog.GetSlots()
    if not cached then
        Transmog.LoadCache()
    end

    return UT.Keys(cached)
end

function Transmog.GetArmor(slot)
    if not cached then
        Transmog.LoadCache()
    end

    return slot and cached[slot] or cached
end
