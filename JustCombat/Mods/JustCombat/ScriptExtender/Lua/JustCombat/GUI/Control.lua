Control = {}

---@param tab ExtuiTabBar
function Control.Main(tab)
    local root = tab:AddTabItem(__("Main"))

    WindowEvent("Start", function(scenarioName, mapName)
        Net.Request("Start", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
            Net.Send("GetState")
        end, {
            Scenario = scenarioName,
            Map = mapName,
        })
    end)

    WindowEvent("Stop", function()
        Net.Request("Stop", function()
            Net.Send("GetState")
        end)
    end)

    WindowEvent("Teleport", function(data)
        Net.Request("Teleport", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end, data)
    end)

    WindowEvent("PingSpawns", function(data)
        Net.Request("PingSpawns", function(event)
            local success, err = table.unpack(event.Payload)
            if not success then
                Event.Trigger("Error", err)
            end
        end, data)
    end)

    local errorBox = root:AddText("")
    errorBox:SetColor("Text", { 1, 0.4, 0.4, 1 })

    Components.Computed(errorBox, function(box, result)
        Defer(3000, function()
            box.Label = ""
        end)

        return result
    end, "Error")

    local header = root:AddSeparatorText("")
    Components.Layout(root, 1, 2, function(layout)
        local cellStart, cellStop = layout.Cells[1][1], layout.Cells[2][1]

        local startLayout = Control.StartPanel(cellStart)

        local stopLayout = Control.RunningPanel(cellStop)

        WindowEvent("StateChange", function(state)
            if state and state.Scenario then
                startLayout.Root.Visible = false
                stopLayout.Root.Visible = true
                header.Label = __("Running")
            else
                startLayout.Root.Visible = true
                stopLayout.Root.Visible = false
                header.Label = __("Start Menu")
            end
        end):Exec()
    end)

    root:AddSeparatorText(__("Logs"))
    Components.Layout(root, 1, 1, function(layout)
        layout.Root.ScrollY = true
        local scrollable = layout.Cells

        ---@type ExtuiInputText
        local textBox = scrollable[1][1]:AddText("")

        WindowEvent("Start", function()
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

        local scenarioSelection = Components.RadioList(listCols[1])
        local mapSelection = Components.RadioList(listCols[2])

        WindowNet("GetSelection", function(event)
            scenarioSelection.Reset()
            mapSelection.Reset()

            for i, item in ipairs(event.Payload.Scenarios) do
                scenarioSelection.AddItem(item.Name, item.Name)
            end

            for i, item in ipairs(event.Payload.Maps) do
                mapSelection.AddItem(item.Name, item.Name)
            end
        end)

        Net.Send("GetSelection")

        listCols[1]:AddButton(__("Start")).OnClick = function(button)
            Event.Trigger("Start", scenarioSelection.Value, mapSelection.Value)
        end

        Components.Conditional(listCols[2], function(cond)
            local b1 = cond.Root:AddButton(__("Teleport"))
            b1.OnClick = function(button)
                Event.Trigger("Teleport", { Map = mapSelection.Value })
            end

            local b2 = cond.Root:AddButton(__("Ping Spawns"))
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

        Components.Computed(scenarioName, function(box, state)
            if state.Scenario then
                return table.concat({
                    "Scenario: " .. tostring(state.Scenario.Name),
                    "Round: " .. tostring(state.Scenario.Round),
                    "Killed: " .. tostring(#state.Scenario.KilledEnemies),
                    -- "Next: " .. tostring(#state.Scenario.Enemies[state.Scenario.Round + 1] or 0),
                }, "\n")
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

        layout.Cells[1][1]:AddButton(__("Stop")).OnClick = function()
            Event.Trigger("Stop")
        end
    end)
end