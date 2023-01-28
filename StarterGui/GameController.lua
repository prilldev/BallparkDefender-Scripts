-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player
local localPlayer = Players.LocalPlayer
local playerGold = localPlayer.leaderstats:WaitForChild("Gold")

--NOTE: The "Squad" folder is where the game's Defender characters are located
local squadFolder = ReplicatedStorage:WaitForChild("Squad")

-- Remove Events
local events = ReplicatedStorage:WaitForChild("Events")
local equipDefenderEvent = events:WaitForChild("EquipDefender")

-- Remote Functions
local remoteFunctions = ReplicatedStorage:WaitForChild("Functions")
local requestDefenderFunction = remoteFunctions:WaitForChild("RequestDefender")
local spawnDefenderFunction = remoteFunctions:WaitForChild("SpawnDefender")

-- Module references
local rsModules = ReplicatedStorage:WaitForChild("Modules")
-- Module Script references
local health = require(rsModules:WaitForChild("Health"))

-- Visual workspace variables
local camera = workspace.CurrentCamera
local gui = script.Parent.GameGui
local map = workspace.Maps:WaitForChild("GrassLand")
local ballpark = map:WaitForChild("Ballpark")
local guiData = workspace:WaitForChild("GUIData")

-- Misc control variables
local hoveredInstance = nil
local selectedDefender = nil
local selectedDefPosition = nil
local spawnedDefender = nil
local canPlace = false
local rotation = 0
local bballPostion = nil
local placedDefenderCt = 0
local maxDefenderCt = 10
local defenderIsMoving = false
local lastTouch = tick() -- for mobile support


-- ** Initial GUI Setup
local function SetupGui()

	-- attach "Health bar" guis to the Ballpark 
	health.Setup(ballpark, gui.Info.Health)

	-- attach "Health bar" guis to all the Mob "children" as they are added/spawned
	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)

	-- Connect "Changed" event of Info Message bar whenver Message changes
	guiData.Message.Changed:Connect(function(change)
		gui.Info.Message.Text = change
	end)

	-- Connect "Changed" event of Inning (Wave) Message bar each time Inning/Wave is changing
	guiData.Inning.Changed:Connect(function(change)
		gui.Info.Stats.Inning.Text = "Inning: " .. change
	end)

	-- Connect "Changed" even of playerGold to the Info bar's Gold text box
	playerGold.Changed:Connect(function(change)
		gui.Info.Stats.Gold.Text = "$" .. playerGold.Value
	end)
	-- Initialize Gold text box and beginning of the game
	gui.Info.Stats.Gold.Text = "$" .. playerGold.Value

end
SetupGui() -- call above Setup function OnLoad of the Game

-- Set Collision Group of all Parts of a Model
function SetCollisionGroup(model: Model, cgroupName: string, objectTransparency: NumberValue)

	for i, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") or object:IsA("MeshPart")  then
			object.CollisionGroup = cgroupName
			if objectTransparency then
				object.Transparency = objectTransparency
			end
		end
	end	

end

-- ** Remove Placeholder for Defender after they're placed (or if canceled/menu is clicked again)
local function RemovePlaceholderDefender()
	if spawnedDefender then
		--print("Destroying... ", spawnedDefender.Name)
		spawnedDefender:Destroy()
		spawnedDefender = nil
		rotation = 0
		defenderIsMoving = false
	end
end

-- ** Add Placeholder for the Defender/Character being placed as the mouse moves around the screen (before placement)
local function AddPlaceholderDefender(name)

	if (defenderIsMoving and selectedDefender) then

		-- Existing Defender is being Moved!
		spawnedDefender = selectedDefender:Clone()
		spawnedDefender.Parent = workspace

	else

		-- Totally NEW Defender being Placed
		local newDefender = squadFolder:FindFirstChild(name)
		if newDefender then
			RemovePlaceholderDefender()
			spawnedDefender = newDefender:Clone()
			spawnedDefender.Parent = workspace

		else
			warn(name .. " not found as a defender.")
		end
	end

	-- Set CollisionGroup of Defender Model
	if spawnedDefender then
		SetCollisionGroup(spawnedDefender, "Defender", 0.5)
	end

end

