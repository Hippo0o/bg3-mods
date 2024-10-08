---@class Visual
Visual = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class VisualStruct : Struct
---@field Uuid string
---@field SlotName VisualSlots
---@field Type VisualTypes
---@field Source ExtResourceManagerType[]
---@field BodyType number|nil
---@field BodyShape number|nil
---@field Race string|nil
---@field Icon string|nil
local Struct = Libs.Struct({
    Uuid = nil,
    SlotName = nil,
    Type = nil,
    Source = nil,
    BodyType = nil,
    BodyShape = nil,
    Race = nil,
    Icon = nil,
    DisplayName = nil,
})

function Struct:GetDisplayName()
    return Ext.Loca.GetTranslatedString(self.Source.DisplayName.Handle.Handle)
end

function Struct:GetIcon()
    local override = U.GetProperty(self.Source, "IconIdOverride")
    if override and override ~= "" then
        return override
    end

    local visualResource = U.GetProperty(self.Source, "VisualResource")
    if not visualResource then
        return
    end

    return table.concat(UT.Map({ self.BodyType, self.SlotName, visualResource }, tostring), "_")
end

---@param doll DollStruct
function Struct:FillFromDoll(doll)
    if not self.BodyType then
        self.BodyType = doll.BodyType
    end
    if not self.BodyShape then
        self.BodyShape = doll.BodyShape
    end
    self.Icon = self:GetIcon()
end

function Struct.New(data, type, uuid)
    local obj = Struct.Init({
        Uuid = uuid,
        Type = type,
        SlotName = data.SlotName,
        BodyType = U.GetProperty(data, "BodyType"),
        BodyShape = U.GetProperty(data, "BodyShape"),
        Race = U.GetProperty(data, "RaceUUID"),
        Source = data,
    })

    obj.Icon = obj:GetIcon()
    obj.DisplayName = obj:GetDisplayName()
    return obj
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param slot VisualSlots
---@param type VisualTypes
---@return StructVisual[]
function Visual.GetSlot(slot, type)
    return UT.Map(Ext.StaticData.GetAll(type), function(visual)
        local data = Ext.StaticData.Get(visual, type)

        if data.SlotName == slot then
            return Struct.New(data, type, visual)
        end
    end)
end

function Visual.GetSlots()
    local seen = {}
    UT.Each(Ext.StaticData.GetAll(C.VisualTypes.CCSV), function(visual)
        local data = Ext.StaticData.Get(visual, C.VisualTypes.CCSV)

        if data.SlotName then
            seen[data.SlotName] = true
        end
    end)
    UT.Each(Ext.StaticData.GetAll(C.VisualTypes.CCAV), function(visual)
        local data = Ext.StaticData.Get(visual, C.VisualTypes.CCAV)

        if data.SlotName then
            seen[data.SlotName] = true
        end
    end)

    return UT.Keys(seen)
end
