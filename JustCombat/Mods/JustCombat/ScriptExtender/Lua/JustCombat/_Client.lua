Require("JustCombat/Shared")
---@type Net
local Net = Require("Shared/Net")
local Async = Require("Shared/Async")
local Utils = Require("Shared/Utils")

Ext.IMGUI.EnableDemo(true)

Net.On("OpenUI", function(_, data)
    ---@type ExtuiWindow
    local w = Ext.IMGUI.NewWindow("New Window")

    local bubu = w:AddButton("Hello World")

    local listGroup
    bubu.OnClick = function()
        if listGroup then
            listGroup:Destroy()
        end

        listGroup = w:AddGroup("Deez")
        local radios = {}
        Net.On("GibList", function(_, data)
            for i, item in ipairs(data.Payload) do
                local radio = listGroup:AddRadioButton(item, i == 1)

                radio.OnChange = function()
                    for _, r in pairs(radios) do
                        r.Active = false
                    end
                    radio.Active = true
                end

                table.insert(radios, radio)
            end
        end):Send({ id = "scenarios" })
    end

    L.Dump(w)
end)
