---@diagnostic disable: undefined-global

local maps = Require("JustCombat/Templates/Maps.lua")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Structures                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Pos
---@field x number
---@field y number
---@field z number
---@class Map : LibsObject
---@field Region string
---@field Enter Pos
---@field Spawns Pos[]
local Object = Libs.Object({
    Region = nil,
    Enter = nil,
    Spawns = nil,
})

---@return Map
function Object.New(data)
    -- TODO validate
    return Object.Init(data)
end

---@param character string GUID
function Object:Teleport(character)
    Osi.TeleportToPosition(character, self.Enter[1], self.Enter[2], self.Enter[3], "", 1, 1, 1)
end

---@param enemy Enemy
---@param spawn number Index of Spawns or -1 for random
---@return boolean
function Object:SpawnIn(enemy, spawn)
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

    -- spawned is combat ready
    local success = enemy:Spawn(pos[1], pos[2], pos[3])

    if not success then
        L.Error("Failed to spawn enemy.", enemy.GUID)
        return false
    end

    Schedule(function()
        Osi.LookAtEntity(enemy.GUID, Osi.GetClosestAlivePlayer(enemy.GUID), 5)
        -- Osi.SetAmbushing(enemy.GUID, 1) -- makes tactical cam outline disappear
    end)

    return true
end

---@param loot Item
function Object:SpawnLoot(loot)
    local x, y, z = self.Enter[1], self.Enter[2], self.Enter[3]
    -- x,z is x,y in game map
    x = x + U.Random() * U.Random(-1, 1)
    z = z + U.Random() * U.Random(-1, 1)
    loot:Spawn(x, y, z)
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

---@param region string
---@return Map[]
function Map.Get(region)
    local r = {}

    for _, m in ipairs(maps) do
        if m.Region == region then
            table.insert(r, Object.New(m))
        end
    end

    return r
end

---@return Map
function Map.GetByIndex(index)
    local map = maps[index]
    return Object.New(map)
end

---@param map Map
---@return Map
function Map.Restore(map)
    return Object.Init(map)
end
