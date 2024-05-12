Creation = {}

---@param tab ExtuiTabBar
function Creation.Main(tab)
    local root = tab:AddTabItem(__("Creation"))

    local posLabel = root:AddText("")
    root:AddButton(__("Pos")).OnClick = function()
        local pos = Ext.Entity.GetAllEntitiesWithComponent("PartyMember")[1].Transform.Transform.Translate

        local x, y, z = table.unpack(pos)
        posLabel.Label = string.format("Pos: %s, %s, %s", x, y, z)
    end

    root:AddButton(__("Kill spawned")).OnClick = function()
        Net.Send("KillSpawned")
    end
end
