Debug = {}

function Debug.Main(root)
    root:AddButton("Reload").OnClick = function()
        Net.Send("State")
        Net.Send("Templates")
    end

    local stateTree
    WindowEvent("StateChange", function()
        if stateTree then
            stateTree:Destroy()
        end

        stateTree = Components.Tree(root, State, "State")
    end)

    local templatesTree
    WindowEvent(Net.EventName("Templates"), function(event)
        if templatesTree then
            templatesTree:Destroy()
        end

        templatesTree = Components.Tree(root, event.Payload, "Templates")
    end)
    Net.Send("Templates")

end
