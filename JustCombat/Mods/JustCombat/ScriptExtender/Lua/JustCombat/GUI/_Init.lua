GUI = {}
Require("JustCombat/GUI/Widgets")

local function openWindow()
    ---@type ExtuiWindow
    local window = Ext.IMGUI.NewWindow("Just Combat")

    do
        local state = {}
        Net.On("State", function(event)
            state = event.Payload
        end)

        local errorBox = GUI.EventTextbox(window, "Error", function(box, result)
            Defer(3000, function()
                box.Reset()
            end)

            return result
        end)

        -- color error red
        errorBox.Root:SetColor("Text", { 255, 0, 0, 255 })

        GUI.Layout(window, 2, 1, function(layout)
            local cellStart, cellStop = table.unpack(layout.Layout[1])
            local started = false

            Event.On("Start", function(scenarioId, mapId)
                started = true

                Net.Request("Start", function(event)
                    local success, err = table.unpack(event.Payload)
                    if not success then
                        Event.Trigger("Error", err)
                    end
                end, {
                    Scenario = scenarioId,
                    Map = mapId,
                })
            end)
            Event.On("Stop", function()
                Net.Request("Stop", function()
                    started = false
                end)
            end)

            local startLayout = GUI.Layout(cellStart, 2, 1, function(startLayout)
                startLayout.Layout[1][1]:AddText("Scenarios")
                startLayout.Layout[1][2]:AddText("Maps")
                local listCols = startLayout.Layout[1]

                local scenarioSelection = GUI.Selection(listCols[1])
                local mapSelection = GUI.Selection(listCols[2])
                Net.On("LoadSelections", function(event)
                    scenarioSelection.Reset()
                    mapSelection.Reset()

                    for i, item in ipairs(event.Payload.Scenarios) do
                        scenarioSelection.AddItem(item.Name, item.Id)
                    end

                    for i, item in ipairs(event.Payload.Maps) do
                        mapSelection.AddItem(item.Name, item.Id)
                    end
                end)

                GUI.Button(listCols[2], "Teleport", function(button)
                    Net.Send("Teleport", { Map = mapSelection.Selected })
                end)
                GUI.Button(listCols[2], "Ping Spawns", function(button)
                    Net.Send("PingSpawns", { Map = mapSelection.Selected })
                end)

                Net.Send("LoadSelections")

                GUI.Button(listCols[1], "Start", function(button)
                    Event.Trigger("Start", scenarioSelection.Selected, mapSelection.Selected)
                end)
            end)

            local stopLayout = GUI.Layout(cellStart, 1, 1, function(stopLayout)
                local cell = stopLayout.Layout[1][1]

                GUI.Button(cell, "Teleport", function(button)
                    Net.Send("Teleport", { Map = mapSelection.Selected })
                end)

                GUI.Button(cell, "Ping Spawns", function(button)
                    Net.Send("PingSpawns", { Map = mapSelection.Selected })
                end)

                GUI.Button(cell, "Stop", function(button)
                    Event.Trigger("Stop")
                end)
            end)

            Net.On("State", function(event)
                if started then
                    startLayout.Root.Visible = false
                    stopLayout.Root.Visible = true
                else
                    startLayout.Root.Visible = true
                    stopLayout.Root.Visible = false
                end
            end)
        end)
    end

    do
        ---@type ExtuiTable
        local scrollable = GUI.Layout(window, 1, 1, function(tbl)
            tbl.ScrollY = true
        end).Layout

        local notifications = GUI.EventTextbox(scrollable[1][1], Net.CreateEventName("PlayerNotify"), function(_, event)
            return event.Payload
        end)

        Net.On("PlayerNotify", function(event)
            if not started then
                Net.Send("State")
            end
        end)

        local clearButton = GUI.Button(window, "Clear", function(button)
            notifications.Reset()
        end)
    end

    -- do
    --     local state = {}
    --     local loadButton = w:AddButton("Load")
    --     local loadField = w:AddText("LoadField")
    --     loadField.Label = ""
    --
    --     loadButton.OnClick = function()
    --         state = {}
    --         loadField.Label = "Loading..."
    --         Net.Send("State")
    --     end
    --     Net.On("State", function(event)
    --         state = event.Payload
    --         loadField.Label = Ext.Json.Stringify(state)
    --     end)
    -- end
end

Net.On("OpenGUI", openWindow)
