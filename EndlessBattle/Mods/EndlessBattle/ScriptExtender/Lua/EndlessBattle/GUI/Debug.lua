Debug = {}

---@param tab ExtuiTabBar
function Debug.Main(tab)
    Schedule(function()
        Event.Trigger("ToggleDebug", Mod.Debug)
    end)

    local root = tab:AddTabItem(__("Debug"))

    root:AddButton(__("Reload")).OnClick = function()
        Net.Send("GetState")
        Net.Send("GetTemplates")
        Net.Send("GetItems")
    end

    -- section State
    local state = root:AddGroup(__("State"))
    state:AddSeparatorText(__("State"))

    local stateTree
    WindowEvent("StateChange", function()
        if stateTree then
            stateTree:Destroy()
        end

        stateTree = Components.Tree(state, State)
    end):Exec()

    -- section Templates
    local templates = root:AddGroup(__("Templates"))
    templates:AddSeparatorText(__("Templates"))

    local templatesTree
    WindowNet("GetTemplates", function(event)
        if templatesTree then
            templatesTree:Destroy()
        end

        templatesTree = Components.Tree(templates, event.Payload)
    end):Exec({ Payload = {} })
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
    WindowNet("GetEnemies", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload)
    end):Exec({ Payload = {} })

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
    WindowNet("GetItems", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload)
    end):Exec({ Payload = {} })

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
