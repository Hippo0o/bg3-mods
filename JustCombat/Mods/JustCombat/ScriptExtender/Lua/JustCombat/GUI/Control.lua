function Control.Main(window)
    Event.On("Start", function(scenarioName, mapName)
        Net.Request("Start", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
            Net.Send("State")
        end, {
            Scenario = scenarioName,
            Map = mapName,
        })
    end)

    Event.On("Stop", function()
        Net.Request("Stop", function()
            Net.Send("State")
        end)
    end)

    Event.On("Teleport", function(data)
        Net.Request("Teleport", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end, data)
    end)

    Event.On("PingSpawns", function(data)
        Net.Request("PingSpawns", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end, data)
    end)

    Components.Layout(window, 1, 2, function(layout)
        local cellStart, cellStop = layout.Cells[1][1], layout.Cells[2][1]

        local startLayout = Control.StartPanel(cellStart)

        local stopLayout = Control.RunningPanel(cellStop)

        Event.On("StateChange", function(state)
            if state and state.Scenario then
                startLayout.Root.Visible = false
                stopLayout.Root.Visible = true
            else
                startLayout.Root.Visible = true
                stopLayout.Root.Visible = false
            end
        end):Exec()
    end)
end

function Control.StartPanel(root)
    return Components.Layout(root, 2, 1, function(startLayout)
        startLayout.Cells[1][1]:AddText("Scenarios")
        startLayout.Cells[1][2]:AddText("Maps")
        local listCols = startLayout.Cells[1]

        local scenarioSelection = Components.RadioList(listCols[1])
        local mapSelection = Components.RadioList(listCols[2])
        Net.On("LoadSelections", function(event)
            scenarioSelection.Reset()
            mapSelection.Reset()

            for i, item in ipairs(event.Payload.Scenarios) do
                scenarioSelection.AddItem(item.Name, item.Name)
            end

            for i, item in ipairs(event.Payload.Maps) do
                mapSelection.AddItem(item.Name, item.Name)
            end
        end)

        Net.Send("LoadSelections")

        listCols[1]:AddButton("Start").OnClick = function(button)
            Event.Trigger("Start", scenarioSelection.Value, mapSelection.Value)
        end

        Components.Conditional(listCols[2], function(cond)
            local b1 = cond.Root:AddButton("Teleport")
            b1.OnClick = function(button)
                Event.Trigger("Teleport", { Map = mapSelection.Value })
            end

            local b2 = cond.Root:AddButton("Ping Spawns")
            b2.OnClick = function(button)
                Event.Trigger("PingSpawns", { Map = mapSelection.Value })
            end

            return { b1, b2 }
        end, "ToggleDebug").Update(Mod.Debug)
    end)
end

function Control.RunningPanel(root)
    return Components.Layout(root, 2, 2, function(layout)
        local scenarioName = layout.Cells[1][1]:AddText("")
        local mapName = layout.Cells[1][2]:AddText("")

        Components.Computed(scenarioName, "StateChange", function(box, state)
            if state.Scenario then
                return "Scenario: " .. tostring(state.Scenario.Name)
            end
        end)

        Components.Computed(mapName, "StateChange", function(box, state)
            if state.Scenario then
                return "Map: " .. tostring(state.Scenario.Map.Name)
            end
        end)

        layout.Cells[1][2]:AddButton("Teleport").OnClick = function()
            Event.Trigger("Teleport", { Map = State.Scenario.Map.Name })
        end

        layout.Cells[1][2]:AddButton("Ping Spawns").OnClick = function()
            Event.Trigger("PingSpawns", { Map = State.Scenario.Map.Name })
        end

        layout.Cells[1][1]:AddButton("Stop").OnClick = function()
            Event.Trigger("Stop")
        end
    end)
end
