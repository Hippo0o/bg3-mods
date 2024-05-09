State = {}
Net.On("State", function(event)
    State = event.Payload or {}
    Event.Trigger("StateChange", State)
end)

Components = {}
Require("JustCombat/GUI/Components")

Control = {}
Require("JustCombat/GUI/Control")

local window
local function openWindow()
    if window then
        return
    end
    ---@type ExtuiWindow
    window = Ext.IMGUI.NewWindow("Just Combat")

    Net.Send("State")

    local errorBox = window:AddText("")
    errorBox:SetColor("Text", { 1, 0.4, 0.4, 1 })

    Components.Computed(errorBox, "Error", function(box, result)
        Defer(3000, function()
            box.Label = ""
        end)

        return result
    end)

    Control.Main(window)

    Components.Layout(window, 1, 1, function(layout)
        layout.Root.ScrollY = true
        local scrollable = layout.Cells

        ---@type ExtuiInputText
        local textBox = scrollable[1][1]:AddText("")

        Components.Computed(textBox, Net.CreateEventName("PlayerNotify"), function(_, event)
            return textBox.Label .. event.Payload[1] .. "\n"
        end, "Label")
    end)
end

Net.On("OpenGUI", openWindow)
