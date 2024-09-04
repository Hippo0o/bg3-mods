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
---@field Helpers string[] list of GUID
local Object = Libs.Struct({
    Region = nil,
    Enter = nil,
    Spawns = nil,
    Timeline = nil, -- used on scenario creation
    Helpers = {},
})

---@return Map
function Object.New(data)
    return Object.Init(data)
end

---@param character string GUID
function Object:TeleportInRegion(character, withOffset)
    local _, chainable = self:TeleportToSpawn(character, 0, withOffset)

    chainable:After(function()
        Event.Trigger("MapTeleported", self, character)
    end)

    return true
end

local charactersToTeleport = {}
function Object:Teleport(character, noOffset)
    if self.Region == Player.Region() then
        return self:TeleportInRegion(character, not noOffset)
    end

    local _, act = table.find(C.Regions, function(region, act)
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

    if spawn > 0 then
        pos = self.Spawns[spawn]
    end
    if spawn == 0 then
        pos = self.Enter
    end
    if not pos then
        pos = self.Spawns[math.random(1, #self.Spawns)]
    end

    return table.unpack(pos)
end

function Object:TeleportToSpawn(guid, spawn, withOffset)
    local x, y, z = self:GetSpawn(spawn)

    pcall(function()
        if withOffset then
            local offset = tonumber(Config.RandomizeSpawnOffset)
            if not GC.IsNonPlayer(guid) then
                ofsset = offset / 2
            end

            local offset = math.floor(offset)
            if offset > 0 then
                x = x + math.random() * math.random(-offset, offset)
                z = z + math.random() * math.random(-offset, offset)
            end
        end

        x, y, z = Osi.FindValidPosition(x, y, z, 50, guid, 1)
    end)
    if not x or not y or not z then
        x, y, z = self:GetSpawn(spawn)
    end

    Osi.TeleportToPosition(guid, x, y, z, "", 1, 1, 1, 0, 1)

    if GC.IsNonPlayer(guid) then
        Osi.PROC_Foop(guid)
    end

    local x, y, z = self:GetSpawn(spawn)
    return true,
        WaitTicks(10, function()
            return Map.CorrectPosition(guid, x, y, z, Config.RandomizeSpawnOffset)
        end)
end

---@param enemy Enemy
---@param spawn number Index of Spawns or -1 for random
---@param faceTowards string|nil GUID of entity to face towards
---@return boolean, ChainableRunner|nil
function Object:SpawnIn(enemy, spawn, faceTowards)
    local x, y, z = self:GetSpawn(spawn)

    pcall(function()
        local offset = tonumber(Config.RandomizeSpawnOffset)
        if offset > 0 then
            x = x + math.random() * math.random(-offset, offset)
            z = z + math.random() * math.random(-offset, offset)
        end
    end)

    -- spawned is combat ready
    local ok, chainable = enemy:Spawn(x, y, z)

    if not ok then
        return false
    end

    Osi.PROC_Foop(enemy.GUID)

    local x, y, z = self:GetSpawn(spawn)

    local x2, y2, z2 = Osi.FindValidPosition(x, y, z, 50, enemy.GUID, 1)
    if x2 and y2 and z2 then
        x, y, z = x2, y2, z2
    end

    return true,
        chainable:After(function()
            return enemy, -- 2nd param chainable can only be chained on if executed later
                WaitTicks(6, function() -- 6 ticks to ensure enitity is spawned
                    local didCorrect = Map.CorrectPosition(enemy.GUID, x, y, z, Config.RandomizeSpawnOffset)

                    if not faceTowards then
                        faceTowards = Osi.GetClosestAlivePlayer(enemy.GUID)
                    end

                    Osi.SteerTo(enemy.GUID, faceTowards, 1)
                    -- Osi.LookAtEntity(enemy.GUID, Osi.GetClosestAlivePlayer(enemy.GUID), 5)

                    return enemy, didCorrect
                end)
        end)
end

function Object:PingSpawns()
    for _, pos in pairs(self.Spawns) do
        local x, y, z = table.unpack(pos)
        Osi.RequestPing(x, y, z, "", "")
    end
end

function Object:Prepare()
    for _, pos in pairs(table.combine({}, { self.Enter }, self.Spawns)) do
        local x, y, z = table.unpack(pos)

        local guid = Osi.CreateAt(C.MapHelper, x, y, z, 1, 0, "")
        if not guid then
            L.Error("Failed to create helper.", x, y, z)
            self:Clear()
            return false
        end

        table.insert(self.Helpers, guid)
    end

    return true
end

function Object:VFXSpawns(spawns, time)
    for _, guid in pairs(self.Helpers) do
        -- LOW_CAZADORSPALACE_SARCOPHAGUS_BEAM_007
        -- END_HIGHHALLINTERIOR_DROPPODTARGET_VFX
        Osi.RemoveStatus(guid, "END_HIGHHALLINTERIOR_DROPPODTARGET_VFX")
    end

    for _, index in pairs(spawns) do
        local helperObject = self.Helpers[index + 1]
        if helperObject then
            Osi.ApplyStatus(helperObject, "END_HIGHHALLINTERIOR_DROPPODTARGET_VFX", time or -1)
        end
    end
end

function Object:Clear()
    for _, guid in pairs(self.Helpers) do
        GU.Object.Remove(guid)
    end

    self.Helpers = {}
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

    for _, m in ipairs(External.Templates.GetMaps()) do
        if region == nil or m.Region == region then
            table.insert(r, m)
        end
    end

    return r
end

---@param region string|nil
---@return Map[]
function Map.Get(region)
    return table.map(Map.GetTemplates(region), Object.New)
end

---@param map Map
---@return Map
function Map.Restore(map)
    -- map = table.find(Map.GetTemplates(map.Region), function(v)
    --     return v.Name == map.Name
    -- end) or map

    return Object.Init(map)
end

---@param guid string GUID
---@param x number
---@param y number
---@param z number
---@param offset number
---@return boolean
function Map.CorrectPosition(guid, x, y, z, offset)
    local distance = Osi.GetDistanceToPosition(guid, x, y, z)
    local _, y2, _ = Osi.GetPosition(guid)
    if not y2 then
        return false
    end

    if distance > offset * 1.5 or y2 < y - 5 or y2 > y + 5 then
        L.Error(guid, "Spawned too far away.", distance)
        Osi.TeleportToPosition(guid, x, y, z, "", 1, 1, 1, 0, 0)
        Osi.PROC_Foop(guid)
        return true
    end

    return false
end
