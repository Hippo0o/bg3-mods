Require("DOLL/Shared")

Require("DOLL/Server/Armor")
Require("DOLL/Server/Visual")
Require("DOLL/Server/Doll")

Require("DOLL/Server/Net")

function VisualTest()
    for _, slot in pairs(C.VisualSlots) do
        for _, type in pairs(C.VisualTypes) do
            if slot == C.VisualSlots["Private Parts"] then
                L.Dump(type, slot, Visual.GetSlot(slot, type))
            end
        end
    end
end

function DollTest()
    L.Dump(Doll.Visuals(GetHostCharacter(), true))
end

function Debug()
    Require("Hlib/OsirisEventDebug").Attach()
end
