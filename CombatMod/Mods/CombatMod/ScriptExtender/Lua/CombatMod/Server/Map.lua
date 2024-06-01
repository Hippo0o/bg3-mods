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
---@class Map : LibsClass
---@field Region string
---@field Enter Pos
---@field Spawns Pos[]
---@field Timeline number[]
local Object = Libs.Class({
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
function Object:Teleport(character, withOffset)
    local x, y, z = table.unpack(self.Enter)

    -- sucks to suck
    -- pcall(function()
    --     local offset = tonumber(Config.RandomizeSpawnOffset)
    --     if offset > 0 and withOffset then
    --         x = x + U.Random() * U.Random(-offset, offset)
    --         z = z + U.Random() * U.Random(-offset, offset)
    --     end
    --
    --     x, y, z = Osi.FindValidPosition(x, y, z, 100, "", 1) -- TODO fix dangerous surface
    -- end)
    -- if not x or not y or not z then
    --     x = self.Enter[1]
    --     y = self.Enter[2]
    --     z = self.Enter[3]
    -- end

    Osi.TeleportToPosition(character, x, y, z, "", 1, 1, 1)
end

---@param spawn number Index of Spawns or -1 for random
---@return number x, number y, number z
function Object:GetSpawn(spawn)
    local pos = nil

    if spawn == -1 then
        pos = self.Spawns[U.Random(1, #self.Spawns)]
    else
        pos = self.Spawns[spawn]
    end
    if pos == nil then
        L.Error("No spawn point found.", spawn)
        return false
    end

    local x, y, z = table.unpack(pos)

    pcall(function()
        local offset = tonumber(Config.RandomizeSpawnOffset)
        if offset > 0 then
            x = x + U.Random() * U.Random(-offset, offset)
            z = z + U.Random() * U.Random(-offset, offset)
        end
    end)

    return x, y, z
end

---@param enemy Enemy
---@param spawn number Index of Spawns or -1 for random
---@return boolean
function Object:SpawnIn(enemy, spawn)
    local x, y, z = self:GetSpawn(spawn)

    -- spawned is combat ready
    local success = enemy:Spawn(x, y, z)

    if not success then
        return false
    end

    Osi.LookAtEntity(enemy.GUID, Osi.GetClosestAlivePlayer(enemy.GUID), 5)
    -- Osi.SetAmbushing(enemy.GUID, 1) -- makes tactical cam outline disappear

    return true
end

---@param loot Item
function Object:SpawnLoot(loot)
    local x, y, z = self.Enter[1], self.Enter[2], self.Enter[3]
    if Config.SpawnItemsAtPlayer then
        x, y, z = Player.Pos()
    end

    Item.SpawnLoot(loot, x, y, z)
end

function Object:PingSpawns()
    for _, pos in pairs(self.Spawns) do
        local x, y, z = table.unpack(pos)
        Osi.RequestPing(x, y, z, "", "")
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

---@param map Map
---@param character string GUID
---@return boolean
function Map.TeleportTo(map, character)
    if map.Region == Osi.GetRegion(Player.Host()) then
        Object.Init(map):Teleport(character)

        if S and U.Equals(map, S.Map) then
            Event.Trigger("ScenarioTeleport", character)
        end

        return true
    end

    if not U.UUID.Equals(character, Player.Host()) then
        return false
    end

    local _, act = UT.Find(C.Regions, function(region, act)
        return region == map.Region
    end)

    if act == nil then
        L.Error("Region not found.", map.Region)
        return false
    end

    local teleporting = Player.TeleportToAct(act)

    if teleporting then
        Player.Notify(__("Teleporting to different ACT"))
        teleporting.After(function()
            for _, character in pairs(U.DB.GetPlayers()) do
                Map.TeleportTo(map, character)
            end
        end)
    end

    return false
end
