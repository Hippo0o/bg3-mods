Control = {}

function Control.Events()
    local function handleResponse(payload)
        if payload[1] then
            Event.Trigger("Success", payload[2])
        else
            Event.Trigger("Error", payload[2])
        end
    end

    Event.On("Start", function(scenarioName, mapName)
        Net.Request("Start", {
            Scenario = scenarioName,
            Map = mapName,
        }).After(function(event)
            handleResponse(event.Payload)
        end)
    end)

    Event.On("Stop", function()
        Net.Request("Stop").After(function(event)
            handleResponse(event.Payload)
        end)
    end)

    Event.On("PingSpawns", function(data)
        Net.Request("PingSpawns", data).After(function(event)
            handleResponse(event.Payload)
        end)
    end)

    Event.On("Teleport", function(data)
        Net.Request("Teleport", data).After(function(event)
            handleResponse(event.Payload)
        end)
    end)

    Event.On("ToCamp", function()
        Net.Request("ToCamp").After(function(event)
            handleResponse(event.Payload)
        end)
    end)

    Event.On("ResumeCombat", function()
        Net.Request("ResumeCombat").After(function(event)
            handleResponse(event.Payload)
        end)
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
        end):Exec()
    end)

    root:AddSeparatorText(__("Logs"))

    local scrollable = root:AddChildWindow(U.RandomId())

    ---@type ExtuiInputText
    local textBox = scrollable:AddText("")

    Event.On("Start", function()
        textBox.Label = ""
    end)
    Components.Computed(textBox, function(_, event)
        return textBox.Label .. event.Payload[1] .. "\n"
    end, Net.EventName("PlayerNotify"), "Label")
end

function Control.StartPanel(root)
    return Components.Layout(root, 2, 1, function(startLayout)
        startLayout.Cells[1][1]:AddText(__("Scenarios"))
        startLayout.Cells[1][2]:AddText(__("Maps"))
        local listCols = startLayout.Cells[1]

        local scenarioSelection = Components.Selection(listCols[1])
        local scenarioSelPaged = Components.Paged(scenarioSelection.Root, {}, 5)
        local mapSelection = Components.Selection(listCols[2])
        local mapSelPaged = Components.Paged(mapSelection.Root, {}, 5)

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
            scenarioSelPaged.UpdateItems(scenarioSelection.Selectables)

            mapSelection.AddItem("Random", nil)
            for i, item in ipairs(event.Payload.Maps) do
                mapSelection.AddItem(item.Name, item.Name)
            end
            mapSelPaged.UpdateItems(mapSelection.Selectables)
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

        local cond = Components.Conditional(layout.Cells[1][1], function(cond)
            local b = cond.Root:AddButton(__("Stop"))
            b.OnClick = function()
                Event.Trigger("Stop")
            end

            return b
        end, "StateChange")
        cond.OnEvent = function(state)
            return state.Scenario and (state.Scenario.OnMap == false or state.Scenario.Round == 0)
        end

        layout.Cells[1][1]:AddButton(__("Go to Camp")).OnClick = function(button)
            Event.Trigger("ToCamp")
        end

        local btn = layout.Cells[1][1]:AddButton(__("Next Round"))
        btn.SameLine = true
        btn.OnClick = function(button)
            Event.Trigger("ResumeCombat")
        end

        layout.Cells[1][2]:AddButton(__("Teleport")).OnClick = function()
            Event.Trigger("Teleport", { Map = State.Scenario.Map.Name, Restrict = true })
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
