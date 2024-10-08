Loot = {}

-- TODO UI feedback
function Loot.Main(tab)
    local root = tab:AddTabItem(__("Loot")):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }

    if IsHost then
        local btn = root:AddButton(__("Pickup All"))
        btn.IDContext = U.RandomId()
        btn.OnClick = function()
            Net.Request("PickupAll"):After(DisplayResponse)
        end

        local btn = root:AddButton(__("Destroy All"))
        btn.IDContext = U.RandomId()
        btn.SameLine = true
        btn.OnClick = function()
            Net.Request("DestroyAll"):After(DisplayResponse)
        end
    else
        root:AddSeparatorText(__("Global Settings - Host only"))
    end

    Components.Layout(root, 1, 1, function(layout)
        local root = layout.Cells[1][1]:AddGroup("")

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

        root:AddSeparatorText(__("Auto-Pickup for Combat Objects"))
        for _, rarity in pairs(C.ItemRarity) do
            Loot.Rarity(root, rarity, "CombatObject")
        end
    end)

    local ckb = Config.Checkbox(root, "Drop Camp Clothes", "Include camp clothes in item drops", "LootIncludesCampSlot")

    root:AddSeparatorText(__("Mod Item Blacklist"))
    root:AddText(__("Blacklisted mods will not have their items dropped."))

    Net.Request("GetFilterableModList"):After(function(event)
        local list = table.values(event.Payload)

        table.sort(list, function(a, b)
            return a.Name < b.Name
        end)
        L.Dump(list)

        for _, mod in pairs(list) do
            Loot.BlacklistMod(root, mod)
        end
    end)
end

function Loot.Rarity(root, rarity, type)
    Components.Layout(root, 2, 1, function(layout)
        local checkbox = layout.Cells[1][1]:AddCheckbox(__(rarity))
        checkbox.IDContext = U.RandomId()

        Components.Computed(checkbox, function(_, state)
            return state and state.LootFilter[type] and state.LootFilter[type][rarity]
        end, "StateChange", "Checked")

        checkbox.OnChange = function(ckb)
            if not IsHost then
                ckb.Checked = not ckb.Checked
                return
            end
            Net.Request("UpdateLootFilter", { rarity, type, ckb.Checked }):After(DisplayResponse)
        end

        local btn = layout.Cells[1][2]:AddButton(__("Pickup"))
        btn.IDContext = U.RandomId()
        btn.OnClick = function()
            Net.Request("Pickup", { rarity, type }):After(DisplayResponse)
        end

        local btn2 = layout.Cells[1][2]:AddButton(__("Destroy"))
        btn2.IDContext = U.RandomId()
        btn2.SameLine = true
        btn2.OnClick = function()
            Net.Request("DestroyLoot", { rarity, type }):After(DisplayResponse)
        end
    end)
end

function Loot.BlacklistMod(root, mod)
    local checkbox = root:AddCheckbox(mod.Name .. " - " .. mod.Id)
    checkbox.IDContext = U.RandomId()
    checkbox.OnChange = function(ckb)
        if not IsHost then
            ckb.Checked = not ckb.Checked
            return
        end

        Net.Request("UpdateModFilter", { mod.Id, ckb.Checked }):After(DisplayResponse)
    end

    checkbox.Checked = mod.Blacklist
end
