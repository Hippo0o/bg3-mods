Config = {}

---@param tab ExtuiTabBar
function Config.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem(__("Config")):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }

    Net.Send("Config")

    Config.Client(root)

    root:AddSeparatorText(__("Global Settings - Host only"))

    local c8 = Config.Checkbox(root, "Play Roguelike Mode", "get continuously harder battles", "RoguelikeMode")

    local c3 = Config.Checkbox(root, "Challenge Mode", "apparently it was too easy", "HardMode")

    local c6 = Config.Checkbox(
        root,
        "Spawn Items At Player",
        "items will spawn at the current player's position instead the maps entry point",
        "SpawnItemsAtPlayer"
    )

    ---@type ExtuiCheckbox
    local c2 = Config.Checkbox(
        root,
        "Bypass Story",
        "skip dialogues, combat and interactions that aren't related to a scenario",
        "BypassStory"
    )

    ---@type ExtuiCheckbox
    local c2 = Config.Checkbox(
        root,
        "Clear All Entities",
        "will remove all entities from the map automatically and fix most issues with unexpected story triggers",
        "ClearAllEntities"
    )

    local c9 =
        Config.Checkbox(root, "Turn Off Notifications", "don't show ingame notifications", "TurnOffNotifications")

    local c10 = Config.Checkbox(
        root,
        "Only Host Can Buy Unlocks",
        "restrict other players in multiplayer from buying unlocks",
        "MulitplayerRestrictUnlocks"
    )

    local c2 = Config.Slider(
        root,
        "To Camp After n Seconds",
        "in roguelike, after combat, teleport back to camp automatically - set to 0 to disable auto-teleport",
        "AutoTeleport",
        0,
        120
    )

    local c5 = Config.Slider(
        root,
        "Randomize Spawn Offset",
        "randomize spawn position for more varied encounters (too high may cause issues)",
        "RandomizeSpawnOffset",
        0,
        30
    )

    local c7 = Config.Slider(
        root,
        "Exp Multiplier",
        "multiplies the experience gained by killing enemies",
        "ExpMultiplier",
        1,
        10
    )

    local c1 = Config.Checkbox(root, "Enable Debug", "some more info in the console and other debug features", "Debug")
    c1.Checked = Mod.Debug

    local text = ""
    local function showStatus(msg, append)
        if append then
            if not text:match(msg) then
                text = text .. " " .. msg
            end
        else
            text = msg
        end

        Event.Trigger("Success", text)
    end

    Net.On("Config", function(event)
        Event.Trigger("ConfigChange", event.Payload)
    end)

    Event.On("ConfigChange", function(config)
        showStatus(__("Config updated"), true)

        Mod.Debug = config.Debug
        Mod.Dev = config.Dev

        Event.Trigger("ToggleDebug", config.Debug)
    end)

    if not IsHost then
        return
    end

    -- buttons
    root:AddSeparator()
    local btn = root:AddButton(__("Persist Config"))
    btn.OnClick = function()
        showStatus(__("Persisting config..."))

        Net.Send("Config", {
            Persist = true,
        })
    end

    local btn = root:AddButton(__("Reset Config"))
    btn.SameLine = true
    btn.OnClick = function()
        showStatus(__("Resetting config..."))

        Net.Send("Config", { Reset = true })
    end

    local btn = root:AddButton(__("Default Config"))
    btn.SameLine = true
    btn.OnClick = function()
        showStatus(__("Default config..."))

        Net.Send("Config", { Default = true })
    end

    Event.On("UpdateConfig", function(config)
        Net.Send("Config", config)

        showStatus(__("Updating config..."))
    end)

    root:AddSeparator()
    local btn = root:AddButton(__("Reset Templates"))
    btn.OnClick = function()
        showStatus(__("Resetting templates..."))
        Net.Request("ResetTemplates", { Maps = true, Scenarios = true, Enemies = true, LootRates = true })
            :After(function(event)
                Net.Send("GetTemplates")
                Net.Send("GetSelection")

                showStatus(__("Templates reset"), true)
            end)
    end
    root:AddText(__("This will reset all changes you've made to the templates.")).SameLine = true

    root:AddDummy(1, 2)
end

function Config.Client(root)
    root:AddSeparatorText(__("Window Settings"))

    local c = root:AddCheckbox(__("Auto Hide"))
    c.OnChange = function(ckb)
        Settings.AutoHide = ckb.Checked
    end
    c.Checked = Settings.AutoHide
    root:AddText(__("Hide this window when the native UI is focused."))

    local c = root:AddCheckbox(__("Auto Toggle"))
    c.OnChange = function(ckb)
        Settings.AutoOpen = ckb.Checked
    end
    c.Checked = Settings.AutoOpen
    root:AddText(__("Hide this window when entering a map. Show this window when starting a scenario."))

    local k = root:AddInputText(__("Window toggle key") .. " [A-Z]")
    k.OnChange = function(input)
        input.Text = input.Text:upper():sub(1, 1)
        if not input.Text:match("[A-Z]") then
            input.Text = "U"
        end

        Settings.ToggleKey = input.Text
    end
    k.Text = Settings.ToggleKey
    k.CharsNoBlank = true
    k.CharsUppercase = true
    k.AutoSelectAll = true
    k.AlwaysOverwrite = true
    k.ItemWidth = 25
end

function Config.Checkbox(root, label, desc, field, onChange)
    root:AddSeparator()
    local checkbox = root:AddCheckbox(__(label))
    checkbox.IDContext = U.RandomId()
    root:AddText(__(desc))

    local hostValue

    checkbox.OnChange = function(ckb)
        if not IsHost then
            ckb.Checked = hostValue
            return
        end

        Event.Trigger("UpdateConfig", { [field] = ckb.Checked })
        if onChange then
            onChange(ckb)
        end
    end

    Event.On("ConfigChange", function(config)
        checkbox.Checked = config[field]
        hostValue = config[field]
    end)

    return checkbox
end

function Config.Slider(root, label, desc, field, min, max, onChange)
    root:AddSeparator()
    local slider = root:AddSliderInt(__(label), 0, min, max)
    root:AddText(__(desc))

    local hostValue

    slider.OnChange = Debounce(500, function(sld)
        if not IsHost then
            sld.Value = { hostValue, 0, 0, 0 }
            return
        end

        Event.Trigger("UpdateConfig", { [field] = sld.Value[1] })
    end)

    Event.On("ConfigChange", function(config)
        slider.Value = { config[field], 0, 0, 0 }
        hostValue = config[field]
    end)

    return slider
end
