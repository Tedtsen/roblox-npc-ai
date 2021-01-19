--Main body parts
local myRoot = script.Parent:WaitForChild("HumanoidRootPart")
local myHuman = script.Parent:WaitForChild("Humanoid")
local rightHand = script.Parent:WaitForChild("RightHand")
local upperTorso = script.Parent:WaitForChild("UpperTorso")

--Weapon
local sword = script.Parent:WaitForChild("Sword")
local swordWeld = sword:WaitForChild("SwordWeld")

--Sounds
local lungeSound = sword:WaitForChild("Lunge")
local slashSound = sword:WaitForChild("Slash")
local unsheathSound = sword:WaitForChild("Unsheath")

--AI Booleans
local attackCool = true
local swordHolstered = false
local chasing = false
local pathFailCount = 0 

--Animation
local leftSlash = script.Parent:WaitForChild("LeftSlash")
local leftSlashAnimation = myHuman:LoadAnimation(leftSlash)
leftSlashAnimation.Priority = Enum.AnimationPriority.Action

local rightSlash = script.Parent:WaitForChild("RightSlash")
local rightSlashAnimation = myHuman:LoadAnimation(rightSlash)
rightSlashAnimation.Priority = Enum.AnimationPriority.Action

--Respawn
local clone = script.Parent:Clone()

function getUnstuck()
	myHuman:Move(Vector3.new(math.random(-1,1),0,math.random(-1,1)))
	wait(0.3)
end

function wander()
	local xRand = math.random(-50,50)
	local zRand = math.random(-50,50)
	local goal = myRoot.Position + Vector3.new(xRand,0,zRand)
	local path = game:GetService("PathfindingService"):CreatePath()
	path:ComputeAsync(myRoot.Position, goal)
	if path.Status == Enum.PathStatus.Success then
		pathFailCount = 0
		myHuman.WalkSpeed = 10
		local waypoints = path:GetWaypoints()
		for i,v in ipairs(waypoints) do
			if v.Action == Enum.PathWaypointAction.Jump then
				myHuman.Jump = true
			end
			myHuman:MoveTo(v.Position)
			if i % 5 == 0 then
				if findTarget() then
					break
				end
			end
			local moveSuccess = myHuman.MoveToFinished:Wait()
			if not moveSuccess then
				break
			end
		end
	else
		pathFailCount = pathFailCount + 1 
		if pathFailCount > 10 then
			pathFailCount = 0
			getUnstuck()
		end
	end
end

function findTarget()
	local dist = 200
	local target = nil 
	for i,v in ipairs(workspace:GetChildren()) do
		local human = v:FindFirstChild("Humanoid")
		local torso = v:FindFirstChild("Torso") or v:FindFirstChild("HumanoidRootPart")
		if human and torso and v.Name ~= script.Parent.Name then
			if (myRoot.Position - torso.Position).Magnitude < dist and human.Health > 0 then
				target = torso
				dist = (myRoot.Position - torso.Position).Magnitude
			end
		end
	end
	return target
end

function checkSight(target)
	local ray = Ray.new(myRoot.Position, (target.Position - myRoot.Position).Unit * 200)
	local hit,position = workspace:FindPartOnRayWithIgnoreList(ray, {script.Parent})
	if hit then
		if hit:IsDescendantOf(target.Parent) then
			return true
		end
	end
	return false
end

function checkHeight(target)
	if math.abs(myRoot.Position.Y - target.Position.Y) < 3 then
		return true
	end
	return false
end

function checkDirect(target)
	if checkSight(target) and checkHeight(target) and (myRoot.Position - target.Position).Magnitude < 30 then
		return true
	end
	return false
end

function attack(target)
	if attackCool == true then
		attackCool = false
		myHuman:MoveTo(target.Position)
		
		local attackAnim = math.random(2)
		if attackAnim == 1 then
			slashSound:Play()
			leftSlashAnimation:Play()
		else
			lungeSound:Play()
			rightSlashAnimation:Play()
		end
		
		local human = target.Parent.Humanoid
		human:TakeDamage(math.random(20,30))
		
		if human.Health < 1 then
			wait(0.3)
		end
		
		spawn(function() wait(1) attackCool = true end)
	end
end

function holsterSword()
	if swordHolstered == false then
		swordHolstered = true
		
		unsheathSound:Play()
		
		swordWeld.Part1 = nil
		sword.CFrame = upperTorso.CFrame * CFrame.new(0,0,0.7) * CFrame.Angles(math.rad(90),math.rad(-45),math.rad(0))
		swordWeld.Part1 = upperTorso
	end
end

function drawSword()
	if swordHolstered == true then
		swordHolstered = false
		
		unsheathSound:Play()
		
		swordWeld.Part1 = nil
		sword.CFrame = rightHand.CFrame * CFrame.new(0,0,-2) * CFrame.Angles(0,math.rad(180),math.rad(90))
		swordWeld.Part1 = rightHand
	end
end

function pathToTarget(target)
	local path = game:GetService("PathfindingService"):CreatePath()
	path:ComputeAsync(myRoot.Position,target.Position)
	if path.Status == Enum.PathStatus.Success then
		pathFailCount = 0
		local waypoints = path:GetWaypoints()
		for i,v in ipairs(waypoints) do
			if v.Action == Enum.PathWaypointAction.Jump then
				myHuman.Jump = true
			end
			spawn(function()
				wait(0.5)
				if myRoot.Position.Y < myHuman.WalkToPoint.Y and chasing == false then
					myHuman.Jump = true
				end
			end)
			myHuman:MoveTo(v.Position)
			local moveSuccess = myHuman.MoveToFinished:Wait()
			if not moveSuccess then 
				break
			end
			if i % 5 == 0 then
				if checkDirect(target) then
					break
				end
				if target ~= findTarget() then
					break 
				end
			end
			if (waypoints[#waypoints].Position - target.Position).Magnitude > 30 then
				break
			end
		end
	else
		pathFailCount = pathFailCount + 1
		if pathFailCount > 10 then
			pathFailCount = 0
			getUnstuck()
		end
	end
end

function chase(target)
	myHuman.WalkSpeed = 20
	chasing = true
	myHuman:MoveTo(target.Position)
end

myHuman.Died:Connect(function()
	sword.CanCollide = true
	wait(15)
	clone.Parent = workspace
	game:GetService("Debris"):AddItem(script.Parent,0.1)
end)

function main()
	chasing = false 
	myHuman.WalkSpeed = 16
	local target = findTarget()
	if target then
		local targetDistance = (myRoot.Position - target.Position).Magnitude
		if targetDistance > 30 then
			holsterSword()
		else
			drawSword()
		end
		if checkDirect(target) then
			if targetDistance > 3 then
				chase(target)
			end
			if targetDistance < 6 then
				attack(target)
			end
		elseif checkSight(target) and math.abs(myRoot.Position.X - target.Position.X) < 1 and 
			math.abs(myRoot.Position.Z - target.Position.Z) < 1 then
				getUnstuck()
		else
			pathToTarget(target)
		end
	else
		holsterSword()
		wander()
	end
end

while wait(0.1) do
	if myHuman.Health < 1 then
		break
	end
	main()
end


