-- ** Color Placeholder as it's moving around the screen (Green for valid placement/Red for invalid placement)
local function ColorPlaceholderDefender(color)
	for i, object in ipairs(spawnedDefender:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Color = color
		end
	end
end

local function ToggleDefendersList()
	gui.DefendersList.Visible = not gui.DefendersList.Visible

end

-- ** Spawn the Defender that's currently in the "DefenderPlaceholder" (global 'spawnedDefender' object variable)
local function SpawnDefender()
	if canPlace then
		local placedDefender = nil
		local defenderToMove = nil -- NOTE: A defender Is Updating if they are Moving OR getting Equipped
		print("Defender is moving: ", defenderIsMoving)
		
		
		if defenderIsMoving == true then
			defenderToMove = spawnedDefender
			print("Defender being moved: ", defenderToMove)
			placedDefender = spawnDefenderFunction:InvokeServer(spawnedDefender.Name, spawnedDefender.PrimaryPart.CFrame, bballPostion, defenderToMove.Name, defenderIsMoving)
		else
			print("Defender being added: ", spawnedDefender)
			placedDefender = spawnDefenderFunction:InvokeServer(spawnedDefender.Name, spawnedDefender.PrimaryPart.CFrame, bballPostion)
		end

		if placedDefender then
			if defenderToMove then
				placedDefenderCt += 0 --just moving defender > DON'T increment counter
				gui.Info.Message.Text = "Defender " .. spawnedDefender.Name .. " moved to " .. bballPostion .. "."
			else
				placedDefenderCt += 1 --new defender > increment counter
				gui.Info.Message.Text = "Defender " .. spawnedDefender.Name .. " placed in " .. bballPostion .. "."
			end

			-- Removed the Moved Defender from their Previous Location
			if defenderToMove then
				defenderToMove:Destroy()
				print("Defender Removed: ", defenderToMove.Name)
			end

			gui.LeftMenu.AddDefender.Title.Text = "Defender: " .. placedDefenderCt .. "/" .. maxDefenderCt
			gui.SelectedDefender.Visible = false
			
			--make Def. Position's ForceField Cylinder smaller so Defender is selectable now that they're placed
			local defPositionPlaced = map.DefPositions:FindFirstChild(bballPostion)
			defPositionPlaced.Size = Vector3.new(2, 12, 12) 
			
		else
			warn("Unable to place Defender - 'spawnDefender' remote function return false.")
		end

		RemovePlaceholderDefender()
	end
end


-- ** LeftMenu Frame's "Squad" button Text
gui.LeftMenu.AddDefender.Title.Text = "Defender: " .. placedDefenderCt .. "/" .. maxDefenderCt
-- ** Setup of "AddDefender" Activated Event (Shows/Hides the above "DefendersList" Frame)
gui.LeftMenu.AddDefender.Activated:Connect(function()
	ToggleDefendersList()
	RemovePlaceholderDefender() --remove any Defender placeholders that may not have been placed before accessing the menu again
end)


-- ** Setup/Populate "DefendersList" frame on the Left (invisible by default)
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
			spawnedDefender = nil
			local defenderAllowed = {}
			defenderAllowed = string.split(requestDefenderFunction:InvokeServer(defender.Name), "|")
			print(defenderAllowed)

			if defenderAllowed[1] == "Success" then

				AddPlaceholderDefender(defender.Name)
				gui.Info.Message.TextColor3 = Color3.new(0, 1, 0)
				
				---- If use selected a Defensive Position first, go ahead and Spawn the Defender in that position immediately
				--if (selectedDefPosition and spawnedDefender) then
				--	bballPostion = selectedDefPosition.Name
				--	print("Selected Position for spawn:", selectedDefPosition.Name)
				--	canPlace = true
				--	SpawnDefender()
				--end

			else
				gui.Info.Message.TextColor3 = Color3.new(1, 0, 0)
			end
			gui.Info.Message.Text = defenderAllowed[2]
			gui.DefendersList.Visible = false
		end)
		--print("Squad Member added: ", defender.Name)

	end

end

-- ** Toggle Defender Info when a Placed Defender is selected in the Game (not the DefendersList)
local function ToggleDefenderInfo(defenderToShow: Model)

	if not defenderToShow then
		defenderToShow = selectedDefender
	end
	if defenderToShow then
		gui.SelectedDefender.Visible = true
		local config = defenderToShow.Config
		gui.SelectedDefender.Stats.Damage.Value.Text = config.Damage.Value
		gui.SelectedDefender.Stats.Range.Value.Text = config.Range.Value
		gui.SelectedDefender.Stats.Rest.Value.Text = config.Cooldown.Value
		gui.SelectedDefender.Title.DefenderName.Text = defenderToShow.Name
		gui.SelectedDefender.Title.DefenderIcon.Image = config.Icon.Texture

		local upgradeDefender 
	else
		gui.SelectedDefender.Visible = false

	end
