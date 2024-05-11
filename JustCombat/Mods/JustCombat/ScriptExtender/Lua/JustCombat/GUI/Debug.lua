Debug = {}

function Debug.Main(root)
    root:AddButton("Reload").OnClick = function()
        Net.Send("State")
        Net.Send("Templates")
        Net.Send("Items")
    end

    -- section State 
    local state = root:AddGroup("State")
    state:AddSeparatorText("State")

    local stateTree
    WindowEvent("StateChange", function()
        if stateTree then
            stateTree:Destroy()
        end

        stateTree = Components.Tree(state, State)
    end):Exec()

    -- section Templates 
    local templates = root:AddGroup("Templates")
    templates:AddSeparatorText("Templates")

    local templatesTree
    WindowNet("Templates", function(event)
        if templatesTree then
            templatesTree:Destroy()
        end

        templatesTree = Components.Tree(templates, event.Payload)
    end):Exec({ Payload = {} })
    Net.Send("Templates")

    -- section Items
    Debug.Items(root)
end

function Debug.Items(root)
    local grp = root:AddGroup("Items")
    grp:AddSeparatorText("Items")

    local tree
    WindowNet("Items", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload)
    end):Exec({ Payload = {} })

    local combo = grp:AddCombo("Rarity")
    combo.Options = C.ItemRarity
    combo.OnChange = function()
        Net.Send("Items", { Rarity = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton("Reset")
    btn.OnClick = function()
        combo.SelectedIndex = -1
        Net.Send("Items")
    end
    btn.SameLine = true

    Net.Send("Items")
end
