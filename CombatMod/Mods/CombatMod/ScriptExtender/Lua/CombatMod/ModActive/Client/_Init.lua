IsHost = Ext.Net.IsHost()

Settings = UT.Proxy(
    table.merge({ AutoHide = false, ToggleKey = "U", AutoOpen = true }, IO.LoadJson("ClientConfig.json") or {}),
    function(value, _, raw)
        -- raw not updated yet
        Schedule(function()
            IO.SaveJson("ClientConfig.json", raw)
        end)

        return value
    end
)

Event.On("ToggleDebug", function(bool)
    Mod.Debug = bool
end)

State = {}
Net.On(
    "SyncState",
    Debounce(300, function(event)
        State = event.Payload or {}
        Event.Trigger("StateChange", State)
    end, true)
)

do
    local subtitleWidget
    local function findSubtitleWidget()
        subtitleWidget = nil

        return RetryUntil(function()
            for i = 1, 24 do
                if get(Ext.UI.GetRoot():Child(1):Child(1):Child(i), "XAMLPath", ""):match("OverheadInfo") then
                    subtitleWidget = i
                    break
                end
            end

            return subtitleWidget
        end, { retries = 60 })
    end
    findSubtitleWidget()

    local function showMessage(text, duration)
        if not subtitleWidget then
            -- L.Error("Notification not displayed: " .. text)
            WaitUntil(function()
                return subtitleWidget ~= nil
            end):After(function()
                showMessage(text, duration)
            end)
            return
        end

        xpcall(function() -- now it constantly changes child index, so this will error sometimes
            local context = Ext.UI.GetRoot():Child(1):Child(1):Child(subtitleWidget).DataContext
            context.CurrentSubtitleDuration = duration
            context.CurrentSubtitle = text
        end, function(err)
            L.Debug("Notification error")
            findSubtitleWidget():After(function()
                showMessage(text, duration)
            end)
        end)
    end

    Net.On("Notification", function(event)
        local data = event.Payload
        showMessage(data.Text, data.Duration or 3)
    end)
end

Require("CombatMod/ModActive/Client/GUI/_Init")
