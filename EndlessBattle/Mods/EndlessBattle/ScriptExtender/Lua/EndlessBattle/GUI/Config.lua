Config = {}

---@param tab ExtuiTabBar
function Config.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem(__("Config"))

    Net.Send("Config")

    ---@type ExtuiCheckbox
    local c2 = Config.Checkbox(
        root,
        "Bypass Story",
        "skip dialogues, combat and interactions that aren't related to a scenario",
        "BypassStory"
    )

    local c3 = Config.Checkbox(
        root,
        "Always Bypass Story",
        "always skip dialogues, combat and interactions even if no scenario is active",
        "BypassStoryAlways"
    )

    local c4 = Config.Checkbox(
        root,
        "Force Enter Combat",
        "more continues battle between rounds at the cost of cheesy out of combat strats",
        "ForceEnterCombat"
    )

    local c5 = Config.Slider(
        root,
        "Randomize Spawn Offset",
        "randomize spawn position for more varied encounters (too high may cause issues)",
        "RandomizeSpawnOffset",
        0,
        20
    )

    local c6 = Config.Checkbox(
        root,
        "Spawn Items At Player",
        "items will spawn at the current player's position instead the maps entry point",
        "SpawnItemsAtPlayer"
    )

    local c7 = Config.Slider(
        root,
        "Exp Multiplier",
        "multiplies the experience gained by killing enemies",
        "ExpMultiplier",
        1,
        10
    )

    local c8 =
        Config.Checkbox(root, "Play Roguelike Mode", "get continuesly harder battles automatically", "RoguelikeMode")

    local c1 = Config.Checkbox(root, "Enable Debug", "some more info in the console and other debug features", "Debug")
    c1.Checked = Mod.Debug

    local text = ""
    local function showStatus(msg, append)
        if append then
            text = text .. " " .. msg
        else
            text = msg
        end

        Event.Trigger("Success", text)
    end

    -- buttons
    root:AddSeparator()
    local btn = root:AddButton(__("Persist Config"))
    btn.OnClick = function()
        showStatus("Persisting config...")

        Net.Send("Config", {
            Debug = c1.Checked,
            BypassStory = c2.Checked,
            BypassStoryAlways = c3.Checked,
            ForceEnterCombat = c4.Checked,
            RandomizeSpawnOffset = c5.Value[1],
            SpawnItemsAtPlayer = c6.Checked,
            ExpMultiplier = c7.Value[1],
            RoguelikeMode = c8.Checked,
            Persist = true,
        })
    end

    local btn = root:AddButton(__("Reset Config"))
    btn.SameLine = true
    btn.OnClick = function()
        showStatus("Resetting config...")

        Net.Send("Config", { Reset = true })
    end

    local btn = root:AddButton(__("Default Config"))
    btn.SameLine = true
    btn.OnClick = function()
        showStatus("Default config...")

        Net.Send("Config", { Default = true })
    end

    -- events
    Net.On("Config", function(event)
        Event.Trigger("ConfigChange", event.Payload)
    end)

    Event.On("UpdateConfig", function(config)
        Net.Send("Config", config)

        showStatus("Updating config...")
    end)

    Event.On("ConfigChange", function(config)
        showStatus("Config updated", true)

        Mod.Debug = config.Debug
        c1.Checked = config.Debug
        c2.Checked = config.BypassStory
        c3.Checked = config.BypassStoryAlways
        c4.Checked = config.ForceEnterCombat
        c5.Value = { config.RandomizeSpawnOffset, 0, 0, 0 }
        c6.Checked = config.SpawnItemsAtPlayer
        c7.Value = { config.ExpMultiplier, 0, 0, 0 }
        c8.Checked = config.RoguelikeMode

        Event.Trigger("ToggleDebug", config.Debug)
    end)

    root:AddSeparator()
    local btn = root:AddButton(__("Reset Templates"))
    btn.OnClick = function()
        showStatus("Resetting templates...")
        Net.Request("ResetTemplates", { Maps = true, Scenarios = true, Enemies = true }).After(function(event)
            Net.Send("GetTemplates")
            Net.Send("GetSelection")

            showStatus("Templates reset", true)
        end)
    end
    root:AddText(__("This will reset all changes you've made to the templates.")).SameLine = true
end

function Config.Checkbox(root, label, desc, field, onChange)
    root:AddSeparator()
    local checkbox = root:AddCheckbox(__(label))
    root:AddText(__(desc))
    checkbox.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { [field] = ckb.Checked })
        if onChange then
            onChange(ckb)
        end
    end

    return checkbox
end

function Config.Slider(root, label, desc, field, min, max, onChange)
    root:AddSeparator()
    local slider = root:AddSliderInt(__(label), 0, min, max)
    root:AddText(__(desc))
    slider.OnChange = Async.Debounce(500, function(sld)
        Event.Trigger("UpdateConfig", { [field] = sld.Value[1] })
    end)

    return slider
end
