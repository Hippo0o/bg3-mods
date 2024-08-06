-- Net.On("DollVisuals", function(event)
--     Net.Respond(event, Doll.Visuals(event:Character(), false))
-- end)

Net.On("DollChangeAppearance", function(event)
    if Osi.IsPlayer(event:Character()) ~= 1 then
        return
    end

    Osi.StartChangeAppearance(event:Character())

    Defer(1000, function()
        Net.Respond(event, Doll.Visuals(event:Character(), event.Payload ~= true))
    end)
end)

Net.On("DollApplyVisual", function(event)
    if Osi.IsPlayer(event:Character()) ~= 1 then
        return
    end

    Doll.ApplyVisualSlot(event:Character(), event.Payload.Slot, event.Payload.Uuid)
end)
