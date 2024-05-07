Require("JustCombat/Shared")
---@type Net
local Net = Require("Shared/Net")
local Async = Require("Shared/Async")
local Utils = Require("Shared/Utils")

local function GUI()
    ---@type ExtuiWindow
    local w = Ext.IMGUI.NewWindow("Just Combat")

    do
        local state = {}
        local loadButton = w:AddButton("Load")
        local loadField = w:AddText("LoadField")
        loadField.Label = ""

        loadButton.OnClick = function()
            state = {}
            loadField.Label = "Loading..."
            Net.Send("State")
        end
        Net.On("State", function(event)
            state = event.Payload
            loadField.Label = Ext.Json.Stringify(state)
        end)
    end

    do
        local names = { "Scenarios", "Maps" }
        local selection = w:AddTable("Selection", #names):AddRow()
        local cells = UT.Map(names, function()
            return selection:AddCell()
        end)
        for i, name in pairs(names) do
            cells[i]:AddText(name)
        end

        local lists = {}
        for i, name in pairs(names) do
            local cell = cells[i]
            local grp = cell:AddGroup(name)

            local list = {}
            list.Selected = 1

            local radios = {}
            function list.clearSelection()
                grp:Destroy()
                grp = cell:AddGroup(name)
                radios = {}
            end

            function list.addSelection(label, value)
                local radio = grp:AddRadioButton(#radios, value == list.Selected)
                radio.Label = label

                radio.OnChange = function()
                    for _, r in pairs(radios) do
                        r.Active = false
                    end
                    radio.Active = true
                    list.Selected = value
                end
                table.insert(radios, radio)
            end
            table.insert(lists, list)
        end

        for i, list in pairs(lists) do
            Net.Request("GibList", function(event)
                list.clearSelection()

                for i, item in ipairs(event.Payload) do
                    list.addSelection(item.Name, item.Id)
                end
                if i == 2 then
                    cells[2]:AddButton("Teleport").OnClick = function()
                        Net.Send("Teleport", { Map = lists[2].Selected })
                    end
                end
            end, names[i])
        end

        ---@type ExtuiButton
        local startButton = w:AddButton("Start")
        local errorLabel = w:AddText("StartError")
        errorLabel.SameLine = true
        errorLabel.Label = ""

        local started = false
        Net.On("State", function(event)
            started = event.Payload.Scenario ~= nil
            if started then
                startButton.Label = "Stop"
            else
                startButton.Label = "Start"
            end
        end)

        startButton.OnClick = function()
            if started then
                Net.Send("Stop")
            else
                Net.Request("Start", function(event)
                    if event.Payload[1] then
                        errorLabel.Label = ""
                    else
                        errorLabel.Label = event.Payload[2]
                    end
                end, { Scenario = lists[1].Selected, Map = lists[2].Selected })
            end
            Net.Send("State")
        end
    end

    do
        ---@type ExtuiTable
        local scrollable = w:AddTable("Scrollable", 1)
        scrollable.ScrollY = true

        ---@type ExtuiGroup
        local sr = scrollable:AddRow()
        local fillMe = sr:AddCell()

        Net.On("PlayerNotify", function(event)
            if not started then
                Net.Send("State")
            end
            fillMe:AddText(table.concat(event.Payload, "	"))
        end)

        local clearButton = w:AddButton("Clear")
        clearButton.OnClick = function()
            fillMe:Destroy()
            fillMe = sr:AddCell()
        end
    end
end

Async.Defer(1000, GUI)
