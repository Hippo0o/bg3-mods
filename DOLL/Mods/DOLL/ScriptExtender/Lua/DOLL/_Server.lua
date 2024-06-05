Require("DOLL/Shared")

Require("DOLL/Server/Transmog")
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

function Dump()
    L.Dump(UT.Clean(_C().ServerIsCurrentOwner, 1))
end

function Debug()
    Require("Hlib/OsirisEventDebug").Attach()
end
