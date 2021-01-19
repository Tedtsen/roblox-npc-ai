function onTouched(hit)
        local human = hit.Parent:findFirstChild("Humanoid")
        if (human ~= nil) then
                human.Health = human.Health - 5 -- Change the amount to change the damage.
        end
end
script.Parent.Touched:connect(onTouched)