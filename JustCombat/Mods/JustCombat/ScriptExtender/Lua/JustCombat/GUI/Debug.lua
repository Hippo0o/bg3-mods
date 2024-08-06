Debug = {}

---@param tab ExtuiTabBar
function Debug.Main(tab)
    Schedule(function()
        Event.Trigger("ToggleDebug", Mod.Debug)
    end)

    Components.Conditional(root, function()
        local root = tab:AddTabItem("Debug")

        root:AddButton("Reload").OnClick = function()
            Net.Send("GetState")
            Net.Send("GetTemplates")
            Net.Send("GetItems")
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
        WindowNet("GetTemplates", function(event)
            if templatesTree then
                templatesTree:Destroy()
            end

            templatesTree = Components.Tree(templates, event.Payload)
        end):Exec({ Payload = {} })
        Net.Send("GetTemplates")

        -- section Items
        Debug.Items(root)

        return root
    end, "ToggleDebug")
end

function Debug.Items(root)
    local grp = root:AddGroup("Items")
    grp:AddSeparatorText("Items")

    local tree
    WindowNet("GetItems", function(event)
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(grp, event.Payload)
    end):Exec({ Payload = {} })

    local combo = grp:AddCombo("Rarity")
    combo.Options = C.ItemRarity
    combo.OnChange = function()
        Net.Send("GetItems", { Rarity = combo.Options[combo.SelectedIndex + 1] })
    end

    local btn = grp:AddButton("Reset")
    btn.OnClick = function()
        combo.SelectedIndex = -1
        Net.Send("GetItems")
    end
    btn.SameLine = true

    Net.Send("GetItems")
end
