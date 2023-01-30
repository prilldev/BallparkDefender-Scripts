-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local gui = game:GetService("StarterGui")

-- Module Scripts
local controller = require(ServerScriptService.Modules.Controller)
local mob = require(ServerScriptService.Modules.Mob)
local defender = require(ServerScriptService.Modules.Defender)

-- Workspace variables
local map = workspace.Maps.GrassLand
local guiData = workspace.GUIData

-- Control variables
local gameOver = false
local msgGreenColor = Color3.fromHSV(0.309083, 0.771023, 0.839216) --soft green
local msgRedColor = Color3.fromHSV(0.0140833, 0.639643, 0.870588) --soft red (salmon)

map.Ballpark.Humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		gameOver = true
		gui.GameGui.Info.Message.TextColor3 = msgRedColor
		guiData.Message.Value = "GAME OVER"
	end
end)

for i=3, 0, -1 do
	guiData.Message.Value = "Game starting in..." .. i
	task.wait(1)
end

for wave=1, 10 do
	guiData.Inning.Value = wave
	if wave == 1 then
		guiData.Message.Value = "Select a Defender then place them in a position on the field. You can add one defender per inning..."
	else
		
	
	end
	
	controller.GetWave(wave, map)
	
	repeat
		task.wait(1)
	until #workspace.Mobs:GetChildren() == 0 or gameOver
	
	if not gameOver and wave == 10 then
		gui.GameGui.Info.Message.TextColor3 = msgGreenColor
		guiData.Message.Value = "VICTORY"
	elseif not gameOver then
		gui.GameGui.Info.Message.TextColor3 = msgGreenColor
		
		local reward = 50 * wave
		for i, player in ipairs(Players:GetPlayers()) do
			player.leaderstats.Gold.Value += reward -- Wave/Inning completion bonus
		end
		guiData.Message.Value = "Inning Reward: " .. reward
		task.wait(2)
		
		for i=5, 0, -1 do
			guiData.Message.Value = "Next Inning starting in..." .. i
			task.wait(1)
		end
		guiData.Message.Value = "New Inning... Place another Defender!"
	else
		break
	end

end

if not gameOver then
	guiData.Message.Value = "VICTORY"
end


