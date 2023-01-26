-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Referenced Modules
local modules = ReplicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))

-- Control Variables
local mob = {}
local const WAYPOINT_SAFE_AT_HOME = 13 --waypoint #13 is at Home plate (change if Map changes!)

-- Move the Mob humanoids around the pre-defined Path using waypoints on the Map
function mob.Move(mob, map)
	local mobHumanoid = mob:WaitForChild("Humanoid")
	local mobWaypoints = map.MobPath.Waypoints
	
	--loop through all the waypoints 
	for waypoint=1, #mobWaypoints:GetChildren() do
		mobHumanoid:MoveTo(mobWaypoints[waypoint].Position)
		mobHumanoid.MoveToFinished:Wait()
		
		--If Mob Humanoid has made it safely to Home Plate w/o getting killed...
		--Ballpark Takes Damage = Remaining health of the Mob Humanoid
		if waypoint == WAYPOINT_SAFE_AT_HOME then
			map.Ballpark.Humanoid:TakeDamage(mobHumanoid.Health)
		end
	end
	
	--mob humanoid made it to the end (Dugout)... Destroy
	mob:Destroy()
	
end

-- Spawn the Mob member(s)
function mob.Spawn(name, quantity, map)
	
	local mobExists = ServerStorage.Mobs:FindFirstChild(name)
	if mobExists then
		--move into workspace
		for i=1, quantity do
			task.wait(0.5)
			local newMob = mobExists:Clone()
			newMob.HumanoidRootPart.CFrame = map.MobPath.MobStartPoint.CFrame
			newMob.Parent = workspace.Mobs
			newMob.HumanoidRootPart:SetNetworkOwner(nil) --nil = Server
			
			--add ALL Mob parts to the "Mob" Collision Group
			for i, object in ipairs(newMob:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Mob"
					--print("Mob: " .. newMob.Name .." Object: " .. object.Name .. " Collision Group: " .. object.CollisionGroup)
				end
			end
			
			newMob.Humanoid.Died:Connect(function()
				task.wait(0.5)
				newMob:Destroy()
			end)
			
			-- Immediately call mob.Move to start the newly spawned Mob member on it's way
			coroutine.wrap(mob.Move)(newMob, map)
		
		end

	else
		warn("Requested mob does not exist:", name)
	end
end

return mob
