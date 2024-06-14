Extras = {}

function Extras.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem("Extras"):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }
    root:AddSeparatorText("Experimental workarounds")

    Extras.Button(
        root,
        "Remove all Entities",
        "Has to be run per region.\nWill probably fix most issues with unexpected story triggers.",
        function(btn)
            Net.Request("RemoveAllEntities").After(function(event)
                DisplayResponse(event.Payload)
            end)
        end
    )

    Extras.Button(root, "Cancel Dialog", "End the current dialog.", function(btn)
        Net.Request("CancelDialog").After(function(event)
            DisplayResponse(event.Payload)
        end)
    end)

    root:AddSeparatorText("Recruit Origins")
    for name, char in pairs(C.OriginCharacters) do
        local desc = ""
        if name == "Halsin" then
            desc = "Needs Remove all Entities"
        end

        Extras.Button(root, name, desc, function(btn)
            Net.Request("RecruitOrigin", name).After(function(event)
                DisplayResponse(event.Payload)
            end)
        end)
    end
end

function Extras.Button(root, text, desc, callback)
    root:AddSeparator()
    local b = root:AddButton(text)
    b.IDContext = U.RandomId()
    b.OnClick = callback
    for i, s in ipairs(US.Split(desc, "\n")) do
        root:AddText(s).SameLine = i == 1
    end
end
