print("Executed lua: " .. debug.getinfo(1,'S').source)

-- GRENADE TRACERS AND SOUNDS
if SERVER then
	local grenadeTypes = {
		["ttt_frag_proj"] = true,
		["ttt_firegrenade_proj"] = true,
		["ttt_smokegrenade_proj"] = true,
		["ttt_confgrenade_proj"] = true,
	}
	local grenade_sounds = {
		"physics/metal/metal_grenade_impact_hard1.wav",
		"physics/metal/metal_grenade_impact_hard2.wav",
		"physics/metal/metal_grenade_impact_hard3.wav",
	}
	hook.Add("OnEntityCreated", "TrackGrenadeThrows", function(ent)

		if grenadeTypes[ent:GetClass()] then
			-- play sound when any grenade is thrown
			timer.Simple(0.05, function() 
				ent:EmitSound("WeaponFrag.Throw", 75, 100, 0.8, CHAN_BODY)
				if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
					function ent:PhysicsCollide(data, phys)
						-- if ent is over certain speed, play sound
						if data.DeltaTime > 0.05 and data.Speed > 20 then
							self:EmitSound(grenade_sounds[math.random(1,3)], 65, 100)
						end
					end
				end
			end)
		end

		-- grenade-specific sounds and tracers
		if ent:GetClass() == "ttt_frag_proj" then
			util.SpriteTrail(
				ent, 0, Color(255, 0, 0), false, 10, 1, 0.3, 1/(10+1)*0.5, "trails/laser"
			)
			-- make the grenade beep
			timer.Create("beep_timer_"..ent:EntIndex(), 0.15, 30, function()
				if !IsValid(ent) then return end
				ent:EmitSound("buttons/blip1.wav", 70, 200, 0.8, CHAN_AUTO)
			end)
		elseif ent:GetClass() == "ttt_firegrenade_proj" then
			util.SpriteTrail(ent, 0, Color(255, 255, 0), false, 10, 1, 0.1, 1/(10+1)*0.5, "trails/laser")
			timer.Create("beep_timer_"..ent:EntIndex(), 0.33, 20, function()
				if !IsValid(ent) then return end
				--ent:EmitSound("buttons/blip1.wav", 70, 50, 0.8, CHAN_AUTO)
			end)
		-- elseif ent:GetClass() == "ttt_confgrenade_proj" then
		-- 	util.SpriteTrail(ent, 0, Color(255, 0, 0), false, 10, 1, 0.1, 1/(10+1)*0.5, "trails/laser")
		-- 	timer.Create("beep_timer_"..ent:EntIndex(), 0.25, 35, function()
		-- 		if !IsValid(ent) then return end
		-- 		--ent:EmitSound("buttons/blip1.wav", 70, math.random(80,120), 0.5, CHAN_AUTO)
		-- 	end)
		end
		
	end)

	hook.Add("OnEntityCreated", "SmokeGrenadeCollisionSound", function(ent)
		if ent:GetClass() == "ttt_smokegrenade_proj" then
			
		end
	end)

	
end