Creation = {}

---@param tab ExtuiTabBar
function Creation.Main(tab)
    ---@type ExtuiTree
    local root = tab:AddTabItem(__("Creation"))

    do
        ---@type ExtuiInputText
        local posBox = root:AddInputText("List")
        posBox.Multiline = true

        local pb = root:AddButton(__("Pos"))
        pb.SameLine = true

        local ca = root:AddButton(__("Clear Area"))
        ca.SameLine = true

        local pi = root:AddInputText(__("Pos"))
        pi.IDContext = U.RandomId()
        pi.Text = "0, 0, 0"
        local ping = root:AddButton(__("Ping"))
        ping.SameLine = true
        local tp = root:AddButton(__("TP"))
        tp.SameLine = true

        pb.OnClick = function()
            local host = UE.GetHost()
            local region = host.Level.LevelName
            L.Dump("Host", host.CustomName)
            Net.RCE("return Osi.GetPosition(RCE:Character())").After(function(ok, x, y, z)
                if not ok then
                    return
                end

                Net.RCE('Osi.RequestPing(%s, %s, %s, "", "")', x, y, z)
                posBox.Text = posBox.Text .. string.format("%s: %s, %s, %s", region, x, y, z) .. "\n"
                pi.Text = string.format("%s, %s, %s", x, y, z)
            end)
        end

        ca.OnClick = function()
            Net.Send("KillNearby")
        end

        ping.OnClick = function()
            local x, y, z = table.unpack(US.Split(pi.Text, ","))
            x = x:match("[-]?%d+")
            y = y:match("[-]?%d+")
            z = z:match("[-]?%d+")
            Net.RCE('Osi.RequestPing(%d, %d, %d, "", "")', x, y, z).After(function(ok, err)
                if not ok then
                    Event.Trigger("Error", err)
                end
            end)
        end

        tp.OnClick = function()
            local x, y, z = table.unpack(US.Split(pi.Text, ","))
            x = x:match("[-]?%d+")
            y = y:match("[-]?%d+")
            z = z:match("[-]?%d+")
            Net.RCE("Osi.TeleportToPosition(RCE:Character(), %d, %d, %d)", x, y, z).After(function(ok, err)
                if not ok then
                    Event.Trigger("Error", err)
                end
            end)
        end
    end

    do
        local uwp = root:AddButton(__("Unlock Waypoints"))
        uwp.OnClick = function()
            Net.RCE("Osi.PROC_Debug_UnlockAllWP()")
        end
        local wp = root:AddCollapsingHeader(__("Waypoints"))
        wp.SameLine = true
        Components.Layout(wp, 1, 1, function(layout)
            layout.Table.ScrollY = true
            local wp = layout.Cells[1][1]

            local acts = UT.Keys(C.Waypoints)
            table.sort(acts)
            for _, act in ipairs(acts) do
                wp:AddSeparatorText(act .. " - " .. C.Regions[act])
                for short, waypoint in pairs(C.Waypoints[act]) do
                    local label = waypoint:gsub(US.Escape(U.UUID.Extract(waypoint)), short)
                    local b = wp:AddButton(label)
                    b.OnClick = function()
                        Net.RCE("TeleportToWaypoint(RCE:Character(), '%s')", waypoint).After(function(ok, err)
                            if not ok then
                                Event.Trigger("Error", err)
                            end
                        end)
                    end
                end
            end
        end)
    end

    return root
end
