--Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--Remote Events
local events = ReplicatedStorage:WaitForChild("Events")
local animateDefenderEvent = events:WaitForChild("AnimateDefender")
local equipDefenderEvent = events:WaitForChild("EquipDefender")

--Remote Functions
local remoteFunctions = ReplicatedStorage:WaitForChild("Functions")
local requestDefender = remoteFunctions:WaitForChild("RequestDefender")
local spawnDefender = remoteFunctions:WaitForChild("SpawnDefender")

--Control variables
local maxDefenderCt = 10
local defender = {}


-- ****************************** --

-- Find Nearest Mob humanoid target
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

function defender.Optimize(defenderModel: Model)
	local humanoid = defenderModel:FindFirstChild("Humanoid")
	
	if defenderModel:FindFirstChild("HumanoidRootPart") then
		defenderModel.HumanoidRootPart:SetNetworkOwner(nil)
	elseif defenderModel.PrimaryPart ~= nil then
		defenderModel.PrimaryPart:SetNetworkOwner(nil)
	end
	
	--Optimize by Disabling all the "States" Defender's dont' need/use
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	
end

-- Set Collision Group of all Parts of a Model
function defender.SetCollisionGroup(model: Model, cgroupName: string)
	
	for i, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") or object:IsA("MeshPart")  then
			object.CollisionGroup = cgroupName
		end
	end	
	
end

-- Turn Defender towards Target with TweenService (replaces BodyGyro stuff)
function defender.FaceTarget(newDefender, target, duration)
	
	local targetVector = Vector3.new(target.PrimaryPart.Position.X, newDefender.PrimaryPart.Position.Y, target.PrimaryPart.Position.Z)
	local targetCFrame = CFrame.new(newDefender.PrimaryPart.Position, targetVector)
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
	local faceTargetTween = TweenService:Create(newDefender.PrimaryPart, tweenInfo, {CFrame = targetCFrame})
	faceTargetTween:Play()
	
end

-- Defender Attack on Mobs
function defender.Attack(newDefender, player)
	local config = newDefender.Config
	
	local target = NearestTarget(newDefender, config.Range.Value)
	
	-- If Target has been acquired and they aren't Dead yet (Health > 0)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		
		---- Look at/Turn toward the Target
		defender.FaceTarget(newDefender, target, 0.05)
		
		-- ATTACK!!  
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
	
	-- Wait .1 then immediately look to Attack again (will remain Idle if no Target acquired)
	task.wait(.1)
	if (newDefender and newDefender.Parent) then
		defender.Attack(newDefender, player)
	end
	
end

-- Spawn a New/Upgraded Defender (or Move an existing one)
function defender.Spawn(player, name, cframe, bbPostion, existingDefenderName: string, isMoving)
	
	local existingDefender = nil
	local defenderAllowed = false
	
	if existingDefenderName then
		print("Existing Defender being Moved in Workspace: ", existingDefenderName)
		existingDefender = workspace.Squad:FindFirstChild(existingDefenderName)
		defenderAllowed = true
	else
		defenderAllowed = defender.CheckSpawn(player, name)
	end
	
	if defenderAllowed then
		local defenderToPlace = nil
		local defenderNameToPlace = nil
		
		--print("defender.Spawn() -- Existing Defender Name: ", existingDefender.Name)
		if (not existingDefender) then
			defenderToPlace = ReplicatedStorage.Squad[name]:Clone()
			defenderNameToPlace = defenderToPlace.Name
			player.leaderstats.Gold.Value -= defenderToPlace.Config.Price.Value
			player.PlacedDefenders.Value += 1
			print("Placing New Defender " .. defenderToPlace.Name .. " in Position " .. bbPostion)
		else
			defenderToPlace = existingDefender
			local existingDefenderNameParts = existingDefender.Name:split("-")
			defenderNameToPlace = existingDefenderNameParts[1] 
			print("Moving Defender: ", existingDefender.Name .. " to " .. defenderNameToPlace .. "-" .. bbPostion)
		end
		
		--IMPORTANT: Tack Spawned Baseball Position onto name (ex: "Seb-CF" when Defender "Seb" is placed in Center Field). 
		--Will be checked when trying to place others (only one player/position!)
		defenderToPlace.Name = defenderNameToPlace .. "-" .. bbPostion
		defenderToPlace.PrimaryPart.CFrame = cframe
		defenderToPlace.Parent = workspace.Squad --move into workspace
		print("Name of Defender placed/moved in workspace: ", defenderToPlace.Name)
		
		--add ALL Defender parts to the "Defender" Collision Group
		defender.SetCollisionGroup(defenderToPlace, "Defender")
		
		--Optimize the New Defender
		defender.Optimize(defenderToPlace)
		
		-- Once Spawned/Moved: Immediately look to Attack
		coroutine.wrap(defender.Attack)(defenderToPlace, player)
		
 		return defenderToPlace
		
	else
		warn("Defender does not exist or unable to Move:", name)
		return false
	end
end
spawnDefender.OnServerInvoke = defender.Spawn


-- New Defender validation (before Spawn)
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
--Connect above function to Server Remote Function
requestDefender.OnServerInvoke = defender.CheckSpawn --wire up the above Function


-- Equip Defender with a new/upgraded Weapon
function defender.EquipWeapon(player, currentDefender, weapon)
	--[[ 
	*** IMPORTANT: For a Weapon to "Weld" properly to the Character in the proper position when "Humanoid:EquipTool" is called, 
	*** The "weapon/tool" variable should:
	*** 1) Be an object of type "Tool"
	*** 2) Have a Part named "Handle" that is a direct Child to the Tool (add one near the grip and make invisible if there isn't one)
	*** 3) Have a Weld created between the "Handle" part and the Tool's grip area
    	***    (use "RigEdit Lite" plug-in or with "Weld" script)
	*** 4) And the "Handle" part should be in the same orientation as the Tool/Weapon 
	***    (use "Tool Grip Editor" plugin, done manually in Workspace, or repositioned in the "Weld" script)
	--]]
	
	if currentDefender then
		print("Attempting to Equip " .. currentDefender.Name .. " with " .. weapon.Config.WeaponName.Value)
		--Determine Defender data, etc.
		local defenderData = string.split(currentDefender.Name, "-")
		local defenderName = defenderData[1]
		local defBBPos = defenderData[2]
		local cframe = currentDefender.PrimaryPart.CFrame
		
		--Get a new Clone of the Defender and Weapon to be Equipped
		--local equippedDefender = ReplicatedStorage.Squad:WaitForChild(defenderName):Clone()
		local newWeapon = weapon:Clone()
		
		--Set the Defender's New Weapon, add new Damange/Range, and Parent weapon to the Defender
		currentDefender.Config.Weapon.Value = newWeapon
		currentDefender.Config.Damage.Value = currentDefender.Config.Damage.Value + newWeapon.Config.DamageAdded.Value
		currentDefender.Config.Range.Value = currentDefender.Config.Range.Value + newWeapon.Config.RangeAdded.Value
		newWeapon.Parent = currentDefender

		--Actually Equip the Defender with the New Weapon
		currentDefender.Humanoid:EquipTool(newWeapon)
		print("Defender " .. currentDefender.Name	 .. " equipped with Weapon " .. newWeapon.Config.WeaponName.Value)
		
	else
		warn("No Defender to equip/upgrade!")
	end
	
end
--Connect above method to Server Remote Event
equipDefenderEvent.OnServerEvent:Connect(defender.EquipWeapon)


return defender
