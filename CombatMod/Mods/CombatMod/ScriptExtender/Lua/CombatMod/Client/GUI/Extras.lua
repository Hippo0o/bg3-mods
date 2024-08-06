Extras = {}

function Extras.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem("Extras"):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }
    root:AddSeparatorText("Experimental workarounds")

    Extras.Button(
        root,
        "Remove all Entities",
        "Runs automatically if config enabled.\nWill probably fix most issues with unexpected story triggers. Has to be run per region.",
        function(btn)
            Net.Request("RemoveAllEntities"):After(DisplayResponse)
        end
    )

    root:AddSeparator()
    Extras.Button(
        root,
        "Clean Ground",
        "Clean the ground from blood and similar.\nWill also remove important map properties such as lava, swamp, water, etc.\nReload the save or switch act to restore them.",
        function(btn)
            Net.Request("ClearSurfaces"):After(DisplayResponse)
        end
    )

    root:AddSeparator()
    Extras.Button(root, "End Long Rest", "Use when stuck in night time.", function(btn)
        Net.Request("CancelLongRest"):After(DisplayResponse)
    end)
    root:AddSeparator()

    Extras.Button(root, "Cancel Dialog", "End the current dialog.", function(btn)
        Net.Request("CancelDialog"):After(DisplayResponse)
    end)

    root:AddSeparatorText("Recruit Origins (Experimental)")
    root:AddDummy(1, 1)
    for name, char in pairs(C.OriginCharacters) do
        local desc = ""

        Extras.Button(root, name, desc, function(btn)
            Net.Request("RecruitOrigin", name):After(DisplayResponse)
        end).SameLine =
            true
    end
    root:AddText("Needs to be run multiple times in some cases. May not work in all cases.")
    root:AddText("Halsin will be dead once entering Act 2 for the first time.")
    root:AddText("Level will be reset. Inventory will be emptied.")
    root:AddSeparator()
end

function Extras.Button(root, text, desc, callback)
    local root = root:AddGroup("")
    local b = root:AddButton(text)
    b.IDContext = U.RandomId()
    b.OnClick = callback
    for i, s in ipairs(US.Split(desc, "\n")) do
        root:AddText(s).SameLine = i == 1
    end
    return root
end
