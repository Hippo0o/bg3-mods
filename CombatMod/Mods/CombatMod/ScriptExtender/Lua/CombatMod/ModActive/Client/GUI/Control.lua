Control = {}

function Control.Events()
    Event.On("Start", function(scenarioName, mapName, difficultyName)
        Net.Request("Start", {
            Scenario = scenarioName,
            Map = mapName,
            Difficulty = difficultyName,
        }):After(DisplayResponse)
    end)

    Event.On("Stop", function()
        Net.Request("Stop"):After(DisplayResponse)
    end)

    Event.On("MarkSpawns", function(data)
        Net.Request("MarkSpawns", data):After(DisplayResponse)
    end)

    Event.On("PingSpawns", function(data)
        Net.Request("PingSpawns", data):After(DisplayResponse)
    end)

    Event.On("Teleport", function(data)
        Net.Request("Teleport", data):After(DisplayResponse)
    end)

    Event.On("ToCamp", function()
        Net.Request("ToCamp"):After(DisplayResponse)
    end)

    Event.On("ForwardCombat", function()
        Net.Request("ForwardCombat"):After(DisplayResponse)
    end)
end

---@param tab ExtuiTabBar
function Control.Main(tab)
    Control.Events()

    local root = tab:AddTabItem(__("Play"))

    local header = root:AddSeparatorText("")
    Components.Layout(root, 1, 2, function(layout)
        local cellStart, cellStop = layout.Cells[1][1], layout.Cells[2][1]

        local startLayout = Control.StartPanel(cellStart)

        local stopLayout = Control.RunningPanel(cellStop)

        Event.On("StateChange", function(state)
            if state and state.Scenario then
                startLayout.Table.Visible = false
                stopLayout.Table.Visible = true
                header.Label = __("Running")
            else
                startLayout.Table.Visible = true
                stopLayout.Table.Visible = false
                header.Label = __("Start Menu")
            end

            if state and state.RogueModeActive then
                header.Label = header.Label .. " - RogueScore: " .. tostring(state.RogueScore)
            end
        end):Exec()
    end)

    root:AddSeparator()
    root:AddText("")
    root:AddText(
        __("The encounter budget increases as your RogueScore increases and scales faster with higher difficulties.")
    )
    root:AddText("")
    root:AddText(
        __(
            "'Bias' refers to the way that budget is spent.\nHigh Bias leans toward selecting expensive monsters.\nLow Bias leans toward selecting many cheap monsters."
        )
    )
    root:AddText("")
    root:AddText(
        __(
            "Lone Wolf Mode is recommended for players who want to play solo.\nIt can be enabled on the Config tab, and it can be used in conjunction with Challenge Mode or Hell Mode.\nRemember to Reset Templates after enabling or disabling Lone Wolf Mode."
        )
    )
    root:AddText("")
    root:AddSeparator()

    root:AddSeparatorText(__("Logs"))

    local scrollable = root:AddChildWindow(U.RandomId())

    ---@type ExtuiInputText
    local textBox = scrollable:AddText("")

    Event.On("Start", function()
        textBox.Label = ""
    end)
    Components.Computed(textBox, function(_, event)
        return string.format("[%d]: %s\n%s", Ext.Utils.MonotonicTime(), event.Payload[1], textBox.Label)
    end, Net.EventName("PlayerNotify"), "Label")
end

function Control.StartPanel(root)
    return Components.Layout(root, 3, 1, function(startLayout)
        startLayout.Cells[1][1]:AddText(__("Scenarios"))
        startLayout.Cells[1][2]:AddText(__("Difficulty"))
        startLayout.Cells[1][3]:AddText(__("Maps"))
        local listCols = startLayout.Cells[1]

        local scenarioSelection = Components.Selection(listCols[1])
        local scenarioSelPagination = Components.Pagination(scenarioSelection.Root, {}, 5)
        local difficultySelection = Components.Selection(listCols[2])
        local difficultySelPagination = Components.Pagination(difficultySelection.Root, {}, 5)
        local mapSelection = Components.Selection(listCols[3])
        local mapSelPagination = Components.Pagination(mapSelection.Root, {}, 5)

        Net.On("GetSelection", function(event)
            scenarioSelection.Reset()
            mapSelection.Reset()
            difficultySelection.Reset()

            for i, item in ipairs(event.Payload.Scenarios) do
                local label = item.Name
                scenarioSelection.AddItem(label, item.Name)
            end
            scenarioSelPagination.UpdateItems(scenarioSelection.Selectables)

            local t1 = difficultySelection.AddItem(__("Regular Mode"), 0):Tooltip()
            t1:SetStyle("WindowPadding", 30, 10)
            t1:AddText(__("Regular Mode: Variety, power, and quantity of monsters scales gently."))
            local t2 = difficultySelection.AddItem(__("Challenge Mode"), 1):Tooltip()
            t2:SetStyle("WindowPadding", 30, 10)
            t2:AddText(__("Challenge Mode: A challenge for experienced players."))
            local t3 = difficultySelection.AddItem(__("Hell Mode"), 2):Tooltip()
            t3:SetStyle("WindowPadding", 30, 10)
            t3:AddText(__("Hell Mode: For players who want a punishing, unfair experience."))

            difficultySelPagination.UpdateItems(difficultySelection.Selectables)

            mapSelection.AddItem("Random", nil)
            if not State.RogueModeActive then
                for i, item in ipairs(event.Payload.Maps) do
                    local label = item.Name
                    if item.Author then
                        label = item.Author .. "'s " .. label
                    end

                    mapSelection.AddItem(label, item.Name)
                end
            end

            mapSelPagination.UpdateItems(mapSelection.Selectables)
        end)

        local startButton = listCols[1]:AddButton(__("Start"))
        startButton.IDContext = U.RandomId()

        local pressed = false
        Event.On("StateChange", function()
            Net.Send("GetSelection")
            pressed = false
            startButton:SetStyle("Alpha", 1)
        end)

        startButton.OnClick = function(button)
            if pressed then
                return
            end
            pressed = true
            startButton:SetStyle("Alpha", 0.5)
            Event.Trigger("Start", scenarioSelection.Value, mapSelection.Value, difficultySelection.Value)
        end

        Components.Conditional(listCols[3], function(cond)
            local grp = cond.Root:AddGroup(__("Debug"))

            grp:AddButton(__("Teleport")).OnClick = function(button)
                Event.Trigger("Teleport", { Map = mapSelection.Value })
            end

            local b2 = grp:AddButton(__("Ping Spawns"))
            b2.SameLine = true
            b2.OnClick = function(button)
                Event.Trigger("PingSpawns", { Map = mapSelection.Value })
            end

            local b3 = grp:AddButton(__("Kill spawned"))
            b3.OnClick = function()
                Net.Send("KillSpawned")
            end

            return grp
        end, "ToggleDebug").Update(Mod.Debug)

        listCols[1]:AddButton(__("Go to Camp")).OnClick = function(button)
            Event.Trigger("ToCamp")
        end
    end)
