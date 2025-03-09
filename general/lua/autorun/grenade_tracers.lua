print("Executed lua: " .. debug.getinfo(1,'S').source)

-- adjust frag grenade damage
if SERVER then
	local MAX_FRAG_DAMAGE = 75
	hook.Add("EntityTakeDamage", "ReduceFragGrenadeDamage", function(target, dmginfo)
		if not target:IsPlayer() then return end
		if IsValid(dmginfo:GetInflictor()) then
			if dmginfo:GetInflictor():GetClass() == "ttt_frag_proj" and dmginfo:IsExplosionDamage() then
				dmginfo:SetDamage((math.min(dmginfo:GetDamage(), 250) / 250) * MAX_FRAG_DAMAGE)
			end
		end
	end)
end

-- GRENADE TRACERS AND SOUNDS
if SERVER then
	local grenade_projectiles = {
		["ttt_frag_proj"] = true,
		["ttt_firegrenade_proj"] = true,
		["ttt_smokegrenade_proj"] = true,
		["ttt_confgrenade_proj"] = true,
	}
	local burn_grenades = {
		["ttt_firegrenade_proj"] = true,
		["ttt_frag_proj"] = true,
	}
	local grenade_sounds = {
		"physics/metal/metal_grenade_impact_hard1.wav",
		"physics/metal/metal_grenade_impact_hard2.wav",
		"physics/metal/metal_grenade_impact_hard3.wav",
	}
	
	hook.Add("OnEntityCreated", "TrackGrenadeThrows", function(ent)
		if grenade_projectiles[ent:GetClass()] then
			ent:EmitSound("WeaponFrag.Throw", 75, 100, 0.8, CHAN_BODY)
			timer.Simple(0.02, function()
				if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
					function ent:PhysicsCollide(data, phys)
						-- if ent is over certain speed, play sound
						if data.DeltaTime > 0.05 and data.Speed > 20 then
							ent:EmitSound(grenade_sounds[math.random(1,3)], 65, 100, 1.1)
							-- if is player, and is frag/molotov grenade, damage player 
							if IsValid(data.HitEntity) and data.HitEntity:IsPlayer() then
								if burn_grenades[ent:GetClass()] then
									local dmginfo = DamageInfo()
									dmginfo:SetDamage(10)
									dmginfo:SetDamageType(DMG_BURN)
									dmginfo:SetAttacker(ent:GetOwner())
									dmginfo:SetInflictor(ent)
									data.HitEntity:TakeDamageInfo(dmginfo)
								end
							end
						end
						-- queue explosion if not smoke grenade
						if ent:GetClass() != "ttt_smokegrenade_proj" then -- for some reason, smoke grenades don't explode with Explode()
							if not timer.Exists("collision_timer_"..ent:EntIndex()) then
								timer.Create("collision_timer_"..ent:EntIndex(), 0.5, 1, function()
									if IsValid(ent) then
										ent:Explode(util.TraceLine({
											start = ent:GetPos(),
											endpos = ent:GetPos() + ent:GetVelocity():GetNormalized() * 100,
											filter = ent
										}))
									end
								end)
							end
						end

					end
				end
			end)
		end

		-- grenade-specific sounds and tracers
		if ent:GetClass() == "ttt_frag_proj" then
			util.SpriteTrail(
				ent, 0, Color(255, 0, 0), false, 10, 1, 0.1, 1/(10+1)*0.5, "trails/laser"
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
	
end
