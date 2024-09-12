-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Enemy : Struct
---@field Name string
---@field TemplateId string
---@field IsBoss boolean
---@field Tier string
---@field Info table
---@field GUID string
---@field Temporary boolean
---@field HadTurn boolean
---@field WasAttacked boolean
-- potential overwrites
---@field LevelOverride integer
---@field DisplayName string
---@field Equipment string
---@field Race string
---@field Stats string
---@field SpellSet string
---@field AiHint string
---@field Archetype string
---@field CharacterVisualResourceID string
---@field Icon string
local Object = Libs.Struct({
    _Id = nil,
    Name = "Empty",
    TemplateId = nil,
    Tier = nil,
    Info = {},
    GUID = nil,
    IsBoss = false,
    HadTurn = false,
    WasAttacked = false,
    Temporary = false,
    -- not required
    Race = nil,
    LevelOverride = 0,
    Equipment = nil,
    Stats = nil,
    DisplayName = nil,
    SpellSet = nil,
    AiHint = nil,
    Archetype = nil,
    CharacterVisualResourceID = nil,
    Icon = nil,
})

---@param data table enemy source data
---@return Enemy
function Object.New(data)
    local o = Object.Init(data)

    o._Id = U.RandomId("Enemy_")
    o.LevelOverride = o.LevelOverride and tonumber(o.LevelOverride) or 0
    o.GUID = nil

    return o
end

function Object:__tostring()
    return self.GUID
end

function Object:GetId()
    return tostring(self.Name) .. "_" .. tostring(self.TemplateId)
end

function Object:GetTranslatedName()
    local handle
    if self:IsSpawned() then
        handle = Osi.GetDisplayName(self.GUID)
    else
        handle = self:GetTemplate().DisplayName.Handle.Handle
    end
    return Osi.ResolveTranslatedString(handle)
end

function Object:IsSpawned()
    return self.GUID ~= nil and self:Entity() ~= nil
end

---@return table<ExtComponentType, any>
function Object:Entity()
    return Ext.Entity.Get(self.GUID)
end

function Object:GetTemplate()
    return Ext.Template.GetTemplate(self.TemplateId)
end

function Object:SyncTemplate()
    local template = self:GetTemplate()
    if template == nil then
        L.Error("Template not found: ", self.TemplateId)
        return
    end

    self.CharacterVisualResourceID = template.CharacterVisualResourceID
    self.Icon = template.Icon
    self.Stats = template.Stats
    self.DisplayName = template.DisplayName.Handle.Handle
    self.Equipment = template.Equipment
    self.Archetype = template.CombatComponent.Archetype
    self.AiHint = template.CombatComponent.AiHint
    self.IsBoss = template.CombatComponent.IsBoss
    self.SpellSet = template.SpellSet
    self.LevelOverride = template.LevelOverride
    self.Race = template.Race
end

function Object:ModifyTemplate()
    local template = self:GetTemplate()
    if template == nil then
        L.Error("Template not found: ", self.TemplateId)
        return
    end

    local function templateOverwrite(prop, value)
        Event.Trigger("TemplateOverwrite", self.TemplateId, prop, value)
    end

    -- most relevant, blocks loot drops
    -- templateOverwrite("IsEquipmentLootable", false)
    -- templateOverwrite("IsLootable", false)
    -- templateOverwrite("Treasures", { "Empty" })

    -- potential overwrites
    local combatComp = {}
    if self.Archetype ~= nil then
        combatComp.Archetype = self.Archetype
    end
    if self.AiHint ~= nil then
        combatComp.AiHint = self.AiHint
    end
    -- set later anyways
    -- combatComp.Faction = C.NeutralFaction
    -- combatComp.CombatGroupID = ""
    templateOverwrite("CombatComponent", combatComp)

    if self.Equipment ~= nil then
        templateOverwrite("Equipment", self.Equipment)
    end

    if self.CharacterVisualResourceID ~= nil then
        -- might not apply when too many enemies are spawned at once
        templateOverwrite("CharacterVisualResourceID", self.CharacterVisualResourceID)
    end

    if self.Icon ~= nil then
        templateOverwrite("Icon", self.Icon)
    end

    if self.DisplayName ~= nil then
        templateOverwrite("DisplayName", { Handle = { Handle = self.DisplayName } })
    end

    if self.Stats ~= nil then
        templateOverwrite("Stats", self.Stats)
    end

    if self.Race ~= nil then
        templateOverwrite("Race", self.Race)
    end

    if self.SpellSet ~= nil then
        templateOverwrite("SpellSet", self.SpellSet)
    end

    if self.LevelOverride > 0 then
        templateOverwrite("LevelOverride", self.LevelOverride)
    end
