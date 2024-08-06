Extras = {}

function Extras.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem(__("Extras")):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }
    root:AddSeparatorText(__("Extra features"))

    root:AddSeparator()
    Extras.Button(root, "End Long Rest", "Use when stuck in night time.", function(btn)
        Net.Request("CancelLongRest"):After(DisplayResponse)
    end)
    root:AddSeparator()

    Extras.Button(root, "Cancel Dialog", "End the current dialog.", function(btn)
        Net.Request("CancelDialog"):After(DisplayResponse)
    end)

    root:AddSeparatorText(__("Recruit Origins (Experimental)"))
    root:AddDummy(1, 1)
    for name, char in pairs(C.OriginCharacters) do
        local desc = ""

        local b = Extras.Button(root, name, desc, function(btn)
            Net.Request("RecruitOrigin", name):After(DisplayResponse)
        end)

        b.SameLine = true
    end
    root:AddText(__("Needs to be run multiple times in some cases. May not work in all cases."))
    root:AddText(__("Level will be reset. Inventory will be emptied."))
    root:AddSeparator()
end

function Extras.Button(root, text, desc, callback)
    local root = root:AddGroup("")

    local b = root:AddButton(__(text))
    b.IDContext = U.RandomId()
    b.OnClick = callback
    for i, s in ipairs(US.Split(desc, "\n")) do
        root:AddText(__(s)).SameLine = i == 1
    end

    return root
end
