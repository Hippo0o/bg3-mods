Config = {}

---@param tab ExtuiTabBar
function Config.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem(__("Config")):AddChildWindow(""):AddGroup("")
    root.PositionOffset = { 5, 5 }

    Net.Send("Config")

    Config.Client(root)

    root:AddSeparatorText(__("Global Settings - Host only"))

    Config.Checkbox(root, "Play Roguelike Mode", "Play continuously harder random battles", "RoguelikeMode")

    Config.Checkbox(root, "Challenge Mode", "A challenge for experienced players. Increases Encounter Budget, increases rate of Enemy Scaling, and allows more powerful monsters to arrive sooner.", "HardMode")

    Config.Checkbox(root, "Hell Mode", "An unfair challenge for players who want a punishing experience. Powerful monsters will arrive much sooner and begin swarming.", "SuperHardMode")

    Config.Checkbox(
        root,
        "Spawn Items At Player",
        "Items will spawn at the current player's position instead of the map's entry point.",
        "SpawnItemsAtPlayer"
    )

    ---@type ExtuiCheckbox
    Config.Checkbox(
        root,
        "Bypass Story",
        "Skip dialogues, combat and interactions that aren't related to Roguelike mode.",
        "BypassStory"
    )

    ---@type ExtuiCheckbox
    Config.Checkbox(
        root,
        "Clear All Entities",
        "Will remove all entities from the map automatically and fix most issues with unexpected story triggers. (Most likely required)",
        "ClearAllEntities"
    )

    Config.Checkbox(root, "Turn Off Notifications", "Don't show ingame notifications.", "TurnOffNotifications")

    Config.Checkbox(
        root,
        "Only Host Can Buy Unlocks",
        "Restrict other players in multiplayer from buying unlocks.",
        "MulitplayerRestrictUnlocks"
    )

    Config.Checkbox(root, "Enable Swarm AI", "Group distant enemies for faster turns", "GroupDistantEnemies")

    Config.Slider(
        root,
        "To Camp After n Seconds",
        "In roguelike mode, teleport back to camp after combat automatically. Set to 0 to disable auto-teleport",
        "AutoTeleport",
        0,
        120
    )

    Config.Slider(
        root,
        "Enemy Stat Scaling Modifier",
        "In roguelike mode, scale the stats of enemies based on this number.",
        "ScalingModifier",
        0,
        100
    )

    Config.Slider(
        root,
        "Randomize Spawn Offset",
        "Randomize spawn position for more varied encounter placement. (High values can result in spawns inside walls or out of bounds)",
        "RandomizeSpawnOffset",
        0,
        30
    )

    Config.Slider(root, "Exp Multiplier", "Multiplies the experience gained by killing enemies", "ExpMultiplier", 1, 10)

    local c1 = Config.Checkbox(root, "Enable Debug", "More info in the console and other debug features", "Debug")
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

        if onChange then
            onChange(ckb)
        end

        Event.Trigger("UpdateConfig", { [field] = ckb.Checked })
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

        if onChange then
            onChange(sld)
        end

        Event.Trigger("UpdateConfig", { [field] = sld.Value[1] })
    end)

    Event.On("ConfigChange", function(config)
        slider.Value = { config[field], 0, 0, 0 }
        hostValue = config[field]
    end)

    return slider
end
