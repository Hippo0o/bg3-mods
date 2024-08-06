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
    combo.Options = C.EnemyTier
    combo.OnChange = function()
        Net.Send("GetEnemies", { Tier = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton(__("Reset"))
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

    local tree
    Net.On("GetItems", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload, nil, function(node, key, value)
            if key == "RootTemplate" then
                local nodeLoaded = false

                node.OnClick = function(v)
                    if nodeLoaded then
                        return
                    end

                    local temp = Ext.Template.GetTemplate(value)
                    if temp then
                        Components.Tree(node, UT.Clean(temp), "   RootTemplate = " .. value)

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
    combo.Options = C.ItemRarity
    combo.OnChange = function()
        Net.Send("GetItems", { Rarity = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton(__("Reset"))
    btn.OnClick = function()
        combo.SelectedIndex = -1
        Net.Send("GetItems")
    end
    btn.SameLine = true

    Net.Send("GetItems")
end