end


-- ** Selected Defender's Equip/Upgrade Weapon button is Activated
gui.SelectedDefender.Action.UpgradeButton.Activated:Connect(function()
	local msg: string = ""
	if selectedDefender then
		--gui.SelectedDefender.Visible = false --hide gui on click
		gui.SelectedDefender.Upgrades.Visible = true

		--look for contents in the Selected Defender's Config.Weapons folder
		local defenderWeapon = selectedDefender.Config.Weapon.Value
		local weaponGroup = selectedDefender.Config.WeaponGroup.Value

		local selDefName = string.split(selectedDefender.Name, "-")[1]
		local selDefenderSource = ReplicatedStorage.Squad:FindFirstChild(selDefName)
		local weaponGroupFolder = ReplicatedStorage.Weapons:FindFirstChild("Group" .. weaponGroup)	
		local newWeaponFound = false
		local currWeaponEquipOrder = nil

		if defenderWeapon then
			local defenderWeaponSource = weaponGroupFolder:FindFirstChild(defenderWeapon.Name)
			print("Current Weapon: " .. defenderWeaponSource.Config.WeaponName.Value)
			currWeaponEquipOrder = defenderWeaponSource.Config.EquipOrder.Value
		else
			print("Defender has no weapon. Equip with first weapon in Group " .. weaponGroup)
			currWeaponEquipOrder = 0
		end

		-- Clear previous Weapon Buttons that may exist before they're reloaded
		for _, item in pairs(gui.SelectedDefender.Upgrades:GetChildren()) do
			if item:IsA('ImageButton') and item.Name ~= "TemplateButton" then
				item:Destroy()
			end
		end

		-- Loop through the available Weapons for the selected Defender's Weapon Group and add them as Buttons
		for _, weapon in pairs(weaponGroupFolder:GetChildren()) do
			local button = gui.SelectedDefender.Upgrades.TemplateButton:Clone()
			local config = weapon:WaitForChild("Config")
			button.Name = "Weapon" .. weapon.Config.EquipOrder.Value
			button.ItemName.Text = weapon.Config.WeaponName.Value
			button.Image = config.Icon.Texture
			button.Visible = true
			button.ItemPrice.Text = config.Cost.Value
			button.LayoutOrder = weapon.Config.EquipOrder.Value
			button.Parent = gui.SelectedDefender.Upgrades

			-- Wire up each Weapon Button's Activated event
			button.Activated:Connect(function()

				if weapon.Config.EquipOrder.Value == currWeaponEquipOrder + 1 then
					equipDefenderEvent:FireServer(selectedDefender, weapon)
					newWeaponFound = true
					gui.SelectedDefender.Upgrades.Visible = false
					msg = "New Weapon for Defender " .. selectedDefender.Name .. ": " .. weapon.Config.WeaponName.Value .. "."
				else
					msg = "Selected Weapon " .. weapon.Config.WeaponName.Value .. " is not the next upgrade for " .. selectedDefender.Name .. ", try again."
				end

				if newWeaponFound == false and defenderWeapon then
					msg = "No weapon upgrade for Defender " .. selectedDefender.Name .. " / Weapon: " .. defenderWeapon.Name .. "."
					gui.SelectedDefender.Upgrades.Visible = false
				end

				if string.len(msg) > 0 then
					print(msg)
					gui.Info.Message.Text = msg
				end

			end)
		end

	end

end)

-- ** Selected Defender's Move button is Activated
gui.SelectedDefender.Action.MoveButton.Activated:Connect(function()
	if selectedDefender then
		gui.SelectedDefender.Visible = false --hide gui on click
		defenderIsMoving = true
		AddPlaceholderDefender(selectedDefender.Name)	
	end
end)


-- ***************************************************************************
-- *******  IMPORTANT Re-Usable "GameControl" functions below ****************

