local mapTemplates = Require("CombatMod/Templates/Maps.lua")
External.File.ExportIfNeeded("Maps", mapTemplates)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Pos
---@field x number
---@field y number
---@field z number
---@class Map : LibsStruct
---@field Region string
---@field Enter Pos
---@field Spawns Pos[]
---@field Timeline number[]
local Object = Libs.Struct({
    Region = nil,
    Enter = nil,
    Spawns = nil,
    Timeline = nil, -- used on scenario creation
})

---@return Map
function Object.New(data)
    return Object.Init(data)
end

---@param character string GUID
function Object:TeleportInRegion(character, withOffset)
    local x, y, z = table.unpack(self.Enter)

    pcall(function()
        local offset = tonumber(Config.RandomizeSpawnOffset / 2)
        if offset > 0 and withOffset then
            x = x + U.Random() * U.Random(-offset, offset)
            z = z + U.Random() * U.Random(-offset, offset)
        end

        x, y, z = Osi.FindValidPosition(x, y, z, 50, character, 1)
    end)
    if not x or not y or not z then
        x = self.Enter[1]
        y = self.Enter[2]
        z = self.Enter[3]
    end

    Osi.TeleportToPosition(character, x, y, z, "", 1, 1, 1)
    -- Osi.PROC_Foop(character)

    local x, y, z = table.unpack(self.Enter)
    Async.WaitTicks(10, function()
        Map.CorrectPosition(character, x, y, z, Config.RandomizeSpawnOffset / 2)

        Event.Trigger("MapTeleported", self, character)
    end)

    return true
end

local charactersToTeleport = {}
function Object:Teleport(character, noOffset)
    if self.Region == Osi.GetRegion(character) then
        return self:TeleportInRegion(character, not noOffset)
    end

    local _, act = UT.Find(C.Regions, function(region, act)
        return region == self.Region
    end)

    if act == nil then
        L.Error("Region not found.", self.Region)
        return false
    end

    table.insert(charactersToTeleport, character)

    local teleporting = Player.TeleportToAct(act)

    if teleporting then
        Player.Notify(__("Teleporting to different ACT"))
        teleporting:After(function()
            for _, character in pairs(charactersToTeleport) do
                self:Teleport(character, noOffset)
            end

            charactersToTeleport = {}
        end)
    end

    return false
end

---@param spawn number Index of Spawns or -1 for random
---@return number x, number y, number z
function Object:GetSpawn(spawn)
    local pos = nil

    if spawn > -1 then
        pos = self.Spawns[spawn]
    end
    if not pos then
        pos = self.Spawns[U.Random(1, #self.Spawns)]
    end

    return table.unpack(pos)
end

---@param enemy Enemy
---@param spawn number Index of Spawns or -1 for random
---@return boolean, ChainableRunner|nil
function Object:SpawnIn(enemy, spawn)
    local x, y, z = self:GetSpawn(spawn)

    pcall(function()
        local offset = tonumber(Config.RandomizeSpawnOffset)
        if offset > 0 then
            x = x + U.Random() * U.Random(-offset, offset)
            z = z + U.Random() * U.Random(-offset, offset)
        end
    end)

    -- spawned is combat ready
    local ok, chainable = enemy:Spawn(x, y, z)

    if not ok then
        return false
    end

    Osi.PROC_Foop(enemy.GUID)

    local x, y, z = self:GetSpawn(spawn)

    return true, chainable:After(function()
        return enemy,
            Async.WaitTicks(6, function()
                local didCorrect = Map.CorrectPosition(enemy.GUID, x, y, z, Config.RandomizeSpawnOffset)

                Osi.LookAtEntity(enemy.GUID, Osi.GetClosestAlivePlayer(enemy.GUID), 5)

                return enemy, didCorrect
            end)
    end)
end

---@param loot Item
function Object:SpawnLoot(loot)
    local x, y, z = self.Enter[1], self.Enter[2], self.Enter[3]
    if Config.SpawnItemsAtPlayer then
        x, y, z = Player.Pos()
    end

    Item.SpawnLoot(loot, x, y, z, true)
end

function Object:PingSpawns()
    for _, pos in pairs(self.Spawns) do
        local x, y, z = table.unpack(pos)
        Osi.RequestPing(x, y, z, "", "")
    end
end

function Object:ClearSpawns()
    for _, pos in pairs(UT.Combine({}, { self.Enter }, self.Spawns)) do
        local x, y, z = table.unpack(pos)

        Osi.CreateSurfaceAtPosition(x, y, z, "None", 100, -1)
        Osi.RemoveSurfaceLayerAtPosition(x, y, z, "Ground", 100)
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param region string|nil
---@return table
function Map.GetTemplates(region)
    local r = {}

    for _, m in ipairs(External.Templates.GetMaps(mapTemplates)) do
        if region == nil or m.Region == region then
            table.insert(r, m)
        end
    end

    return r
end

function Map.ExportTemplates()
    External.File.Export("Maps", mapTemplates)
end

---@param region string|nil
---@return Map[]
function Map.Get(region)
    return UT.Map(Map.GetTemplates(region), Object.New)
end

---@param map Map
---@return Map
function Map.Restore(map)
    return Object.Init(map)
end

function Map.CorrectPosition(guid, x, y, z, offset)
    local distance = Osi.GetDistanceToPosition(guid, x, y, z)
    local _, y2, _ = Osi.GetPosition(guid)
    if not y2 then
        return
    end

    if distance > offset * 1.5 or y2 < y - 5 or y2 > y + 5 then
        L.Error(guid, "Spawned too far away.", distance)
        Osi.TeleportToPosition(guid, x, y, z, "", 1, 1, 1)
        Osi.PROC_Foop(guid)
        return true
    end
end
