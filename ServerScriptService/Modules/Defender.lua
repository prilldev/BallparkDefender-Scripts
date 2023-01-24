local PhysicsService = game:GetService(("PhysicsService"))
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local spawnDefenderEvent = events:WaitForChild("SpawnDefender")
local animateDefenderEvent = events:WaitForChild("AnimateDefender")

local remoteFunctions = ReplicatedStorage:WaitForChild("Functions")
local requestDefender = remoteFunctions:WaitForChild("RequestDefender")

local maxDefenderCt = 10
local defender = {}

function NearestTarget(newDefender, range)
	local nearestTarget = nil

	for i, target in ipairs(workspace.Mobs:GetChildren()) do
		local distance = (target.HumanoidRootPart.Position - newDefender.HumanoidRootPart.Position).Magnitude
		--print(target.Name, distance)
		if distance < range then
			--print(target.Name, "is the nearest target found so far...")
			nearestTarget = target
			range = distance
		end
	end	

	return nearestTarget
end

-- Move a Defender
-- NOTE: Moving a Defender is handled by the Spawn event now

function defender.Attack(newDefender, player)
	local config = newDefender.Config
	local target = NearestTarget(newDefender, config.Range.Value)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		
		local targetCFrame = CFrame.lookAt(newDefender.HumanoidRootPart.Position, target.HumanoidRootPart.Position)
		newDefender.HumanoidRootPart.BodyGyro.CFrame = targetCFrame -- Turn towards enemy when Attacking
		
		animateDefenderEvent:FireAllClients(newDefender, "Attack")
		target.Humanoid:TakeDamage(config.Damage.Value)
		
		--Has mob target been killed yet?
		if (target.Humanoid.Health <= 0) then
			player.leaderstats.Gold.Value += target.Humanoid.MaxHealth --Award player the MaxHealth of the mob target just killed
		end
		
		task.wait(config.Cooldown.Value)
		--print("Defender " .. newDefender.Name .. " in Cooldown for " .. config.Cooldown.Value .. "second...")
	else
		--print("No target nearby. Defender " .. newDefender.Name .. " should be idle.")
	end
	
	task.wait(.1)
	if (newDefender and newDefender.Parent) then
		defender.Attack(newDefender, player)
	end
	
end

-- Spawn a new Defender
function defender.Spawn(player, name, cframe, bbPostion, movingDefender)
	
	local defenderAllowed = false
	if movingDefender then
		--print(movingDefender)
		defenderAllowed = true
	else
		defenderAllowed = defender.CheckSpawn(player, name)
	end
	
	
	if defenderAllowed then
		--move into workspace
		local defenderToPlace = nil
		if (not movingDefender) then
			defenderToPlace = ReplicatedStorage.Squad[name]:Clone()
			player.leaderstats.Gold.Value -= defenderToPlace.Config.Price.Value
			player.PlacedDefenders.Value += 1
		else
			defenderToPlace = movingDefender:Clone()
			movingDefender:Destroy()
			local movingDefenderNameParts = (defenderToPlace.Name):split("-")
			defenderToPlace.Name = movingDefenderNameParts[1]
			print("Moving Defender's Name is now: ", defenderToPlace.Name)
		end
		--local newDefender = ReplicatedStorage.Squad[name]:Clone()
		
		--IMPORTANT: Tack Spawned Baseball Position onto name (ex: "Seb-CF" when Defender "Seb" is placed in Center Field). 
		--Will be checked when trying to place others (only one player/position!)
		defenderToPlace.Name = defenderToPlace.Name .. "-" .. bbPostion
		defenderToPlace.HumanoidRootPart.CFrame = cframe
		defenderToPlace.Parent = workspace.Squad
		defenderToPlace.HumanoidRootPart:SetNetworkOwner(nil) --nil = Server
		
		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bodyGyro.D = 0
		bodyGyro.CFrame = defenderToPlace.HumanoidRootPart.CFrame
		bodyGyro.Parent = defenderToPlace.HumanoidRootPart
		
		--add ALL Defender parts to the "Defender" Collision Group
		for i, object in ipairs(defenderToPlace:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Defender"
			end
		end	
		
		coroutine.wrap(defender.Attack)(defenderToPlace, player)

	else
		warn("Defender does not exist or unable to Move:", name)
	end
end

spawnDefenderEvent.OnServerEvent:Connect(defender.Spawn)

function defender.CheckSpawn(player, name)
	local defenderExists = ReplicatedStorage.Squad:FindFirstChild(name)
	local resultMessage = ""
	
	if defenderExists then
		if defenderExists.Config.Price.Value <= player.leaderstats.Gold.Value then
			if (player.PlacedDefenders.Value < maxDefenderCt) then
				resultMessage = "Success|Defender " .. name .. " selected for placement."
			else
				resultMessage = "Failure|Defender limit reached!"
			end
		else
			resultMessage = "Failure|Player cannot afford the Defender " .. name .. "."
		end
	else
		resultMessage = "Failure|Defender " .. name .. " does not exist."
	end
	
	return resultMessage
end

requestDefender.OnServerInvoke = defender.CheckSpawn --wire up the above Function

return defender
