-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local events = ReplicatedStorage:WaitForChild("Events")
local animateDefenderEvent = events:WaitForChild("AnimateDefender")

local function fireProjectile(defenderWeapon, target)
	local projectile = Instance.new("Part")
	--local distance = (defenderWeapon.Handle.Position - target.HumanoidRootPart.Position).Magnitude
	--projectile.Size = Vector3.new(0.1, 0.1, distance)
	--local offset = CFrame.new(0, 0, -distance/2)
	----NOTE: Currently shooting from the Weapon's "Handle" .. TODO: Add a "BarrelPos" to all Weapons to use here >>
	--projectile.CFrame = CFrame.new(defenderWeapon.Handle.Position, target.HumanoidRootPart.Position) * offset
	projectile.Size = Vector3.new(1, 1, 1)
	projectile.CFrame = defenderWeapon.Handle.CFrame
	
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.Transparency = 0.5
	projectile.Parent = workspace.Camera
	
	local fireEffect = Instance.new("Fire")
	fireEffect.Size = 2
	fireEffect.Heat = 0.4
	fireEffect.Color = defenderWeapon.Config.TrailColor.Value
	fireEffect.Parent = projectile
	
	local projectileTween = TweenService:Create(projectile, TweenInfo.new(.5), {Position = target.HumanoidRootPart.Position})
	projectileTween:Play()
	Debris:AddItem(projectile, 0.5)
	
end

local function setAnimation(object, animName)
	local humanoid = object:WaitForChild("Humanoid")
	local animationsFolder = object:WaitForChild("Animations")
	
	if humanoid and animationsFolder then
		local animObject = animationsFolder:WaitForChild(animName)
		if animObject then
			local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
			
			--if the animation track is already loaded/playing for the current humanoid object, re-use it
			for i, foundTrack in pairs(animator:GetPlayingAnimationTracks()) do
				if foundTrack.Name == animName then
					--print("Animation Track [" .. foundTrack.Name .. "] found for object [" .. animationsFolder.Parent.Name .. "]. Re-using...")
					return foundTrack
				end
			end
			--otherwise, load the track new
			local newTrack = animator:LoadAnimation(animObject)
			return newTrack


		end
	end
	
end

local function playAnimation(object, animName)
	local animTrack = setAnimation(object, animName)
	if animTrack then
		animTrack:Play()
		--print("Should be playing animation track: ", animTrack.Name)
	else
		warn("Unable to load animation '" .. animName .."' or it does not exist.")
		return
	end
end



workspace.Mobs.ChildAdded:Connect(function(object)
	playAnimation(object, "Walk")
end)

workspace.Squad.ChildAdded:Connect(function(object)
	playAnimation(object, "Idle")
end)

animateDefenderEvent.OnClientEvent:Connect(function(defender, animName, target)
	playAnimation(defender, animName)
	if target then
		local defenderWeapon = defender.Config.Weapon.Value
		if defenderWeapon then
			if defenderWeapon.Config:FindFirstChild("TrailColor") then
				fireProjectile(defenderWeapon, target)		
			end
			if defenderWeapon:FindFirstChild("Attack") then
				defenderWeapon.Attack:Play()
			end			
		end
	end
end)
