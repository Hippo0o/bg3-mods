local Commands = {}

function Commands.UI()
    Event.Trigger("ModActive")
    PersistentVars.GUIOpen = not PersistentVars.GUIOpen
    if PersistentVars.GUIOpen then
        Net.Send("OpenGUI")
    else
        Net.Send("CloseGUI")
    end
end

function Commands.Activate()
    Event.Trigger("ModActive")
end

function Commands.Roguelike()
    Event.Trigger("ModActive")
    PersistentVars.RogueModeActive = not PersistentVars.RogueModeActive
    L.Info(string.format("Roguelike mode is %s", PersistentVars.RogueModeActive and "active" or "inactive"))
    Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
end

function Commands.Debug()
    local oed = Require("Hlib/OsirisEventDebug")

    if #oed.Listeners > 0 then
        oed.Detach()
    else
        oed.Attach()
    end
end

function Commands.Loca()
    Localization.BuildLocaFile()
    L.Info("Script Extender/" .. Mod.Prefix .. "/" .. Localization.FilePath .. ".xml")
end

function Commands.Dev()
    L.Info(":)")
    Mod.Dev = true
    Mod.Debug = true
    Config.Debug = true
end

function Commands.Test()
    -- Enemy.TestEnemies(
    --     Enemy.GenerateEnemyList({
    --         Ext.Template.GetTemplate("319efbbe-f9f3-4584-804e-3e17d47d1136"),
    --     }),
    --     true
    -- )
    -- local temps = Ext.Template.GetAllRootTemplates()
    -- L.Dump(table.map(
    --     table.filter(temps, function(v)
    --         return v.TemplateType == "item" and v.CombatComponent.CanFight
    --     end),
    --     function(v)
    --         return v.Name
    --     end
    -- ))
    -- local e = {}
    -- for i, v in Enemy.Iter() do
    --     v:SyncTemplate()
    --     table.insert(e, v)
    -- end
    -- External.File.Export("Enemies", e)

    -- _D(Ext.Template.GetRootTemplate(Item.Armor("Legendary")[1].RootTemplate))
    -- for _, e in ipairs(GE.GetNearby(Player.Host(), 10, true, "DisplayName")) do
    --     -- L.Dump(Osi.ResolveTranslatedString(e.Entity.DisplayName.NameKey.Handle.Handle))
    --     L.Dump(Ext.Loca.GetTranslatedString(e.Entity.DisplayName.NameKey.Handle.Handle))
    -- end

    -- Osi.TeleportToWaypoint(Player.Host(), C.Waypoints.Act3b.GreyHarbor)

    -- local dump = Ext.DumpExport(_C().ServerCharacter.Template)
    -- local parts = string.split(dump, "\n")
    -- for _, part in ipairs(parts) do
    --     Osi.AddEntryToCustomBook("CombatMod", part .. "\n")
    -- end
    -- Osi.OpenCustomBookUI(GetHostCharacter(), "CombatMod")

    -- Require("Hlib/OsirisEventDebug").Attach()
    -- GameMode.AskUnlockAll()
    -- Osi.Use(GetHostCharacter(), "S_CHA_WaypointShrine_Top_PreRecruitment_b3c94e77-15ab-404c-b215-0340e398dac0", "")
    --
    -- new_start = tonumber(new_start) or start
    -- amount = tonumber(amount) or 100

    -- local j = 0
    -- local templates = {}
    -- for i, v in Enemy.Iter() do
    --     table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
    --     -- if i > new_start and (i - new_start) <= amount then
    --     --     j = j + 1
    --     -- end
    -- end
    -- start = new_start + j
    --
    local enemies = Enemy.GetByTemplateId("867c3061-624e-4b02-babb-a23e743fb5d3")

    Enemy.TestEnemies(enemies)

    -- local enemies = Enemy.GenerateEnemyList(Ext.Template.GetAllRootTemplates())
    -- Enemy.TestEnemies(enemies, false)

    -- local templates = {}
    -- for i, v in Enemy.Iter() do
    --     table.insert(templates, Ext.Template.GetTemplate(v.TemplateId))
    -- end
    -- local enemies = Enemy.GenerateEnemyList(templates)
    --
    -- Enemy.TestEnemies(enemies)

    -- Osi.TeleportToPosition(Player.Host(), 0, 0, 0, "", 1, 1, 1, 1, 0)
    -- Osi.MakePlayer("S_Player_Laezel_58a69333-40bf-8358-1d17-fff240d7fb12", Player.Host())
    -- Osi.MakePlayer("S_Player_Karlach_2c76687d-93a2-477b-8b18-8a14b549304c", Player.Host())

    -- local list = {}
    -- for i, v in Enemy.iter() do
    --     local key = v.TemplateId .. v.Stats .. v.Equipment .. v.Tier .. v.CharacterVisualResourceID .. v.Icon
    --     L.Dump(key, list[key])
    --     list[key] = v
    -- end
    -- Ext.IO.SaveFile(
    --     "enemies.json",
    --     Ext.DumpExport(table.map(list, function(v)
    --         return v
    --     end))
    -- )
