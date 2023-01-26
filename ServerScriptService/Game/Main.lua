-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Module Scripts
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
	end
end)

for i=3, 0, -1 do
	guiData.Message.Value = "Game starting in..." .. i
	task.wait(1)
end

for wave=1, 10 do
	guiData.Inning.Value = wave
	guiData.Message.Value = ""
	
	if wave <= 2 then
		mob.Spawn("Zombie", 1 * wave, map)
		task.wait(.25)
		mob.Spawn("Zombie", 1 * wave, map)
		task.wait(.25)
		mob.Spawn("Zombie", 1 * wave, map)
	elseif wave <= 4 then
		for i=1,5 do
			mob.Spawn("Zombie", wave, map)
			mob.Spawn("Noob", wave, map)	
		end		
	elseif wave <= 7 then
		for i=1,5 do
			mob.Spawn("Zombie", wave, map)
			mob.Spawn("Noob", wave, map)	
			mob.Spawn("Mech", 2 * wave, map)	
		end
			
		mob.Spawn("Teddy", 1 * wave, map)	
		mob.Spawn("Mech", 2 * wave, map)	
		mob.Spawn("Zombie", 3 * wave, map)	
		mob.Spawn("Noob", 4 * wave, map)	
	elseif wave <= 9 then
		mob.Spawn("Noob", wave, map)	
		mob.Spawn("Mech", 2 * wave, map)	
		for i=1,5 do
			mob.Spawn("Zombie", 0.5 * wave, map)	
			mob.Spawn("Noob", 0.5 * wave, map)
		end
		mob.Spawn("Teddy", 1, map)
	elseif wave == 10 then			
		mob.Spawn("Zombie", 100, map)
		for i=1, 5 do
			mob.Spawn("Mech", 5, map)
			mob.Spawn("Teddy", 1, map)
			mob.Spawn("Zombie", 2, map)
		end
	end
	
	repeat
		task.wait(1)
	until #workspace.Mobs:GetChildren() == 0 or gameOver
	
	if gameOver then
		guiData.Message.Value = "Game Over!"
		break
	end
	
	for i=5, 0, -1 do
		guiData.Message.Value = "Next Inning starting in..." .. i
		task.wait(1)
	end
end


