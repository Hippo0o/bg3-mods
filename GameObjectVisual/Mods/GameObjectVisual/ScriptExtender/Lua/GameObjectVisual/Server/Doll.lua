---@class Doll
Doll = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class DollStruct : Struct
---@field Uuid string
---@field BodyType number 0|1 (Male,Female)
---@field BodyShape number 0|1 (Normal,Strong)
---@field Race string
local Struct = Libs.Struct({
    Uuid = nil,
    BodyType = nil,
    BodyShape = nil,
    Race = nil,
})

function Struct:Visuals()
    return Ext.Entity.Get(self.Uuid).CharacterCreationAppearance.Visuals
end

---@param visual VisualStruct
function Struct:ApplyVisual(visual)
    Osi.AddCustomVisualOverride(self.Uuid, visual.Uuid)
end

---@param visual VisualStruct
function Struct:RemoveVisual(visual)
    Osi.RemoveCustomVisualOvirride(self.Uuid, visual.Uuid)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param entity EntityHandle
---@return ResourceCharacterCreationPreset[]
function Doll.CreationPresets(entity)
    local subRace = entity.Race.Race
    -- local rootTemplate = entity.GameObjectVisual.RootTemplateId

    return Preset.GetForRace(subRace)
end

---@param character string
---@return DollStruct
function Doll.Build(character)
    local entity = Ext.Entity.Get(character)

    local bodyType = entity.BodyType.BodyType

    local shape = entity.CharacterCreationStats and entity.CharacterCreationStats.BodyShape
        or C.DollParts.BODYSHAPE.NORMAL

    local race = entity.CharacterCreationStats and entity.CharacterCreationStats.Race or C.DollParts.RACES.HUMAN

    if U.UUID.Equals(character, C.OriginCharactersSpecial.Halsin) then
        race = C.DollParts.RACES.HUMAN
    end

    return Struct.Init({
        Uuid = entity.Uuid.EntityUuid,
        BodyType = bodyType,
        BodyShape = shape,
        Race = race,
    })
end

---@param character string
---@param restrictRace boolean
---@return table<VisualSlots, VisualStruct[]>
function Doll.Visuals(doll, restrictRace)
    local bySlot = {}

    for _, slot in pairs(C.VisualSlots) do
        ---@type VisualStruct[]
        local visuals =
            UT.Extend({}, Visual.GetSlot(slot, C.VisualTypes.CCAV), Visual.GetSlot(slot, C.VisualTypes.CCSV))

        bySlot[slot] = UT.Filter(visuals, function(visual)
            visual:FillFromDoll(doll)
            local bt = visual.BodyType
            local bs = visual.BodyShape
            local race = visual.Race

            return (not bt or bt == doll.BodyType)
                and (not bs or bs == doll.BodyShape)
                and (not restrictRace or not race or race == doll.Race)
        end)
    end

    return bySlot
end

function Doll.ApplyVisualSlot(character, slot, visual)
    local doll = Doll.Build(character)
    local visuals = Doll.Visuals(doll, false)[slot]

    for _, v in pairs(visuals) do
        for _, uuid in pairs(doll:Visuals()) do
            if uuid == v.Uuid then
                doll:RemoveVisual(v)
                break
            end
        end
    end

    for _, v in pairs(visuals) do
        if v.Uuid == visual then
            doll:ApplyVisual(v)
        end
    end
end