end

function Object:ModifyExperience()
    RetryUntil(function()
        return self:Entity().ServerExperienceGaveOut
    end, { retries = 4, interval = 1000 }):After(function()
        local entity = self:Entity()

        local expMod = (Config.ExpMultiplier or 1) * 2
        if self.IsBoss then
            expMod = expMod * 1.2
        end

        if PersistentVars.Unlocked.ExpMultiplier then
            expMod = expMod * 2
        end

        local exp = entity.BaseHp.Vitality
            * math.ceil(entity.EocLevel.Level / 2) -- ceil(1/2) = 1
            * expMod

        entity.ServerExperienceGaveOut.Experience = math.floor(exp / Player.PartySize())
    end):Catch(function()
        L.Error("Failed to modify experience: ", self.GUID)
    end)
end

function Object:OnCombat() end

function Object:OnAttacked(attacker)
    Schedule(function()
        if Osi.IsInCombat(self.GUID) ~= 1 then
            self:Combat(true)
        end
    end)

    if self.HadTurn or self.WasAttacked then
        return
    end
    self.WasAttacked = true

    local seenEnemy = table.find(GU.DB.TryGet("DB_Sees", 2, { nil, self.GUID }, 1), function(v)
        return Osi.IsEnemy(self.GUID, v) == 1
    end)

    if not seenEnemy then
        Osi.ApplyStatus(self.GUID, "SURPRISED", 1)
    end
end

function Object:OnTurn()
    self.HadTurn = true
end

function Object:Modify(keepFaction)
    if not self:IsSpawned() or Osi.IsDead(self.GUID) == 1 then
        return
    end

    Osi.SetCharacterLootable(self.GUID, 0)
    Osi.SetCombatGroupID(self.GUID, "a209e7e8-fece-4a68-b4cf-b3000159cf3d")

    if not keepFaction then
        Osi.SetFaction(self.GUID, C.NeutralFaction)
    end

    Osi.AddBoosts(self.GUID, "StatusImmunity(KNOCKED_OUT)", "", "")

    -- if self.SpellSet == "" then
    --     Osi.AddSpell(self.GUID, "Projectile_Jump")
    --     Osi.AddSpell(self.GUID, "Shout_Dash")
    -- end

    -- undead enemies get shadow curse immunity
    if Osi.IsTagged(self.GUID, "33c625aa-6982-4c27-904f-e47029a9b140") == 1 then -- UNDEAD
        Osi.SetTag(self.GUID, C.ShadowCurseTag) -- ACT2_SHADOW_CURSE_IMMUNE
    end

    if Osi.GetSwarmGroup(self.GUID) then
        Osi.RequestSetSwarmGroup(self.GUID, "")
    end

    -- if not self.Temporary then
    --     Osi.SetTag(self.GUID, "6d60bed7-10cc-4b52-8fb7-baa75181cd49") -- IGNORE_COMBAT_LATE_JOIN_PENALTY
    -- end

    Osi.SetTag(self.GUID, "b5825091-f2ed-4657-8d86-c0d020c358a0") -- PALADIN_BLOCK_OATHBREAK
    Osi.ClearTag(self.GUID, "9787450d-f34d-43bd-be88-d2bac00bb8ee") -- AI_UNPREFERRED_TARGET
    Osi.ClearTag(self.GUID, "64bc9da1-9262-475a-a397-157600b7debd") -- AI_PREFERRED_TARGET

    self:ModifyExperience()

    self:Entity().ServerCharacter.Treasures = { "Empty" }

    self:Replicate()

    -- maybe useful
    -- Osi.CharacterGiveEquipmentSet(target, equipmentSet)
    -- Osi.SetAiHint(target, aiHint)
    -- Osi.AddCustomVisualOverride(character, visual)
end

