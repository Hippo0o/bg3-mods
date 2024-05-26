Control = {}

---@param tab ExtuiTabBar
function Control.Main(tab)
    local root = tab:AddTabItem(__("Play"))

    Event.On("Start", function(scenarioName, mapName)
        Net.Request("Start", {
            Scenario = scenarioName,
            Map = mapName,
        }).After(function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
            Net.Send("SyncState")
        end)
    end)

    Event.On("Stop", function()
        Net.Request("Stop").After(function()
            Net.Send("SyncState")
        end)
    end)

    Event.On("Teleport", function(data)
        Net.Request("Teleport", data).After(function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end)
    end)

    Event.On("PingSpawns", function(data)
        Net.Request("PingSpawns", data).After(function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end)
    end)

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
        end):Exec()
    end)

    root:AddSeparatorText(__("Logs"))
    Components.Layout(root, 1, 1, function(layout)
        layout.Table.ScrollY = true
        local scrollable = layout.Cells

        ---@type ExtuiInputText
        local textBox = scrollable[1][1]:AddText("")

        Event.On("Start", function()
            textBox.Label = ""
        end)
        Components.Computed(textBox, function(_, event)
            return textBox.Label .. event.Payload[1] .. "\n"
        end, Net.EventName("PlayerNotify"), "Label")
    end)
end

function Control.StartPanel(root)
    return Components.Layout(root, 2, 1, function(startLayout)
        startLayout.Cells[1][1]:AddText(__("Scenarios"))
        startLayout.Cells[1][2]:AddText(__("Maps"))
        local listCols = startLayout.Cells[1]

        local scenarioSelection = Components.Selection(listCols[1])
        local mapSelection = Components.Selection(listCols[2])

        Net.On("GetSelection", function(event)
            scenarioSelection.Reset()
            mapSelection.Reset()

            for i, item in ipairs(event.Payload.Scenarios) do
                local label = item.Name
                if item.Name == C.RoguelikeScenario then
                    label = label .. " (Score: " .. tostring(State.RogueScore) .. ")"
                end
                scenarioSelection.AddItem(label, item.Name)
            end

            mapSelection.AddItem("Random", nil)
            for i, item in ipairs(event.Payload.Maps) do
                mapSelection.AddItem(item.Name, item.Name)
            end
        end)

        Event.On("StateChange", function()
            Net.Send("GetSelection")
        end)

        listCols[1]:AddButton(__("Start")).OnClick = function(button)
            Event.Trigger("Start", scenarioSelection.Value, mapSelection.Value)
        end

        Components.Conditional(listCols[2], function(cond)
            local grp = cond.Root:AddGroup(__("Debug"))

            grp:AddButton(__("Teleport")).OnClick = function(button)
                Event.Trigger("Teleport", { Map = mapSelection.Value })
            end

            grp:AddButton(__("Ping Spawns")).OnClick = function(button)
                Event.Trigger("PingSpawns", { Map = mapSelection.Value })
            end

            grp:AddButton(__("Kill spawned")).OnClick = function()
                Net.Send("KillSpawned")
            end

            return grp
        end, "ToggleDebug").Update(Mod.Debug)
    end)
end

function Control.RunningPanel(root)
    return Components.Layout(root, 2, 2, function(layout)
        local scenarioName = layout.Cells[1][1]:AddText("")
        local mapName = layout.Cells[1][2]:AddText("")

        Components.Computed(scenarioName, function(box, state)
            if state.Scenario then
                local text = {
                    "Scenario: " .. tostring(state.Scenario.Name),
                    "Round: " .. tostring(state.Scenario.Round),
                    "Total Rounds: " .. tostring(#state.Scenario.Timeline),
                    "Killed: " .. tostring(#state.Scenario.KilledEnemies),
                    -- "Next: " .. tostring(#state.Scenario.Enemies[state.Scenario.Round + 1] or 0),
                }
                if state.Scenario.Name == C.RoguelikeScenario then
                    table.insert(text, 2, "RogueScore: " .. tostring(state.RogueScore))
                end
                return table.concat(text, "\n")
            end
        end, "StateChange")

        Components.Computed(mapName, function(box, state)
            if state.Scenario then
                return "Map: " .. tostring(state.Scenario.Map.Name)
            end
        end, "StateChange")

        layout.Cells[1][2]:AddButton(__("Teleport")).OnClick = function()
            Event.Trigger("Teleport", { Map = State.Scenario.Map.Name })
        end

        layout.Cells[1][2]:AddButton(__("Ping Spawns")).OnClick = function()
            Event.Trigger("PingSpawns", { Map = State.Scenario.Map.Name })
        end

        Components.Conditional(layout.Cells[1][2], function(cond)
            local grp = cond.Root:AddGroup(__("Debug"))

            grp:AddButton(__("Kill spawned")).OnClick = function()
                Net.Send("KillSpawned")
            end

            grp:AddButton(__("Stop")).OnClick = function()
                Event.Trigger("Stop")
            end

            return grp
        end, "ToggleDebug").Update(Mod.Debug)
    end)
end
