local healthMap = {}

local function snapHealth(character)
    local entity = Ext.Entity.Get(character)

    healthMap[entity.Uuid.EntityUuid] = entity.Health
end

local characters = {}

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(character, combatGuid)
    if Osi.IsPlayer(character) == 1 then
        return
    end

    snapHealth(character)
    characters[character] = true
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    if Osi.IsPlayer(character) ~= 1 then
        return
    end

    for character, _ in pairs(characters) do
        snapHealth(character)
    end
end)

Ext.Entity.Subscribe("Health", function(entity)
    if not entity.IsCharacter or entity.PartyMember then
        return
    end

    local uuid = entity.Uuid.EntityUuid

    if healthMap[uuid] == nil then
        return
    end
end)
