local window = Ext.IMGUI.NewWindow("GOV")

Net.On("DollVisuals", function(event)
    Event.Trigger("BuildTree", event.Payload)
end)

window:AddButton("Prepare").OnClick = function()
    Net.Send("DollChangeAppearance", false, "DollVisuals")
end

window:AddCheckbox("Unrestricted").OnChange = function(ckb)
    Net.Send("DollChangeAppearance", ckb.Checked, "DollVisuals")
end

local tree
Event.On("BuildTree", function(data)
    if tree then
        tree:Destroy()
    end

    local function applyVisual(uuid)
        local visuals = UT.Find(data, function(node)
            for _, v in pairs(node) do
                if v.Uuid == uuid then
                    return true
                end
            end
        end)

        local visual = UT.Find(visuals, function(v)
            return v.Uuid == uuid
        end)

        if visual == nil then
            return
        end

        Net.Send("DollApplyVisual", { Uuid = uuid, Slot = visual.SlotName })
    end

    tree = Components.Tree(window, data, nil, function(node, key, value)
        if key == "Icon" then
            node:AddImage(value)
        end
        if key == "Uuid" then
            node:AddButton("Apply").OnClick = function()
                applyVisual(value)
            end
        end
    end)
end)
