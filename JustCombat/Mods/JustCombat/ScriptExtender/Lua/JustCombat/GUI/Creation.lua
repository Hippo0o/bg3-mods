Creation = {}

function Creation.Main(root)
    root:AddButton("Pos").OnClick = function()

        Net.Request("RCE", function(event)
            _D(event.Payload)
        end, "return Osi.GetPosition(Osi.GetHostCharacter())")

    end
end
