Loot = {}

-- TODO UI feedback
function Loot.Main(tab)
    local root = tab:AddTabItem(__("Loot")):AddChildWindow("")

    local btn = root:AddButton(__("Pickup All"))
    btn.IDContext = U.RandomId()
    btn.PositionOffset = { 5, 5 }
    btn.OnClick = function()
        Net.Send("PickupAll")
    end

    Components.Layout(root, 1, 1, function(layout)
        local root = layout.Cells[1][1]:AddGroup("")
        root.PositionOffset = { 5, 5 }

        root:AddSeparatorText(__("Auto-Pickup for Armor"))
        for _, rarity in pairs(C.ItemRarity) do
            Loot.Rarity(root, rarity, "Armor")
        end

        root:AddSeparatorText(__("Auto-Pickup for Weapons"))
        for _, rarity in pairs(C.ItemRarity) do
            Loot.Rarity(root, rarity, "Weapon")
        end

        root:AddSeparatorText(__("Auto-Pickup for Objects"))
        for _, rarity in pairs(C.ItemRarity) do
            Loot.Rarity(root, rarity, "Object")
        end
    end)

    local ckb = Config.Checkbox(root, "Drop Camp Clothes", "Include camp clothes in item drops", "LootIncludesCampSlot")
    ckb.PositionOffset = { 5, 5 }
end

function Loot.Rarity(root, rarity, type)
    Components.Layout(root, 2, 1, function(layout)
        local checkbox = layout.Cells[1][1]:AddCheckbox(__(rarity))
        checkbox.IDContext = U.RandomId()

        Components.Computed(checkbox, function(_, state)
            return state and state.LootFilter[type] and state.LootFilter[type][rarity]
        end, "StateChange", "Checked")

        checkbox.OnChange = function(ckb)
            Net.Send("UpdateLootFilter", { rarity, type, ckb.Checked })
        end

        local btn = layout.Cells[1][2]:AddButton(__("Pickup"))
        btn.IDContext = U.RandomId()
        btn.OnClick = function()
            Net.Send("Pickup", { rarity, type })
        end

        local btn2 = layout.Cells[1][2]:AddButton(__("Destroy"))
        btn2.IDContext = U.RandomId()
        btn2.SameLine = true
        btn2.OnClick = function()
            Net.Send("DestroyLoot", { rarity, type })
        end
    end)
end