end

function Control.RunningPanel(root)
    return Components.Layout(root, 3, 2, function(layout)
        local scenarioName = layout.Cells[1][1]:AddText("")
        local difficultyName = layout.Cells[1][2]:AddText("")
        local mapName = layout.Cells[1][3]:AddText("")

        Components.Computed(scenarioName, function(box, state)
            if state.Scenario then
                local text = {
                    __("Scenario: %s", tostring(state.Scenario.Name)),
                    __("Round: %s", tostring(state.Scenario.Round)),
                    __("Total Rounds: %s", tostring(#state.Scenario.Timeline)),
                    __("Upcoming Spawns: %s", tostring(#(state.Scenario.Enemies[state.Scenario.Round + 1] or {}))),
                    __("Killed: %s", tostring(#state.Scenario.KilledEnemies)),
                }
                return table.concat(text, "\n")
            end
        end, "StateChange")

        Components.Computed(difficultyName, function(box, state)
            if state.Scenario then
                if state.HardMode then
                    return __("Difficulty: Challenge Mode")
                elseif state.SuperHardMode then
                    return __("Difficulty: Hell Mode")
                else
                    return __("Difficulty: Regular Mode")
                end
            end
        end, "StateChange")

        Components.Computed(mapName, function(box, state)
            if state.Scenario then
                local _, act = table.find(C.Regions, function(region)
                    return region == state.Scenario.Map.Region
                end)

                local mapName = state.Scenario.Map.Name
                if state.Scenario.Map.Author then
                    mapName = state.Scenario.Map.Author .. "'s " .. mapName
                end

                return __("Map: %s", string.format("%s - %s", mapName, act))
            end
        end, "StateChange")

        layout.Cells[1][1]:AddButton(__("Stop")).OnClick = function()
            Event.Trigger("Stop")
        end

        layout.Cells[1][1]:AddButton(__("Go to Camp")).OnClick = function()
            Event.Trigger("ToCamp")
        end

        Components.Conditional(layout.Cells[1][1], function(cond)
            local btn = cond.Root:AddButton(__("Next Round"))

            local t = btn:Tooltip()
            t:SetStyle("WindowPadding", 30, 10)
            t:AddText("Will forward 1 round. Use when fight gets stuck or you want to fight more enemies at once.")

            btn.SameLine = true
            btn.OnClick = function(button)
                Event.Trigger("ForwardCombat")
            end

            cond.OnEvent = function(state)
                return state.Scenario and state.Scenario.OnMap
            end

            return btn
        end, "StateChange")

        layout.Cells[1][3]:AddButton(__("Teleport")).OnClick = function()
            Event.Trigger("Teleport", { Map = State.Scenario.Map.Name, Restrict = true })
        end

        -- layout.Cells[1][2]:AddButton(__("Ping Spawns")).OnClick = function()
        --     Event.Trigger("PingSpawns", { Map = State.Scenario.Map.Name })
        -- end

        layout.Cells[1][3]:AddButton(__("Highlight Spawns")).OnClick = function()
            Event.Trigger("MarkSpawns", { Map = State.Scenario.Map.Name })
        end

        Components.Conditional(layout.Cells[1][3], function(cond)
            local grp = cond.Root:AddGroup(__("Debug"))

            grp:AddButton(__("Kill spawned")).OnClick = function()
                Net.Send("KillSpawned")
            end

            grp:AddButton(__("Ping Spawns")).OnClick = function()
                Event.Trigger("PingSpawns", { Map = State.Scenario.Map.Name })
            end

            return grp
        end, "ToggleDebug").Update(Mod.Debug)
    end)
end
