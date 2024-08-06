Config = {}

---@param tab ExtuiTabBar
function Config.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem(__("Config"))

    Net.Send("Config")

    ---@type ExtuiCheckbox
    local c1 = root:AddCheckbox(__("Enable Debug"))
    c1.Checked = Mod.Debug
    root:AddText(__("some more info in the console and other debug features"))
    c1.OnChange = function(ckb)
        Event.Trigger("ToggleDebug", ckb.Checked)
        Event.Trigger("UpdateConfig", { Debug = ckb.Checked })
    end

    root:AddSeparator()
    local c2 = root:AddCheckbox(__("Bypass Story"))
    root:AddText(__("skip dialogues, combat and interactions that aren't related to a scenario"))
    c2.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { BypassStory = ckb.Checked })
    end

    root:AddSeparator()
    local c3 = root:AddCheckbox(__("Always Bypass Story"))
    root:AddText(__("always skip dialogues, combat and interactions even if no scenario is active"))
    c3.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { BypassStoryAlways = ckb.Checked, BypassStory = ckb.Checked or c2.Checked })
    end

    root:AddSeparator()
    local c4 = root:AddCheckbox(__("Force Enter Combat"))
    root:AddText(__("more continues battle between rounds at the cost of cheesy out of combat strats"))
    c4.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { ForceEnterCombat = ckb.Checked })
    end

    root:AddSeparator()
    local c5 = root:AddSliderInt(__("Randomize Spawn Offset"), 0, 0, 20)
    root:AddText(__("randomize spawn position for more varied encounters (too high may cause issues)"))
    c5.OnChange = Async.Debounce(500, function(sld)
        Event.Trigger("UpdateConfig", { RandomizeSpawnOffset = sld.Value[1] })
    end)

    root:AddSeparator()
    local c6 = root:AddCheckbox(__("Spawn Items At Player"))
    root:AddText(__("items will spawn at the current player's position instead the maps entry point"))
    c6.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { SpawnItemsAtPlayer = ckb.Checked })
    end

    root:AddSeparator()

    local status = root:AddText("")
    status:SetColor("Text", { 0.4, 1, 0.4, 1 })
    local clearStatus = Async.Debounce(2000, function(text)
        status.Label = ""
    end)
    local function showStatus(text, append)
        if append then
            text = status.Label .. text
        end

        status.Label = text .. " "
        clearStatus()
    end

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

    WindowNet("Config", function(event)
        Event.Trigger("ConfigChange", event.Payload)
    end)

    WindowEvent("UpdateConfig", function(config)
        Net.Send("Config", config)

        showStatus("Updating config...")
    end)

    WindowEvent("ConfigChange", function(config)
        showStatus("Config updated", true)

        Mod.Debug = config.Debug
        c1.Checked = config.Debug
        c2.Checked = config.BypassStory
        c3.Checked = config.BypassStoryAlways
        c4.Checked = config.ForceEnterCombat
        c5.Value = { config.RandomizeSpawnOffset, 0, 0, 0 }
        c6.Checked = config.SpawnItemsAtPlayer
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