function Object:Replicate()
    Schedule(function()
        local entity = self:Entity()
        entity:Replicate("GameObjectVisual")
        entity.Icon.Icon = entity.GameObjectVisual.Icon
        entity:Replicate("Icon")
        entity:Replicate("DisplayName")
        entity:Replicate("CombatParticipant")
    end):Catch(function(err)
        L.Error("Replication failed: ", self.GUID, err)
    end)
end

function Object:Sync()
    local entity = self:Entity()

    local serverObject = entity.ServerCharacter or entity.ServerItem
    if not serverObject then
        L.Debug("Entity not found", self.GUID)
        return
    end

    local currentTemplate = serverObject.Template
    if self.TemplateId == nil then
        self.TemplateId = currentTemplate.Id
    end

    if not entity.ServerCharacter then
        return
    end

    self.CharacterVisualResourceID = currentTemplate.CharacterVisualResourceID
    self.Icon = currentTemplate.Icon
    self.Stats = currentTemplate.Stats
    self.Equipment = currentTemplate.Equipment
    self.Archetype = currentTemplate.CombatComponent.Archetype
    self.AiHint = currentTemplate.CombatComponent.AiHint
    self.IsBoss = currentTemplate.CombatComponent.IsBoss
    self.SpellSet = currentTemplate.SpellSet
    self.LevelOverride = currentTemplate.LevelOverride
    self.Race = currentTemplate.Race
end

---@param x number
---@param y number
---@param z number
---@return boolean
function Object:CreateAt(x, y, z)
    if self:IsSpawned() then
        return false
    end

    self:ModifyTemplate()

    self.GUID = Osi.CreateAt(self:GetId(), x, y, z, 0, 1, "")

    if not self:IsSpawned() then
        return false
    end

    self:Sync()

    PersistentVars.SpawnedEnemies[self.GUID] = self
    L.Debug("Enemy created: ", self:GetTranslatedName(), self:GetId(), self.GUID)

    return true
end

---@param x number
---@param y number
---@param z number
---@param neutral boolean|nil if combat should not be initiated
---@return boolean, ChainableRunner|nil
function Object:Spawn(x, y, z, neutral)
    if self:IsSpawned() then
        return false
    end

    x, y, z = Osi.FindValidPosition(x, y, z, 100, C.NPCCharacters.Volo, 1) -- avoiding dangerous surfaces

    local success = self:CreateAt(x, y, z)

    if not success then
        L.Error("Failed to spawn: ", self:GetTranslatedName(), self:GetId())

        return false
    end

    return true,
        RetryUntil(function(runner)
            return self:Entity().ServerReplicationDependencyOwner -- goal: a component that loads later and always exists
        end, { retries = 30, interval = 100 }):After(function()
            self:Modify()

            if not neutral then
                self:Combat()
            end

            Osi.SteerTo(self.GUID, Osi.GetClosestAlivePlayer(self.GUID), 1)

            return self
        end)
end

function Object:Combat(force)
    if not self:IsSpawned() then
        return
    end

    local enemy = self.GUID

    Enemy.Combat(enemy, force)
end

