local Players = game:GetService("Players")

--When a Player Joins the game and once their "character" spawns and fully loads in...
Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local gold = Instance.new("NumberValue")
	gold.Name = "Gold"
	gold.Value = 300
	gold.Parent = leaderstats
	
	local placedDefenders = Instance.new("IntValue")
	placedDefenders.Name = "PlacedDefenders"
	placedDefenders.Value = 0
	placedDefenders.Parent = player
	
	
	player.CharacterAppearanceLoaded:Connect(function(character)

		--add ALL Player parts to the "Player" Collision Group
		for i, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Player"
				--print("Player: " .. character.Name .. " Object: " .. object.Name .. " Collision Group: " .. object.CollisionGroup)
			end
		end

	end)
end)



