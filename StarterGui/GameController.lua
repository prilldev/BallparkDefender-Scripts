local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGold = localPlayer.leaderstats:WaitForChild("Gold")

--NOTE: The "Squad" folder is where the game's Defender characters are located
local squadFolder = ReplicatedStorage:WaitForChild("Squad")

local events = ReplicatedStorage:WaitForChild("Events")
local spawnDefenderEvent = events:WaitForChild("SpawnDefender")
local equipDefenderEvent = events:WaitForChild("EquipDefender")

local remoteFunctions = ReplicatedStorage:WaitForChild("Functions")
local requestDefender = remoteFunctions:WaitForChild("RequestDefender")

local modules = ReplicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))

local camera = workspace.CurrentCamera
local gui = script.Parent.GameGui
local map = workspace.Maps:WaitForChild("GrassLand")
local ballpark = map:WaitForChild("Ballpark")
local guiData = workspace:WaitForChild("GUIData")

local hoveredInstance = nil
local selectedDefender = nil

local spawnDefender = nil
local canPlace = false
local rotation = 0
local bballPostion = nil
local placedDefenderCt = 0
local maxDefenderCt = 10
local defenderIsMoving = false

local lastTouch = tick()


local function SetupGui()
	health.Setup(ballpark, gui.Info.Health)

	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)

	guiData.Message.Changed:Connect(function(change)
		gui.Info.Message.Text = change
	end)

	guiData.Inning.Changed:Connect(function(change)
		gui.Info.Stats.Inning.Text = "Inning: " .. change
	end)

	playerGold.Changed:Connect(function(change)
		gui.Info.Stats.Gold.Text = "$" .. playerGold.Value
	end)
	gui.Info.Stats.Gold.Text = "$" .. playerGold.Value
end
SetupGui()

local function MouseRaycast(blacklistTable)
	local mousePosition = UserInputService:GetMouseLocation()	
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local rcParams = RaycastParams.new()
	rcParams.FilterType = Enum.RaycastFilterType.Blacklist
	rcParams.FilterDescendantsInstances = blacklistTable

	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, rcParams)

	return raycastResult
end

local function RemovePlaceholderDefender()
	if spawnDefender then
		--print("Destroying... ", spawnDefender.Name)
		spawnDefender:Destroy()
		spawnDefender = nil
		rotation = 0
		defenderIsMoving = false
	end
end

