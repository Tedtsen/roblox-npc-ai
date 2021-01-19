local head = script.Parent:WaitForChild("Head")
local human = script.Parent:WaitForChild("Humanoid")
--Sound variables
local runningSound = head:WaitForChild("Running")
local jumpingSound = head:WaitForChild("Jumping")
local diedSound = head:WaitForChild("Died")

human.Running:Connect(function(speed)
	if speed>0 then
		runningSound:Play()
	else
		runningSound:Stop()
	end
end)

human.Jumping:Connect(function()
	jumpingSound:Play()
end)

human.Died:Connect(function()
	diedSound:Play()
end)
