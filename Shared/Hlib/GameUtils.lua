---@type Mod
local Mod = Require("Hlib/Mod")

---@type Constants
local Constants = Require("Hlib/Constants")

---@type Utils
local Utils = Require("Hlib/Utils")

---@class GameUtils
local M = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                        Client/Server                                        --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Entity = {}

---@return EntityHandle[]
function M.Entity.GetParty()
    return Ext.Entity.GetAllEntitiesWithComponent("PartyMember")
end

---@return EntityHandle
function M.Entity.GetHost()
    if Ext.IsClient() then
        --- might not give the correct entity
        return Ext.Entity.GetAllEntitiesWithComponent("ClientControl")[1]
    end

    return Ext.Entity.Get(Osi.GetHostCharacter())
end

---@class EntityDistance
---@field Entity EntityHandle
---@field Guid string GUID
---@field Distance number
---@param source string GUID
---@param radius number|nil
---@param ignoreHeight boolean|nil
---@param withComponent ExtComponentType|nil
---@return EntityDistance[]
-- thanks to AtilioA/BG3-volition-cabinet
function M.Entity.GetNearby(source, radius, ignoreHeight, withComponent)
    radius = radius or 1
    withComponent = withComponent or "Uuid"

    ---@param entity string|EntityHandle GUID
    ---@return number[]|nil {x, y, z}
    local function entityPos(entity)
        entity = type(entity) == "string" and Ext.Entity.Get(entity) or entity
        local ok, pos = pcall(function()
            return entity.Transform.Transform.Translate
        end)
        if ok then
            return { pos[1], pos[2], pos[3] }
        end
        return nil
    end

    local sourcePos = entityPos(source)
    if not sourcePos then
        return {}
    end

    ---@param target number[] {x, y, z}
    ---@return number
    local function calcDisance(target)
        return math.sqrt(
            (sourcePos[1] - target[1]) ^ 2
                + (not ignoreHeight and (sourcePos[2] - target[2]) ^ 2 or 0)
                + (sourcePos[3] - target[3]) ^ 2
        )
    end

    local nearby = {}
    for _, entity in ipairs(Ext.Entity.GetAllEntitiesWithComponent(withComponent)) do
        local pos = entityPos(entity)
        if pos then
            local distance = calcDisance(pos)
            if distance <= radius then
                table.insert(nearby, {
                    Entity = entity,
                    Guid = entity.Uuid and entity.Uuid.EntityUuid,
                    Distance = distance,
                })
            end
        end
    end

    table.sort(nearby, function(a, b)
        return a.Distance < b.Distance
    end)

    return nearby
end

---@param entity EntityHandle
---@param property string
---@param default any|nil
---@return any
function M.Entity.GetProperty(entity, property, default)
    local ok, value = pcall(function()
        return entity[property]
    end)
    if ok then
        return value
    end
    return default
end

if Ext.IsClient() then
    return M
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                         Server Only                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.DB = {}

---@param query string
---@param arity number
---@param args table
---@param take number|nil
---@return table
function M.DB.TryGet(query, arity, args, take)
    args = args or {}
    local success, result = pcall(function()
        local db = Osi[query]
        if db and db.Get then
            return db:Get(table.unpack(args, 1, arity))
        end
    end)

    if not success then
        M.Log.Error("Failed to get DB", query, result)
        return {}
    end

    if take then
        result = Utils.Table.Map(result, function(v)
            return v[take]
        end)
    end

    return result
end

---@return string[] list of avatar characters
function M.DB.GetAvatars()
    return M.DB.TryGet("DB_Avatars", 1, nil, 1)
end

---@return string[] list of playable characters
function M.DB.GetPlayers()
    return M.DB.TryGet("DB_Players", 1, nil, 1)
end

M.Character = {}

function M.Character.IsHireling(character)
    local faction = Osi.GetFaction(character)

    return faction and faction:match("^Hireling") ~= nil
end

---@param character string GUID
---@return boolean
function M.Character.IsOrigin(character)
    local faction = Osi.GetFaction(character)
    if faction and (faction:match("^Origin") ~= nil or faction:match("^Companion") ~= nil) then
        return true
    end

    return Utils.Table.Find(Constants.OriginCharacters, function(v)
        return Utils.UUID.Equals(v, character)
    end) ~= nil
end

---@param character string GUID
---@param includeParty boolean|nil Summons or QuestNPCs might be considered party members
---@return boolean
function M.Character.IsNonPlayer(character, includeParty)
    if not includeParty and (Osi.IsPartyMember(character, 1) == 1 or Osi.IsPartyFollower(character) == 1) then
        return false
    end
    return not M.Character.IsOrigin(character)
        and not M.Character.IsHireling(character)
        and Osi.IsPlayer(character) ~= 1
end

---@param character string GUID
---@return boolean
function M.Character.IsPlayable(character)
    return M.Character.IsOrigin(character)
        or M.Character.IsHireling(character)
        or Osi.IsPlayer(character) == 1
        or (
            Utils.Table.Find(M.DB.GetAvatars(), function(v)
                return Utils.UUID.Equals(v, character)
            end) ~= nil
        )
end

function M.Character.IsImportant(character)
    return M.Character.IsPlayable(character)
        or (
            Utils.Table.Find(Constants.NPCCharacters, function(v)
                return Utils.UUID.Equals(v, character)
            end) ~= nil
        )
end

M.Object = {}

-- also works for items
function M.Object.Remove(guid)
    Osi.PROC_RemoveAllPolymorphs(guid)
    Osi.PROC_RemoveAllDialogEntriesForSpeaker(guid)
    Osi.SetOnStage(guid, 0)
    Osi.TeleportToPosition(guid, 0, 0, 0, "", 1, 1, 1, 1, 0) -- no blood
    Osi.Die(guid, 2, Constants.NullGuid, 0, 1)
    Osi.RequestDelete(guid)
    Osi.RequestDeleteTemporary(guid)
    Osi.UnloadItem(guid)
end

return M