local function AddPlaceholderDefender(name)

	if (defenderIsMoving and selectedDefender) then
		
		--Existing Defender is being Moved!
		spawnDefender = selectedDefender
		selectedDefender = nil
		--selectedDefender:Destroy()
		for i, object in ipairs(spawnDefender:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Defender"
				object.Material = Enum.Material.ForceField
			end
		end

	else

		-- Totally NEW Defender being Placed
		local newDefender = squadFolder:FindFirstChild(name)
		if newDefender then
			RemovePlaceholderDefender()
			spawnDefender = newDefender:Clone()
			spawnDefender.Parent = workspace
			selectedDefender = nil

			for i, object in ipairs(spawnDefender:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Defender"
					object.Material = Enum.Material.ForceField
				end
			end
		else
			warn(name .. " not found as a defender.")
		end
	end


end

local function ColorPlaceholderDefender(color)
	for i, object in ipairs(spawnDefender:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Color = color
		end
	end
end

gui.LeftMenu.ShowSquad.Text = "Squad: " .. placedDefenderCt .. "/" .. maxDefenderCt
for i, defender in pairs(squadFolder:GetChildren()) do
	if defender:IsA("Model") then
		local button = gui.DefendersList.TemplateButton:Clone()
		local config = defender:WaitForChild("Config")
		button.Name = defender.Name
		button.Image = config.Icon.Texture
		button.Visible = true
		button.Price.Text = defender.Name .. " (" .. config.Price.Value .. ")"
		button.LayoutOrder = config.Price.Value
		button.Parent = gui.DefendersList

		button.Activated:Connect(function()
			spawnDefender = nil
			local defenderAllowed = {}
			defenderAllowed = string.split(requestDefender:InvokeServer(defender.Name), "|")
			print(defenderAllowed)

			if defenderAllowed[1] == "Success" then
				AddPlaceholderDefender(defender.Name)
				gui.Info.Message.TextColor3 = Color3.new(0, 1, 0)
			else
				gui.Info.Message.TextColor3 = Color3.new(1, 0, 0)
			end
			gui.Info.Message.Text = defenderAllowed[2]
			gui.DefendersList.Visible = false
		end)
		--print("Squad Member added: ", defender.Name)

	end

end


gui.LeftMenu.ShowSquad.Activated:Connect(function()
	gui.DefendersList.Visible = not gui.DefendersList.Visible
	RemovePlaceholderDefender() --remove any Defender placeholders that may not have been placed before accessing the menu again
end)

local function SpawnDefender()
	if canPlace then
		local defenderToMove = nil
		if defenderIsMoving then
			defenderToMove = spawnDefender
		end
		spawnDefenderEvent:FireServer(spawnDefender.Name, spawnDefender.PrimaryPart.CFrame, bballPostion, defenderToMove)
		if defenderToMove then
			placedDefenderCt += 0 --just moving defender > DON'T increment counter
			gui.Info.Message.Text = "Defender " .. spawnDefender.Name .. " moved to " .. bballPostion .. "."
		else
			placedDefenderCt += 1 --new defender > increment counter
			gui.Info.Message.Text = "Defender " .. spawnDefender.Name .. " placed in " .. bballPostion .. "."
		end
		gui.LeftMenu.ShowSquad.Text = "Squad: " .. placedDefenderCt .. "/" .. maxDefenderCt

		RemovePlaceholderDefender()
	end
end

local function toggleDefenderInfo()

	if selectedDefender then
		gui.SelectedDefender.Visible = true
		local config = selectedDefender.Config
		gui.SelectedDefender.Stats.Damage.Value.Text = config.Damage.Value
		gui.SelectedDefender.Stats.Range.Value.Text = config.Range.Value
		gui.SelectedDefender.Stats.Rest.Value.Text = config.Cooldown.Value
		gui.SelectedDefender.Title.DefenderName.Text = selectedDefender.Name
		gui.SelectedDefender.Title.DefenderIcon.Image = config.Icon.Texture

	else
		gui.SelectedDefender.Visible = false

	end
end

gui.SelectedDefender.Action.UpgradeButton.Activated:Connect(function()
	local msg
	if selectedDefender then
		gui.SelectedDefender.Visible = false --hide gui on click

		--look for contents in the Selected Defender's Config.Weapons folder
		local defenderWeapon = selectedDefender.Config.Weapon.Value
		local weaponGroup = selectedDefender.Config.WeaponGroup.Value

		local selDefName = string.split(selectedDefender.Name, "-")[1]
		local selDefenderSource = ReplicatedStorage.Squad:FindFirstChild(selDefName)
		local weaponGroupFolder = ReplicatedStorage.Weapons:FindFirstChild("Group" .. weaponGroup)

		local nextEquipOrder
		if defenderWeapon then
			print("Current Weapon: " .. defenderWeapon.Name)
			local defenderWeaponSource = weaponGroupFolder:FindFirstChild(defenderWeapon.Name)
			nextEquipOrder = defenderWeaponSource.EquipOrder.Value + 1
		else
			print("Defender has no weapon. Equip with first weapon in Group " .. weaponGroup)
			nextEquipOrder = 1
		end
		local newWeaponFound = false

		for i, weapon in pairs(weaponGroupFolder:GetChildren()) do

			-- Look for a Weapon/Weapon Upgrade within the WeaponGroup with
			-- a weapon.EquipOrder that matches the Defender's First/Next EquipOrder
			if weapon.EquipOrder.Value == nextEquipOrder then
				equipDefenderEvent:FireServer(selectedDefender, weapon)
				newWeaponFound = true
				msg = "New Weapon for Defender " .. selectedDefender.Name .. ": " .. weapon.Name .. "."
				break --exit loop
			end

		end	

		if newWeaponFound == false and defenderWeapon then
			msg = "No weapon upgrade for Defender " .. selectedDefender.Name .. " / Weapon: " .. defenderWeapon.Name .. "."
		end
		
		if string.len(msg) > 0 then
			--print(msg)
			gui.Info.Message.Text = msg
		end


	end

end)


gui.SelectedDefender.Action.MoveButton.Activated:Connect(function()
	if selectedDefender then
		gui.SelectedDefender.Visible = false --hide gui on click
		defenderIsMoving = true
		AddPlaceholderDefender(selectedDefender.Name)	
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if spawnDefender then

		--Left Mouse Click to Spawn the Defender Placeholder
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SpawnDefender()

			--Mobile support > double tap to place Defender
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local timeBetweenTouches = tick() - lastTouch
			print(timeBetweenTouches)
			if timeBetweenTouches <= 0.25 then
				-- double tap (mobile)
				SpawnDefender()
			end
			lastTouch = tick() --re-intialize timer

			--Right Mouse Click to Rotate the Defender Placeholder	
		elseif input.KeyCode == Enum.KeyCode.R or input.UserInputType == Enum.UserInputType.MouseButton2 then
			rotation += 90
		end

	elseif hoveredInstance and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then

		local model = hoveredInstance:FindFirstAncestorOfClass("Model")
		if model and model.Parent == workspace.Squad then -- Is the selected Instance a Model AND one of our Squad Defenders?
			selectedDefender = model
		else
			selectedDefender = nil
			defenderIsMoving = false
		end
		print(selectedDefender)
		toggleDefenderInfo()

	end

end)

RunService.RenderStepped:Connect(function()
	local result = MouseRaycast({spawnDefender})
	if result and result.Instance then
		if spawnDefender then
			hoveredInstance = nil
			--print("Parent Name: " .. result.Instance.Parent.Name) 

			--If the mouse is currently over a Defensive Position "part"
			if result.Instance.Parent.Name == "DefPositions" then
				bballPostion = result.Instance.Name
				print("Position: " .. bballPostion)
				local posHasDefender = false -- Only one Defender allowed per defensive position on the field
				local defenderAlreadyPlaced = false -- Specific Defender can only be placed once
				local invalidDefPosition = false -- Special Defenders (ie "Coach" can only go to a specific position on the field)

				local placedDefenders = workspace.Squad:GetChildren()
				--EX: "Seb-CF" means player "Seb" was placed in Center Field already (see 'Defender' module script)
				--Loop through currently placed Defenders ...
				for i, placedDefender in pairs(placedDefenders) do
					local defPosData = (placedDefender.Name):split("-")
					print("Position Data = ", defPosData)
					if (defPosData[1] == spawnDefender.Name) then
						defenderAlreadyPlaced = true -- Defender already placed on the field
						break
					end
					if (defPosData[2] == bballPostion and spawnDefender.Name:split("-")[1] ~= defPosData[1]) then 
						posHasDefender = true --Another Defender already in the Position!
						break
					end

				end

				--Handle special defenders (current just "Coach" > can only go to the "MGR" DefPosition)
				if (spawnDefender.Name == "Coach" and bballPostion ~= "MGR") then
					invalidDefPosition = true
				end

				if posHasDefender or defenderAlreadyPlaced or invalidDefPosition then --Can't place Defender if another Defender is already there
					-- INVALID Placement (turn red)
					canPlace = false 
					ColorPlaceholderDefender(Color3.new(1, 0, 0))

					-- Tell User why they cant Place...
					local cantPlaceMessage = ""
					if posHasDefender then
						cantPlaceMessage = bballPostion .. " position already filled!"
					elseif defenderAlreadyPlaced then
						cantPlaceMessage = "Defender " .. spawnDefender.Name .. " already on the field!"
					elseif invalidDefPosition then
						cantPlaceMessage = "Position " .. bballPostion .. " invalid for Defender " .. spawnDefender.Name .. "."
					end
					print(cantPlaceMessage)
					gui.Info.Message.Text = cantPlaceMessage
					gui.Info.Message.TextColor3 = Color3.new(1, 0, 0)
				else
					-- Placement is valid! (turn green)
					canPlace = true
					ColorPlaceholderDefender(Color3.new(0, 1, 0))
					gui.Info.Message.Text = ""
					gui.Info.Message.TextColor3 = Color3.new(0, 1, 0)
				end

			else
				canPlace = false
				ColorPlaceholderDefender(Color3.new(1, 0, 0))
			end

			if spawnDefender:GetChildren("Humanoid") then
				local x = result.Position.X
				local y = result.Position.Y + spawnDefender.Humanoid.HipHeight + (spawnDefender.PrimaryPart.Size.Y / 2)
				local z = result.Position.Z	

				local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)
				spawnDefender:SetPrimaryPartCFrame(cframe)	
			end

		else
			hoveredInstance = result.Instance

		end		
	else
		hoveredInstance = nil
	end


end)