end

function Commands.Spawn(search, neutral)
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end
    local x, y, z = Player.Pos()

    local e = Enemy.Find(search)
    if e == nil then
        L.Error("Enemy not found.", guid)
        return
    end

    local c = Config.BypassStory
    Config.BypassStory = false

    local ok, chainable = e:Spawn(x, y, z, neutral and true or false)
    if ok then
        chainable:After(function()
            if not neutral then
                e:Combat()
            end
            Defer(3000, function()
                L.Dump(e, Enemy.CalcTier(e))
            end)
        end)
    else
        L.Error("Failed to spawn enemy.")
    end

    Defer(2000, function()
        Config.BypassStory = c
    end)

    -- Defer(1000, function()
    --     Ext.IO.SaveFile("spawn-" .. e:GetId() .. ".json", Ext.DumpExport(e:Entity():GetAllComponents()))
    -- end)
end

function Commands.ToMap(id)
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end
    local s = Scenario.Current()

    if not id and s then
        s.Map:Teleport(Player.Host())
        return
    end

    local maps = Map.Get()
    id = tonumber(id or 1)
    if maps == nil then
        L.Error("No maps found.")
        return
    end

    local map = maps[id]
    if map == nil then
        L.Error("Map not found.")
        return
    end

    map:Teleport(Player.Host())
end

function Commands.Kill(guid)
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end
    Enemy.KillSpawned(guid)
end

function Commands.Clear()
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end

    Enemy.Cleanup()
end

function Commands.Maps(id)
    local maps = Map.GetTemplates()

    L.Info("ID", "Name", "!TT Maps [id]")

    for i, v in pairs(maps) do
        if id and i == tonumber(id) then
            L.Info(i, v.Name, Ext.DumpExport(v))
        else
            L.Info(i, v.Name)
        end
    end
end

function Commands.Scenarios(id)
    L.Info("ID", "Name", "!TT Scenarios [id]")
    for i, v in pairs(Scenario.GetTemplates()) do
        if id and i == tonumber(id) then
            L.Info(i, v.Name, Ext.DumpExport(v))
        else
            L.Info(i, v.Name)
        end
    end
end

function Commands.Start(scenarioId, mapId)
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end

    L.Info("!TT Scenarios", "List scenarios")
    L.Info("!TT Maps", "List maps")
    L.Info("!TT Start [scenarioId] [mapId]")
    if not scenarioId then
        L.Error("Scenario ID is required.")
        return
    end
    if not mapId then
        L.Error("Map ID is required.")
        return
    end

    local map = Map.Get(Player.Region())[tonumber(mapId)]
    local template = Scenario.GetTemplates()[tonumber(scenarioId)]
    if map == nil then
        L.Error("Map not found.")
        return
    end
    if template == nil then
        L.Error("Scenario not found.")
        return
    end

    L.Dump("Starting scenario.", id, template, map)

    Scenario.Start(template, map)
end

function Commands.Stop()
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end

    Scenario.Stop()
end

function Commands.Dump(file)
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end

    for i, v in pairs(Scenario.Current().SpawnedEnemies) do
        if v:IsSpawned() then
            L.Dump(table.filter(v:Entity().ServerCharacter, function(v, k)
                return k ~= "Template" and k ~= "TemplateUsedForSpells"
            end, true))

            if file then
                IO.SaveJson("dump-" .. v:GetId() .. ".json", v:Entity():GetAllComponents())
            end
        end
    end
end

function Commands.Pos()
    local x, y, z = Player.Pos()
    L.Debug("Region", Player.Region())
    L.Debug("Position", table.concat({ x, y, z }, ", "))
end

function Commands.Reload()
    if not IsActive() then
        L.Error("Mod is not active.")
        return
    end

    if External.LoadConfig() then
        L.Info("Config reloaded.")
    end

    if External.LoadLootRates() then
        L.Info("Loot rates reloaded.")
    end

    local m = External.Templates.GetMaps()
    if m then
        L.Info(#m, "Maps loaded.")
    else
        Templates.ExportMaps()
    end

    local s = External.Templates.GetScenarios()
    if s then
        L.Info(#s, "Scenarios loaded.")
    else
        Templates.ExportScenarios()
    end

    local e = External.Templates.GetEnemies()
    if e then
        L.Info(#e, "Enemies loaded.")
    else
        Templates.ExportEnemies()
    end

    Item.ClearCache()
end

function Commands.StoryBypass(flag)
    Config.BypassStory = ("true" == flag or tonumber(flag) == 1) and true or false
    L.Info("Story bypass is", Config.BypassStory and "enabled" or "disabled")
end
function Commands.EnableStoryBypass()
    Commands.StoryBypass(1)
end
function Commands.DisableStoryBypass()
    Commands.StoryBypass(0)
end

Ext.RegisterConsoleCommand("TT", function(_, fn, ...)
    if fn == nil or Commands[fn] == nil then
        L.Info("Available Commands:")
        for i, _ in pairs(Commands) do
            L.Info("!TT " .. i)
        end
        return
    end

    Commands[fn](...)
end)
