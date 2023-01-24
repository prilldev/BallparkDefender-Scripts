local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local animateDefenderEvent = events:WaitForChild("AnimateDefender")

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

animateDefenderEvent.OnClientEvent:Connect(function(defender, animName)
	playAnimation(defender, animName)
end)
