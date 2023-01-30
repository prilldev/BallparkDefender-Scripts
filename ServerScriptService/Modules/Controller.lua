local mob = require(script.Parent.Mob)

local controller = {}

function controller.GetWave(wave, map)


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
			mob.Spawn("Teddy", 5, map)
		end
end

return controller