function Object:Clear(keepCorpse)
    local guid = self.GUID
    local id = self:GetId()
    local entity = self:Entity()

    RetryUntil(function()
        if keepCorpse then
            Osi.Die(guid, 0, C.NullGuid, 0, 0)
        else
            GU.Object.Remove(guid)
        end

        return Osi.IsDead(guid) == 1 or not entity or not entity:IsAlive()
    end, { retries = 3, interval = 300, immediate = true }):After(function()
        if not keepCorpse then
            for db, matches in pairs({
                DB_Was_InCombat = Osi.DB_Was_InCombat:Get(guid, nil),
                DB_Sees = Osi.DB_Sees:Get(nil, guid),
            }) do
                for _, v in pairs(matches) do
                    Osi[db]:Delete(table.unpack(v))
                end
            end

            PersistentVars.SpawnedEnemies[guid] = nil
        end
    end):Catch(function()
        L.Error("Failed to kill: ", guid, id)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Enemy.RestoreFromSave(state)
    xpcall(function()
        PersistentVars.SpawnedEnemies = table.map(state, function(v, k)
            return Enemy.Restore(v), k
        end)
    end, function(err)
        L.Error(err)
    end)
end

local enemies = {}
Event.On("ScenarioStarted", function()
    enemies = {}
end)

---@param enemy Enemy
---@return Enemy
function Enemy.Restore(enemy)
    if enemy._Id and enemies[enemy._Id] then
        return enemies[enemy._Id]
    end

    local e = Object.Init(enemy)
    if e._Id then
        enemies[e._Id] = e
    end

    if not e:IsSpawned() then
        return e
    end

    PersistentVars.SpawnedEnemies[e.GUID] = e

    RetryUntil(function(runner)
        return e:Entity().ServerReplicationDependencyOwner
    end, { retries = 30, interval = 100 }):After(function()
        e:ModifyTemplate()

        e:Sync()
        e:Modify(true)

        return e
    end)

    return e
end

---@param object string GUID
---@return Enemy
-- mostly for tracking summons
function Enemy.CreateTemporary(object)
    local e = Object.New({ Name = "Temporary" })
    e.GUID = U.UUID.Extract(object)
    e.Tier = C.EnemyTier[1]
    e.Temporary = true

    PersistentVars.SpawnedEnemies[e.GUID] = e

    e:Sync()
    e:Modify(true)

    return e
end

---@return Enemy|nil
function Enemy.Find(search, templates)
    for _, enemy in Enemy.Iter(templates) do
        if string.contains(search, { enemy.TemplateId, enemy.Name }, false, true) then
            return enemy
        end
    end
end

---@param tier string
---@return Enemy[]
function Enemy.GetByTier(tier, templates)
    local list = {}
    for _, enemy in Enemy.Iter(templates) do
        if enemy.Tier == tier then
            table.insert(list, enemy)
        end
    end

    return list
end

---@return Enemy[]
function Enemy.GetByTemplateId(templateId, templates)
    local list = {}
    for _, enemy in Enemy.Iter(templates) do
        if enemy.TemplateId == templateId then
            table.insert(list, enemy)
        end
    end

    return list
end

Enemy.GetTemplates = Cached(function()
    return table.filter(External.Templates.GetEnemies(), function(v)
        local template = Ext.Template.GetRootTemplate(v.TemplateId)
        local keep = template and Ext.Template.GetRootTemplate(template.ParentTemplateId)

        if not keep then
            L.Debug("Template does not exist:", v.TemplateId)
        elseif (v.Stats and not Ext.Stats.Get(v.Stats)) or not Ext.Stats.Get(template.Stats) then
            L.Debug("Template Stats does not exist:", v.TemplateId)
            keep = false
        end

        return keep
    end)
end, 10000)

---@field templates table<number, table>
---@return fun():number,Enemy
function Enemy.Iter(templates)
    if not templates then
        templates = Enemy.GetTemplates()
    end
    local i = 0
    return function()
        i = i + 1
        if templates[i] then
            return i, Object.New(templates[i])
        end
    end
end

---@param object string GUID
---@return boolean
function Enemy.IsValid(object)
    return GC.IsNonPlayer(object)
        and Osi.IsAlly(object, Player.Host()) ~= 1 -- probably already handled by IsNonPlayer
        and not GU.Object.IsOwned(object)
        and (
            Osi.IsSummon(object) == 1
            or (Scenario.Current() and table.find(Scenario.Current().SpawnedEnemies, function(v)
                return U.UUID.Equals(v.GUID, object)
            end) ~= nil)
            or (table.find(PersistentVars.SpawnedEnemies, function(v)
                return U.UUID.Equals(v.GUID, object)
            end) ~= nil)
            or U.UUID.Equals(C.EnemyFaction, Osi.GetFaction(object))
        )
end

---@param object string GUID
---@return number distance, number x, number y, number z
function Enemy.DistanceToParty(object)
    local partyPositions = table.map(GU.Entity.GetParty(), function(entity)
        return entity.Transform.Transform.Translate
    end)

    local x, y, z = Osi.GetPosition(object)

    local distance = 999
    local partyXyz = {}
    for _, xyz in ipairs(partyPositions) do
        local d = Ext.Math.Distance({ x, xyz[2], z }, xyz)
        if d < distance then
            distance = d
            partyXyz = xyz
        end
    end

    return distance, table.unpack(partyXyz)
end

function Enemy.Cleanup()
    for guid, enemy in pairs(PersistentVars.SpawnedEnemies) do
        if not Enemy.IsValid(guid) then
            PersistentVars.SpawnedEnemies[guid] = nil
        else
            Object.Init(enemy):Clear()
        end
    end
end

---@param object string GUID
function Enemy.Combat(object, force)
    Osi.ApplyStatus(object, "InitiateCombat", -1)
    Osi.ApplyStatus(object, "BringIntoCombat", -1)

    Osi.SetFaction(object, C.EnemyFaction)
    Osi.SetCanJoinCombat(object, 1)
    Osi.SetCanFight(object, 1)

    if force then
        for _, player in pairs(GU.DB.GetPlayers()) do
            Osi.EnterCombat(player, object)
            Osi.EnterCombat(object, player)
        end
    end
end

function Enemy.KillSpawned(object)
    for guid, enemy in pairs(PersistentVars.SpawnedEnemies) do
        enemy = Object.Init(enemy)
        if
            object == nil
            or U.UUID.Equals(enemy.GUID, object)
            or string.contains(object, { enemy.TemplateId, enemy.Name, enemy:GetId() })
        then
            enemy:Clear(true)
        end
    end
end

function Enemy.SpawnTemplate(templateId, x, y, z)
    local e = Object.New({ Name = "Custom", TemplateId = templateId })
    if e:GetTemplate() == nil then
        L.Error("Template not found: ", templateId)
        return
    end
    e:Spawn(x, y, z)
    return e
end

---@param enemy Enemy
---@return string, table
function Enemy.CalcTier(enemy)
    local vit = enemy:Entity().BaseHp.Vitality
    local level = enemy:Entity().EocLevel.Level

    local stats = enemy:Entity().Stats.AbilityModifiers
    local prof = enemy:Entity().Stats.ProficiencyBonus
    local ac = enemy:Entity().Resistances.AC

    -- for i, v in pairs(enemy:Entity().Resistances.Resistances) do
    --     local s = Ext.Json.Stringify(v)
    --     if s:match("ImmuneToNonMagical") or s:match("ImmuneToMagical") then
    --         return "trash"
    --     end
    -- end

    -- if enemy:Entity().ServerCharacter.Template.IsLootable ~= true then
    --     return "trash"
    -- end

    local sum = 0
    local statsValid = false
    for _, stat in pairs(stats) do
        sum = sum + stat
        if stat ~= 0 then
            statsValid = true
        end
    end

    if vit < 5 then
        return "trash"
    end

    if not statsValid then
        return "trash"
    end

    local pwr = (vit / 2) + sum + prof + ac + level * 2

    local category
    if pwr > 150 then
        category = C.EnemyTier[6]
    elseif pwr % 151 > 90 then
        category = C.EnemyTier[5]
    elseif pwr % 91 > 65 then
        category = C.EnemyTier[4]
    elseif pwr % 66 > 45 then
        category = C.EnemyTier[3]
    elseif pwr % 46 > 25 then
        category = C.EnemyTier[2]
    else
        category = C.EnemyTier[1]
    end

    return category,
        {
            Vit = vit,
            Stats = sum,
            AC = ac,
            Level = level,
            Pwr = pwr,
        }
end

function Enemy.GenerateEnemyList(templates)
    local function isValidFilename(filename)
        return string.contains(filename, {
            "Public/Gustav",
            "Public/GustavDev",
            "Public/Shared",
            "Public/SharedDev",
            "Public/Honour",

            "Mods/Gustav",
            "Mods/GustavDev",
            "Mods/Shared",
            "Mods/SharedDev",
            "Mods/Honour",
        })
    end

    local function check(template)
        if not isValidFilename(template.FileName) then
            L.Debug(template.FileName)
            return
        end

        if template.TemplateType ~= "character" then
            return
        end

        -- if template.LevelOverride < 0 then
        --     return
        -- end

        if template.CombatComponent.Archetype == "base" then
            L.Debug(template.CombatComponent.Archetype)
            return
        end

        local patterns = {
            "_Civilian",
            "Dummy",
            "Orin",
            "DaisyPlaceholder",
            "Template",
            "Player",
            "Backup",
            "DarkUrge",
            "Daisy",
            "donotuse",
            "_Hireling",
            "_Guild",
            "Helper",
        }
        local startswith = {
            "^_",
            "^ORIGIN_",
            "^Child_",
            "^TEMP_",
            "^CINE_",
            "^BASE_",
            "^S_CAMP_",
            "^QUEST_",
        }

        if string.contains(template.Name, patterns, true) then
            L.Debug(template.Name)
            return false
        end
        if string.contains(template.Name, startswith, true) then
            L.Debug(template.Name)
            return false
        end

        return true
    end

    local enemies = {}
    for templateId, templateData in pairs(templates) do
        if check(templateData) then
            local data = {
                Name = templateData.Name,
                TemplateId = templateData.Id,
                CharacterVisualResourceID = templateData.CharacterVisualResourceID,
                Icon = templateData.Icon,
                Stats = templateData.Stats,
                Equipment = templateData.Equipment,
                Archetype = templateData.CombatComponent.Archetype,
                AiHint = templateData.CombatComponent.AiHint,
                IsBoss = templateData.CombatComponent.IsBoss,
                SpellSet = templateData.SpellSet,
                LevelOverride = templateData.LevelOverride,
            }
            table.insert(enemies, Object.New(data))
        else
            L.Debug("Enemy template skipped: ", templateId)
        end
    end

    L.Info("Enemies generated from templates: ", #enemies)

    return enemies
end

---@param enemies Enemy[]
function Enemy.TestEnemies(enemies, keepAlive)
    local i = 0
    local pause = false
    local dump = {}
    RetryUntil(function()
        if pause then
            return
        end

        i = i + 1
        if i > #enemies then
            return true
        end

        L.Debug("Checking template: ", i, #enemies)
        local enemy = enemies[i]

        local x, y, z = Player.Pos()
        local target = Player.Host()
        local radius = 100
        local avoidDangerousSurfaces = 1
        local x2, y2, z2 = Osi.FindValidPosition(x, y, z, radius, target, avoidDangerousSurfaces)

        xpcall(function()
            if enemy:CreateAt(x2 or x, y2 or y, z2 or z) then
                pause = true
                Defer(400, function()
                    Defer(100, function()
                        pause = false
                    end)

                    if not enemy:IsSpawned() then
                        return
                    end

                    local tier, info = Enemy.CalcTier(enemy)
                    enemy.Tier = tier
                    enemy.Info = info
                    L.Dump(tier, info)
                    if tier ~= "trash" then
                        table.insert(
                            dump,
                            table.filter(enemy, function(v, k)
                                return k ~= "GUID"
                            end, true)
                        )
                    end

                    if not keepAlive then
                        enemy:Clear()
                    end
                end)
            end
        end, function(err)
            L.Error(err)
            error(err)
        end)
    end, { retries = -1, interval = 1 }):After(function()
        IO.SaveJson("RatedEnemies.json", dump)
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(character, _)
    if Osi.IsPlayer(character) == 1 then
        return
    end

    local enemy = PersistentVars.SpawnedEnemies[U.UUID.Extract(character)]
    if getmetatable(enemy) then
        enemy:OnCombat()
    end
end)

Ext.Osiris.RegisterListener("LeftCombat", 2, "after", function(character, _)
    if Osi.IsPlayer(character) == 1 then
        return
    end

    local enemy = PersistentVars.SpawnedEnemies[U.UUID.Extract(character)]
    if getmetatable(enemy) then
        enemy:OnCombat()
    end
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "before", function(character)
    if Osi.IsPlayer(character) == 1 then
        return
    end

    local enemy = PersistentVars.SpawnedEnemies[U.UUID.Extract(character)]
    if getmetatable(enemy) then
        enemy:OnTurn()
    end
end)

Ext.Osiris.RegisterListener("AttackedBy", 7, "before", function(defender, attackerOwner)
    if Osi.IsPlayer(defender) == 1 then
        return
    end
    if Osi.IsPlayer(attackerOwner) ~= 1 then
        return
    end

    local enemy = PersistentVars.SpawnedEnemies[U.UUID.Extract(defender)]
    if getmetatable(enemy) then
        enemy:OnAttacked(attackerOwner)
    end
end)
