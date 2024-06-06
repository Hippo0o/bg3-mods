Require("DOLL/Shared")

Require("DOLL/Server/Transmog")
Require("DOLL/Server/Visual")
Require("DOLL/Server/Doll")

Require("DOLL/Server/Net")

function VisualTest()
    local e = Ext.Entity.Get(GetHostCharacter())
    local presets = Doll.CreationPresets(e)
    local doll = Doll.Build(GetHostCharacter())
    L.Dump(presets[2], doll)
    doll.BodyType = presets[2].BodyType
    doll.BodyShape = presets[2].BodyShape

    e.GameObjectVisual.RootTemplateId = presets[2].RootTemplate
    e:Replicate("GameObjectVisual")

    Net.Send("DollVisuals", Doll.Visuals(doll, false))
end

function Dump()
    L.Dump(UT.Clean(_C().ServerIsCurrentOwner, 1))
end

function Debug()
    Require("Hlib/OsirisEventDebug").Attach()
end
