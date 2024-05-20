Unlocks = {}

---@param tab ExtuiTabBar
function Unlocks.Main(tab)
    ---@type ExtuiTree
    local root = tab:AddTabItem(__("Unlocks"))

    Components.Computed(root:AddSeparatorText(__("Currency owned: %d", 0)), function(root, currency)
        return __("Currency owned: %d", currency)
    end, "CurrencyChanged")

    WindowEvent("StateChange", function(state)
        Event.Trigger("CurrencyChanged", state.Currency or 0)
    end)

    local unlocks = {
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
    }
    local cols = 3
    local nrows = math.ceil(#unlocks / cols)
    Components.Layout(root, cols, nrows, function(layout)
        layout.Table.Borders = true
        for i, unlock in ipairs(unlocks) do
            local c = (i - 1) % cols
            local r = math.ceil(i / cols)
            local cell = layout.Cells[r][c + 1]
            Unlocks.Tile(cell, i)
        end
    end)
    Unlocks.PickChar(root)
end

function Unlocks.Tile(root, i)
    root:AddIcon("GEN_Armor")
    if U.Random() > 0.5 then
        root:AddText("Locked")
    elseif U.Random() > 0.5 then
        root:AddText("Unlocked")
    else
        root:AddButton("Unlock")
    end
    root:AddText(tostring(i) .. "c").SameLine = true
end

function Unlocks.PickChar(root)
    local grid = root:AddGroup(U.RandomId())
    grid:AddText("Pick a character")

    for k, e in pairs(UE.GetParty()) do
        grid:AddButton(e.CustomName.Name)
        -- grid:AddImage(e.GameObjectVisual.Icon)
    end

    return grid
end
