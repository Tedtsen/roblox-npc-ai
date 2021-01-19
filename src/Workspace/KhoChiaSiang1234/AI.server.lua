local myHuman = script.Parent:WaitForChild("Humanoid")
local myRoot = script.Parent:WaitForChild("HumanoidRootPart")
local myHead = script.Parent:WaitForChild("Head")
local myFace = myHead:WaitForChild("face")

local oldHealth = myHuman.Health
local isFleeing = false
local fleeLength = 5 -- How many second it will try to flee
local fleeCountdown = fleeLength
local pathCount = 0 
local isDead = false

local clone = script.Parent:Clone()

-- This part is to solve the slowing down of myHuman.MoveToFinished:Wait() after extensive usage
-- The slowdown is caused by the frequent ownership switching of NPC from the client/server
function setNetworkOwner(character)
	for _, desc in pairs(character:GetDescendants())do
		if desc:IsA("BasePart")then
			desc:SetNetworkOwner(nil)
		end
	end
end
setNetworkOwner(script.Parent)

function getUnstuck()
	print("Unstucking...")
	myHuman:Move(Vector3.new(math.random(-1,1),0,math.random(-1,1)))
	myHuman.Jump = true
	wait(0.5)
end

function pathToLocation(location)
	local path = game:GetService("PathfindingService"):CreatePath()
	path:ComputeAsync(myRoot.Position, location)
	local waypoints = path:GetWaypoints()
	pathCount = pathCount + 1
	
	if path.Status == Enum.PathStatus.Success then
		local currentPathCount = pathCount
		for i, waypoint in ipairs(waypoints) do
			if currentPathCount ~= pathCount  then
				return -- Remove old pathfinding threads
			end
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				myHuman.Jump = true
			end
			myHuman:MoveTo(waypoint.Position)
			delay(0.5, function() -- Spawn another thread to check if jump is needed (Roblox waypoint sometimes sucks)
				if myHuman.WalkToPoint.Y > myRoot.Position.Y then
					myHuman.Jump = true
				end
			end)
			local moveSuccess = myHuman.MoveToFinished:Wait()
			if not moveSuccess then
				break
			end
			if isFleeing == true then
				if i == #waypoints then
					wander()
				end
			end
		end
	else
		getUnstuck()
	end
end

function wander()
	local randX = math.random(-50, 50)
	local randZ = math.random(-50, 50)
	local goal = myRoot.Position + Vector3.new(randX, 0, randZ)
	pathToLocation(goal)
end

function findThreat()
	local dist = 100
	local threat = nil
	for i,v in ipairs(workspace:GetChildren()) do
		if v == "Friendly NPCs" or v == "Hostile NPCs" then
			for j, k in  ipairs(v:GetChildren()) do
				local human = k:FindFirstChild("Humanoid") or k:FindFirstChild("Zombie")
				local torso = k:FindFirstChild("HumanoidRootPart") or k:FindFirstChild("Torso") 
				if human and torso and k ~= script.Parent then
					if (myRoot.Position - torso.Position).Magnitude < dist then
						threat = torso
						dist = (myRoot.Position - torso.Position).Magnitude
					end
				end
			end
		else
			local human = v:FindFirstChild("Humanoid") or v:FindFirstChild("Zombie")
			local torso = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
			if human and torso and v ~= script.Parent then
				if (myRoot.Position - torso.Position).Magnitude < dist then
					threat = torso
					dist = (myRoot.Position - torso.Position).Magnitude
				end
			end
		end
	end
	return threat
end

function flee()
	local threat = findThreat()
	if threat then
		local cframe = threat.CFrame * CFrame.new(Vector3.new(0,0,-100))
		spawn(function() pathToLocation(cframe.Position) end)	
	else
		spawn(wander)
	end
	
	fleeCountdown = fleeLength
	if isFleeing == false then
		isFleeing = true
		myFace.Texture = "http://www.roblox.com/asset/?id=258192246" -- Scared face
		myHuman.WalkSpeed = 25
		repeat 
			wait(1)
			fleeCountdown = fleeCountdown - 1
		until fleeCountdown <= 0 or myHuman.Health <= 0
		if isDead == false then
			myFace.Texture = "rbxasset://textures/face.png"
			myHuman.WalkSpeed = 16
		end
		isFleeing = false
	end 
end

myHuman.Died:Connect(function()
	myFace.Texture = "http://www.roblox.com/asset/?id=15426038"
	isDead = true
	wait(5)
	clone.Parent = workspace
	game:GetService("Debris"):AddItem(script.Parent,0.1)
end)

myHuman.HealthChanged:Connect(function(health)
	if isDead == false then
		if health < oldHealth then
			flee()
		end
		oldHealth = health
	end
end)

while wait() do
	if myHuman.Health > 0 then
		if isFleeing == false then
			wander()
			wait(math.random(5,15))
		end
	else
		break
	end
end
