Debug = {}

function Debug.Main(root)
    local tree
    WindowEvent("StateChange", function()
        if tree then
            tree:Destroy()
        end

        tree = Components.Tree(root, State, "State")
    end)
end

