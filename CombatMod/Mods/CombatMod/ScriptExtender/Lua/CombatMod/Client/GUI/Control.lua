Control = {}

function Control.Events()
    Event.On("Start", function(scenarioName, mapName)
        Net.Request("Start", {
            Scenario = scenarioName,
            Map = mapName,
        }):After(DisplayResponse)
    end)

    Event.On("Stop", function()
        Net.Request("Stop"):After(DisplayResponse)
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
        return string.format("[%d]: %s\n%s", Ext.Utils.MonotonicTime(), event.Payload[1], textBox.Label)
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
                    label = label .. " (RogueScore: " .. tostring(State.RogueScore) .. ")"
                end

                if not State.RogueModeActive or item.Name == C.RoguelikeScenario then
                    scenarioSelection.AddItem(label, item.Name)
                end
            end
            scenarioSelPaged.UpdateItems(scenarioSelection.Selectables)

            mapSelection.AddItem("Random", nil)
            if not State.RogueModeActive then
                for i, item in ipairs(event.Payload.Maps) do
                    mapSelection.AddItem(item.Name, item.Name)
                end
            end

            mapSelPaged.UpdateItems(mapSelection.Selectables)
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
                    __("Scenario: %s", tostring(state.Scenario.Name)),
                    __("Round: %s", tostring(state.Scenario.Round)),
                    __("Total Rounds: %s", tostring(#state.Scenario.Timeline)),
                    __("Upcoming Spawns: %s", tostring(#(state.Scenario.Enemies[state.Scenario.Round + 1] or {}))),
                    __("Killed: %s", tostring(#state.Scenario.KilledEnemies)),
                }
                if state.Scenario.Name == C.RoguelikeScenario then
                    table.insert(text, 2, "RogueScore: " .. tostring(state.RogueScore))
                end
                return table.concat(text, "\n")
            end
        end, "StateChange")

        Components.Computed(mapName, function(box, state)
            if state.Scenario then
                local _, act = UT.Find(C.Regions, function(region)
                    return region == state.Scenario.Map.Region
                end)
                return __("Map: %s", string.format("%s - %s", state.Scenario.Map.Name, act))
            end
        end, "StateChange")

        layout.Cells[1][1]:AddButton(__("Stop")).OnClick = function()
            Event.Trigger("Stop")
        end

        layout.Cells[1][1]:AddButton(__("Go to Camp")).OnClick = function(button)
            Event.Trigger("ToCamp")
        end

        do
            local btn = layout.Cells[1][1]:AddButton(__("Next Round"))

            local t = btn:Tooltip()
            t:SetStyle("WindowPadding", 30, 10)
            t:AddText("Will forward 1 round. Use when fight gets stuck or you want to fight more enemies at once.")

            btn.SameLine = true
            btn.OnClick = function(button)
                Event.Trigger("ForwardCombat")
            end
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

            return grp
        end, "ToggleDebug").Update(Mod.Debug)
    end)
end
