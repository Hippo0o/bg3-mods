Config = {}

---@param tab ExtuiTabBar
function Config.Main(tab)
    ---@type ExtuiTabItem
    local root = tab:AddTabItem("Config")

    Net.Send("Config")

    ---@type ExtuiCheckbox
    local c1 = root:AddCheckbox("Enable Debug")
    c1.Checked = Mod.Debug
    c1.OnChange = function(ckb)
        Event.Trigger("ToggleDebug", ckb.Checked)
        Event.Trigger("UpdateConfig", { Debug = ckb.Checked })
    end

    root:AddSeparator()
    local c2 = root:AddCheckbox("Bypass Story")
    root:AddText("skip dialogues, combat and interactions that aren't related to a scenario")
    c2.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { BypassStory = ckb.Checked })
    end

    root:AddSeparator()
    local c3 = root:AddCheckbox("Always Bypass Story")
    root:AddText("always skip dialogues, combat and interactions even if no scenario is active")
    c3.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { BypassStoryAlways = ckb.Checked, BypassStory = ckb.Checked or c2.Checked })
    end

    root:AddSeparator()
    local c4 = root:AddCheckbox("Force Enter Combat")
    root:AddText("more continues battle between rounds at the cost of cheesy out of combat strats")
    c4.OnChange = function(ckb)
        Event.Trigger("UpdateConfig", { ForceEnterCombat = ckb.Checked })
    end

    root:AddSeparator()
    local c5 = root:AddSliderInt("Randomize Spawn Offset", 0, 0, 50)
    root:AddText("randomize spawn position offset to for more varied encounters")
    c5.OnChange = Async.Debounce(500, function(sld)
        Event.Trigger("UpdateConfig", { RandomizeSpawnOffset = sld.Value[1] })
    end)

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

    local btn = root:AddButton("Persist Config")
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

    local btn = root:AddButton("Reset Config")
    btn.SameLine = true
    btn.OnClick = function()
        showStatus("Resetting config...")

        Net.Send("Config", { Reset = true })
    end

    local btn = root:AddButton("Default Config")
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
    end)
end
