ClientUnlock = {}

---@param tab ExtuiTabBar
function ClientUnlock.Main(tab)
    ---@type ExtuiTree
    local root = tab:AddTabItem(__("Unlocks"))

    Components.Computed(root:AddSeparatorText(__("Currency owned: %d   RogueScore: %d", 0, 0)), function(root, state)
        return __("Currency owned: %d   RogueScore: %d", state.Currency, state.RogueScore or 0)
    end, "StateChange")

    Event.On("StateChange", function(state)
        Event.Trigger("CurrencyChanged", state.Currency or 0)
    end):Exec(State)

    Event.ChainOn("StateChange"):After(function(self, state)
        local unlocks = state.Unlocks
        if UT.Size(unlocks) == 0 then
            return
        end
        self:Unregister()

        local cols = 3
        local nrows = math.ceil(UT.Size(unlocks) / cols)
        Components.Layout(root, cols, nrows, function(layout)
            layout.Table.Borders = true
            for i, unlock in ipairs(UT.Values(unlocks)) do
                local c = (i - 1) % cols
                local r = math.ceil(i / cols)
                local cell = layout.Cells[r][c + 1]
                ClientUnlock.Tile(cell, unlock)
            end
        end)
    end)
end

function ClientUnlock.GetStock(unlock)
    local stock = unlock.Amount - unlock.Bought
    if stock > 0 then
        return __("Stock: %s", unlock.Amount - unlock.Bought .. "/" .. unlock.Amount)
    end
    return __("Out of stock")
end

function ClientUnlock.Tile(root, unlock)
    local grp = root:AddGroup(unlock.Id)

    local icon = grp:AddIcon(unlock.Icon)
    if unlock.Description then
        icon:Tooltip():AddText(unlock.Description)
    end

    local col2 = grp:AddGroup(unlock.Id)
    col2.SameLine = true
    local cost = col2:AddText(__("Cost: %s", unlock.Cost))
    if unlock.Persistent then
        cost.Label = __("Permanent") .. "\n" .. cost.Label
    end

    local buyLabel = col2:AddText("")

    if unlock.Amount ~= nil then
        local amount = Components.Computed(buyLabel, function(root, unlock)
            return ClientUnlock.GetStock(unlock)
        end)
        amount.Update(unlock)

        Event.On("StateChange", function(state)
            for _, new in pairs(state.Unlocks) do
                if new.Id == unlock.Id then
                    amount.Update(new)
                end
            end
        end):Exec(State)
    end

    grp:AddSeparator()

    local text = grp:AddText(unlock.Name)
    if unlock.Description then
        text:Tooltip():AddText(unlock.Description)
    end

    grp:AddSeparator()
    do
        local unlock = unlock

        local notUnlocked = grp:AddText("")
        notUnlocked.Visible = not unlock.Unlocked

        if unlock.Requirement then
            if type(unlock.Requirement) ~= "table" then
                unlock.Requirement = { unlock.Requirement }
            end

            for _, req in pairs(unlock.Requirement) do
                if type(req) == "number" then
                    notUnlocked.Label = notUnlocked.Label .. __("%d RogueScore required", req) .. "\n"
                elseif type(req) == "string" then
                    local u = UT.Find(State.Unlocks, function(u)
                        return u.Id == req
                    end)
                    notUnlocked.Label = notUnlocked.Label .. __("%s required", u.Name) .. "\n"
                end
            end
        end

        local cond = Components.Conditional(grp, function()
            if unlock.Character then
                return ClientUnlock.BuyChar(grp, unlock)
            end

            return ClientUnlock.Buy(grp, unlock)
        end)
        cond.Update(unlock.Unlocked)

        Event.On("StateChange", function(state)
            for _, new in pairs(state.Unlocks) do
                if new.Id == unlock.Id then
                    unlock = new
                    cond.Update(unlock.Unlocked)
                    notUnlocked.Visible = not unlock.Unlocked
                end
            end
        end):Exec(State)
    end
end

function ClientUnlock.Buy(root, unlock)
    local grp = root:AddGroup(U.RandomId())

    ---@type ExtuiButton
    local btn = grp:AddButton(__("Buy"))
    btn.IDContext = U.RandomId()

    if unlock.Amount ~= nil then
        Event.On("StateChange", function(state)
            for _, new in pairs(state.Unlocks) do
                if new.Id == unlock.Id then
                    btn.Visible = new.Bought < new.Amount
                    return
                end
            end
        end):Exec(State)
    end

    btn.OnClick = function()
        btn:SetStyle("Alpha", 0.2)
        Net.Request("BuyUnlock", { Id = unlock.Id }).After(function(event)
            local ok, res = table.unpack(event.Payload)

            if not ok then
                Event.Trigger("Error", res)
            else
                Event.Trigger("Success", __("Unlock %s bought.", unlock.Name))
            end
            btn:SetStyle("Alpha", 1)
        end)
    end

    grp:AddText("").SameLine = true

    return grp
end

function ClientUnlock.BuyChar(root, unlock)
    local grp = root:AddGroup(U.RandomId())

    ---@type ExtuiButton
    local btn = grp:AddButton(__("Buy"))
    btn.IDContext = U.RandomId()

    ---@type ExtuiPopup
    local popup = grp:AddPopup("")
    popup.IDContext = U.RandomId()
    popup:AddSeparatorText(__("Select character"))

    local list = {}
    local function createPopup(unlock)
        for _, b in pairs(list) do
            b:Destroy()
        end
        list = {}

        for i, u in ipairs(UE.GetParty()) do
            local name
            if not u.CustomName then
                name = Localization.Get(u.DisplayName.NameKey.Handle.Handle)
            end
            if not name then
                name = u.CustomName.Name
            end

            local uuid = u.Uuid.EntityUuid

            ---@type ExtuiButton
            local b = popup:AddButton(name)
            table.insert(list, b)

            if unlock.BoughtBy[uuid] then
                b.Label = string.format("%s (%s)", name, __("bought"))
                b:SetStyle("Alpha", 0.5)
            end

            b.OnClick = function()
                b:SetStyle("Alpha", 0.2)
                Net.Request("BuyUnlock", { Id = unlock.Id, Character = uuid }).After(function(event)
                    local ok, res = table.unpack(event.Payload)

                    if not ok then
                        Event.Trigger("Error", res)
                    else
                        Event.Trigger("Success", __("Unlock %s bought for %s.", unlock.Name, u.CustomName.Name))
                    end
                    b:SetStyle("Alpha", 1)
                end)
            end
        end
    end

    Event.On("StateChange", function(state)
        for _, new in pairs(state.Unlocks) do
            if new.Id == unlock.Id then
                local buyable = new.Amount == nil or new.Bought < new.Amount
                btn.Visible = buyable
                popup.Visible = buyable
                createPopup(new)
                return
            end
        end
    end):Exec(State)

    btn.OnClick = function()
        popup:Open()
    end

    return grp
end
