Debug = {}

---@param tab ExtuiTabBar
function Debug.Main(tab)
    Schedule(function()
        Event.Trigger("ToggleDebug", Mod.Debug)
    end)

    local tabRoot = tab:AddTabItem(__("Debug"))
    local root = tabRoot:AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }

    root:AddSeparatorText("Cheat")
    local ca = root:AddButton(__("Clear Area"))
    ca.OnClick = function()
        Net.Send("KillNearby")
    end

    root:AddInputInt("RogueScore", State.RogueScore or 0).OnChange = Debounce(1000, function(input)
        Net.RCE("PersistentVars.RogueScore = %d", input.Value[1]):After(function()
            Net.Send("SyncState")
        end)
    end)

    root:AddInputInt("Currency", State.Currency or 0).OnChange = Debounce(1000, function(input)
        Net.RCE("PersistentVars.Currency = %d", input.Value[1]):After(function()
            Net.Send("SyncState")
        end)
    end)

    -- section State
    local state = root:AddGroup(__("State"))
    state:AddSeparatorText(__("State"))
    state:AddButton(__("Reload")).OnClick = function()
        Net.Send("SyncState")
        Net.Send("GetTemplates")
        Net.Send("GetItems")
    end

    local stateTree
    Event.On("StateChange", function()
        if stateTree then
            stateTree:Destroy()
        end

        stateTree = Components.Tree(state, State)
    end)

    -- section Templates
    local templates = root:AddGroup(__("Templates"))
    templates:AddSeparatorText(__("Templates"))

    local templatesTree
    Net.On("GetTemplates", function(event)
        if templatesTree then
            templatesTree:Destroy()
        end

        templatesTree = Components.Tree(templates, event.Payload)
    end)
    Net.Send("GetTemplates")

    -- section Enemies
    Debug.Enemies(root)

    -- section Items
    Debug.Items(root)

    root:AddDummy(1, 2)

    return tabRoot
end

function Debug.Enemies(root)
    local grp = root:AddGroup(__("Enemies"))
    grp:AddSeparatorText(__("Enemies"))

    local netEnemies
    Net.On("GetEnemies", function(event)
        netEnemies = event.Payload
        Event.Trigger("EnemiesChanged", netEnemies)
    end)

    local tree
    Event.On("EnemiesChanged", function(enemies)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, enemies, nil, function(node, key, value)
            if key == "Name" then
                node:AddButton("Spawn").OnClick = function()
                    Net.RCE("Enemy.Find('%s'):Spawn(Osi.GetPosition(RCE:Character()))", value):After(function(_, err)
                        L.Dump(err)
                    end)
                end
            end
            if key == "TemplateId" then
                local nodeLoaded = false

                node.OnClick = function(v)
                    if nodeLoaded then
                        return
                    end

                    local temp = Ext.Template.GetTemplate(value)
                    if temp then
                        Components.Tree(node, UT.Clean(temp), "TemplateId = " .. value)

                        node:AddText("   DisplayName = ")
                        node:AddText(Ext.Loca.GetTranslatedString(temp.DisplayName.Handle.Handle)).SameLine = true
                    end

                    nodeLoaded = true
                end

                return true -- replace node
            end
        end)
    end)

    local search = grp:AddInputText(__("Search"))
    search.IDContext = U.RandomId()
    search.OnChange = Debounce(100, function(input)
        local list = {}
        for k, enemies in pairs(netEnemies) do
            list[k] = UT.Filter(enemies, function(item)
                local temp = Ext.Template.GetTemplate(item.TemplateId)
                if not temp then
                    L.Error("Template not found", item.TemplateId, item.Name)
                    return false
                end

                return US.Contains(item.Name, input.Text, true, true)
                    or US.Contains(Ext.Loca.GetTranslatedString(temp.DisplayName.Handle.Handle), input.Text, true, true)
            end)
        end

        Event.Trigger("EnemiesChanged", list)
    end)

    local combo = grp:AddCombo(__("Tier"))
    combo.IDContext = U.RandomId()
    combo.Options = C.EnemyTier
    combo.OnChange = function()
        search.Text = ""
        Net.Send("GetEnemies", { Tier = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton(__("Reset"))
    btn.IDContext = U.RandomId()
    btn.OnClick = function()
        combo.SelectedIndex = -1
        search.Text = ""
        Net.Send("GetEnemies")
    end
    btn.SameLine = true

    Net.Send("GetEnemies")
end
function Debug.Items(root)
    local grp = root:AddGroup(__("Items"))
    grp:AddSeparatorText(__("Items"))

    local netItems
    Net.On("GetItems", function(event)
        netItems = event.Payload
        Event.Trigger("ItemsChanged", netItems)
    end)

    local tree
    Event.On("ItemsChanged", function(items)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, items, nil, function(node, key, value)
            if key == "Name" then
                node:AddText("   Name = ")
                local t = node:AddInputText("")
                t.SameLine = true
                t.Text = value

                node:AddButton("Spawn").OnClick = function()
                    local rt = nil
                    for _, catItems in pairs(items) do
                        for _, item in pairs(catItems) do
                            if item.Name == value then
                                rt = item.RootTemplate
                                break
                            end
                        end
                    end
                    Net.RCE("Item.Create('%s', '', '%s'):Spawn(Osi.GetPosition(RCE:Character()))", value, rt)
                        :After(function(_, err)
                            L.Dump(err)
                        end)
                end

                return true
            end
            if key == "RootTemplate" then
                local nodeLoaded = false

                node.OnClick = function(v)
                    if nodeLoaded then
                        return
                    end

                    local temp = Ext.Template.GetTemplate(value)
                    if temp then
                        Components.Tree(node, UT.Clean(temp), "RootTemplate = " .. value)

                        node:AddText("   DisplayName = ")
                        node:AddText(Ext.Loca.GetTranslatedString(temp.DisplayName.Handle.Handle)).SameLine = true

                        node:AddText("   Icon = ")
                        node:AddImage(temp.Icon).SameLine = true
                    end

                    nodeLoaded = true
                end

                return true -- replace node
            end
        end)
    end)

    local search = grp:AddInputText(__("Search"))
    search.IDContext = U.RandomId()
    search.OnChange = Debounce(100, function(input)
        local list = {}
        for k, items in pairs(netItems) do
            list[k] = UT.Filter(items, function(item)
                local temp = Ext.Template.GetTemplate(item.RootTemplate)
                if not temp then
                    L.Error("Template not found", item.RootTemplate, item.Name)
                    return false
                end

                if input.Text:match("^#") then
                    return US.Contains(item.Slot, input.Text:sub(2), true, true)
                        or US.Contains(item.Tab, input.Text:sub(2), true, true)
                end

                return US.Contains(item.Name, input.Text, true, true)
                    or US.Contains(Ext.Loca.GetTranslatedString(temp.DisplayName.Handle.Handle), input.Text, true, true)
            end)
        end

        Event.Trigger("ItemsChanged", list)
    end)

    local combo = grp:AddCombo(__("Rarity"))
    combo.IDContext = U.RandomId()
    combo.Options = C.ItemRarity
    combo.OnChange = function()
        search.Text = ""
        Net.Send("GetItems", { Rarity = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton(__("Reset"))
    btn.IDContext = U.RandomId()
    btn.OnClick = function()
        combo.SelectedIndex = -1
        search.Text = ""
        Net.Send("GetItems")
    end
    btn.SameLine = true

    Net.Send("GetItems")
end