-- ** Mouse Raycast function (determines where mouse is in 3D on the screen... used for moving/placing Characters)
-- ** (called by the RunService:RenderStepped event below)
-- ** blacklistTable: An optional {table} of "blacklisted" items for the Raycast to ignore
local function MouseRaycast(blacklistTable)
	local mousePosition = UserInputService:GetMouseLocation()	
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local rcParams = RaycastParams.new()
	rcParams.FilterType = Enum.RaycastFilterType.Blacklist
	rcParams.FilterDescendantsInstances = blacklistTable

	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, rcParams)

	return raycastResult
end

-- ***** Connect "InputBegan" Event to handle all Mouse/Touch Input *****
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if spawnedDefender then

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
		-- Selecting a Defender?
		if model and model.Parent == workspace.Squad then -- Is the selected Instance a Model AND one of our Squad Defenders?
			selectedDefender = model
			print(selectedDefender)
		else
			selectedDefender = nil
			defenderIsMoving = false
		end
		ToggleDefenderInfo()
		

	end

end)


-- ***** Connect "RenderStepped" Event that runs "every split second" to determine what Mouse/Touch is Hovering over in the 3D roblox world *****
RunService.RenderStepped:Connect(function()

	-- Get current 3D Raycast result (with a {table} of "blacklisted" items to ignore). 
	-- In this case the translucent "spawnedDefender" object (Defender being placed) is ignored when it exists
	local result = MouseRaycast({spawnedDefender})
	
	-- Result of object Mouse/Touch is currently hovering over
	if result and result.Instance then
		--print("Mouse currently over:", result.Instance.Name .. " Material = " .. result.Material.Name)
		local resultInstanceName = result.Instance.Name
		
		-- Are we currently spawning/placing a Defender? 
		-- If so ignore any other "hoveredInstance" determined in the "else" below >>
		if spawnedDefender then
			hoveredInstance = nil
			--print("Parent Name: " .. result.Instance.Parent.Name) 

			--If the mouse is currently over a Defensive Position "part"
			if result.Instance.Parent.Name == "DefPositions" then
				bballPostion = result.Instance.Name
				--print("Position: " .. bballPostion)
				local posHasDefender = false -- Only one Defender allowed per defensive position on the field
				local defenderAlreadyPlaced = false -- Specific Defender can only be placed once
				local invalidDefPosition = false -- Special Defenders (ie "Coach" can only go to a specific position on the field)

				local placedDefenders = workspace.Squad:GetChildren()
				--EX: "Seb-CF" means player "Seb" was placed in Center Field already (see 'Defender' module script)
				--Loop through currently placed Defenders ...
				for _, pd in pairs(placedDefenders) do
					local defPosData = (pd.Name):split("-")
					--print("Position Data = ", defPosData)
					if (defPosData[1] == spawnedDefender.Name and defenderIsMoving == false) then
						defenderAlreadyPlaced = true -- Defender already placed on the field
						break
					end
					if (defPosData[2] == bballPostion and spawnedDefender.Name:split("-")[1] ~= defPosData[1]) then 
						posHasDefender = true --Another Defender already in the Position!
						break
					end

				end

				--Handle special defenders (current just "Coach" > can only go to the "MGR" DefPosition)
				if (spawnedDefender.Name == "Coach" and bballPostion ~= "MGR") then
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
						cantPlaceMessage = "Defender " .. spawnedDefender.Name .. " already on the field!"
					elseif invalidDefPosition then
						cantPlaceMessage = "Position " .. bballPostion .. " invalid for Defender " .. spawnedDefender.Name .. "."
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

			if spawnedDefender:FindFirstChild("Humanoid")  then
				local x = result.Position.X
				local y = result.Position.Y + spawnedDefender.Humanoid.HipHeight + (spawnedDefender.PrimaryPart.Size.Y / 2)
				local z = result.Position.Z	

				local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)
				spawnedDefender:SetPrimaryPartCFrame(cframe)	
			
			end

			
		-- ** Handle every Instance the mouse is currently "hovering" over when we're not spawning/placing a Defender
		elseif (gui.DefendersList.Visible == false and map.DefPositions:FindFirstChild(resultInstanceName)) then
			
			selectedDefPosition = map.DefPositions:FindFirstChild(resultInstanceName)
			hoveredInstance = result.Instance 

		else
			-- Use this variable in the InputBegan event to do different things based on what the "hoveredInsance" is when a click/touch occurs
			hoveredInstance = result.Instance 

		end		

	else
		-- Not hovering over anyting so set variable to "nil"
		hoveredInstance = nil
		selectedDefPosition = nil
	end


end)