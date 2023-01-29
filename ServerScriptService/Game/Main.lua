-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Module Scripts
local gamecontrol = require(ServerScriptService.Modules.GameControl)
local mob = require(ServerScriptService.Modules.Mob)
local defender = require(ServerScriptService.Modules.Defender)

-- Workspace variables
local map = workspace.Maps.GrassLand
local guiData = workspace.GUIData

-- Control variables
local gameOver = false

map.Ballpark.Humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		gameOver = true
		guiData.Message.Value = "GAME OVER"
	end
end)

for i=3, 0, -1 do
	guiData.Message.Value = "Game starting in..." .. i
	task.wait(1)
end

for wave=1, 10 do
	guiData.Inning.Value = wave
	guiData.Message.Value = ""
	
	gamecontrol.GetWave(wave, map)
	
	repeat
		task.wait(1)
	until #workspace.Mobs:GetChildren() == 0 or gameOver
	
	if not gameOver and wave == 10 then
		guiData.Message.Value = "VICTORY"
	elseif not gameOver then
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
		
	else
		break
	end

end

if not gameOver then
	guiData.Message.Value = "VICTORY"
end


