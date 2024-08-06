Debug = {}

---@param tab ExtuiTabBar
function Debug.Main(tab)
    Schedule(function()
        Event.Trigger("ToggleDebug", Mod.Debug)
    end)

    local root = tab:AddTabItem(__("Debug"))

    root:AddButton(__("Reload")).OnClick = function()
        Net.Send("SyncState")
        Net.Send("GetTemplates")
        Net.Send("GetItems")
    end

    root:AddInputInt("RogueScore", State.RogueScore or 0).OnChange = Async.Debounce(1000, function(input)
        Net.RCE("PersistentVars.RogueScore = %d", input.Value[1]).After(function()
            Net.Send("SyncState")
        end)
    end)

    root:AddInputInt("Currency", State.Currency or 0).OnChange = Async.Debounce(1000, function(input)
        Net.RCE("PersistentVars.Currency = %d", input.Value[1]).After(function()
            Net.Send("SyncState")
        end)
    end)

    -- section State
    local state = root:AddGroup(__("State"))
    state:AddSeparatorText(__("State"))

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

    return root
end

function Debug.Enemies(root)
    local grp = root:AddGroup(__("Enemies"))
    grp:AddSeparatorText(__("Enemies"))

    local tree
    Net.On("GetEnemies", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload)
    end)

    local combo = grp:AddCombo(__("Tier"))
    combo.IDContext = U.RandomId()
    combo.Options = C.EnemyTier
    combo.OnChange = function()
        Net.Send("GetEnemies", { Tier = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton(__("Reset"))
    btn.IDContext = U.RandomId()
    btn.OnClick = function()
        combo.SelectedIndex = -1
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

    local combo = grp:AddCombo(__("Rarity"))
    combo.IDContext = U.RandomId()
    combo.Options = C.ItemRarity
    combo.OnChange = function()
        Net.Send("GetItems", { Rarity = combo.Options[combo.SelectedIndex + 1] })
    end

    local search = grp:AddInputText(__("Search"))
    search.IDContext = U.RandomId()
    search.OnChange = Async.Debounce(100, function(input)
        local itemList = {}
        for k, items in pairs(netItems) do
            itemList[k] = UT.Filter(items, function(item)
                local temp = Ext.Template.GetTemplate(item.RootTemplate)
                if not temp then
                    L.Error("Template not found", item.RootTemplate, item.Name)
                    return false
                end
                return item.Name:match(US.Escape(input.Text))
                    or US.Contains(Ext.Loca.GetTranslatedString(temp.DisplayName.Handle.Handle), input.Text, true, true)
            end)
        end

        Event.Trigger("ItemsChanged", itemList)
    end)

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
