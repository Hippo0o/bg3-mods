Debug = {}

function Debug.Main(root)
    root:AddButton("Reload").OnClick = function()
        Net.Send("State")
    end
    local tree
    WindowEvent("StateChange", function()
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(root, State, "State")
    end)
end
