print("Executed lua: " .. debug.getinfo(1,'S').source)

-- MAKE EXPLOSION
if SERVER then
	function CreateExplosionAtPosition(pos)
		-- Check if the provided position is valid
		if not pos or not isvector(pos) then
			print("Invalid position.")
			return
		end

		-- Create an explosion entity
		local explosion = ents.Create("env_explosion") 
		if not IsValid(explosion) then 
			print("Failed to create explosion.")
			return
		end

		-- Set explosion attributes
		explosion:SetPos(pos)  
		explosion:Spawn()

		-- Configure the explosion
		explosion:SetKeyValue("iMagnitude","200") 

		-- Trigger the explosion
		explosion:Fire("Explode", "", 0)
		explosion:EmitSound("weapon_AWP.Single", 400, 400 ) 
	end

	-- Example usage:
	-- Replace Vector(0, 0, 0) with your desired position
end