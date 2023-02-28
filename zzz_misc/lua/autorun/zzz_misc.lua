print("Executed lua: " .. debug.getinfo(1,'S').source)

-- arm damage
if SERVER then
	hook.Add("ScalePlayerDamage", "arm_damage3", function(ply, hitgroup, dmginfo) 
		if (hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM) then
			dmginfo:ScaleDamage(1.85) -- set arm damage equal to body damage
		 end
	end)
end

-- spawn geagle(s). alert player when picked up
if SERVER then
    hook.Add("TTTBeginRound", "spawn_1_geagle", function()
        local options = {}
        for i, ent in ipairs(ents.GetAll()) do
            if ent:IsWeapon() then
                table.insert(options, ent:GetPos())
            end
        end
        if #options >= 1 then
            local geagle = ents.Create("weapon_ttt_powerdeagle")
            geagle:SetPos(options[math.random(#options)] + Vector(0,0,30))
            geagle:Spawn()
        end
    end)
	hook.Add("WeaponEquip","geag_alert", function(wep, owner)
		owner:PrintMessage(HUD_PRINTCENTER, "YOU GOT THA GEAG")
	end)
end

-- hup!
hook.Add("OnKeyPressed???", "hup_hook", function(ply)
    sound.Play("hup", ply:GetPos()+Vector(0,0,70), 100, 100, 100)
end)


-- hitmarker sound
if SERVER then
    resource.AddFile("sound/hit.wav")
    util.AddNetworkString("zz_hitmarker_sound_msg")
    hook.Add("EntityTakeDamage", "zz_hitmarker_sound", function(vic, dmg)
        if vic:IsPlayer() and dmg:GetAttacker():IsPlayer() then
            if dmg:GetDamage() >= 1 then -- this doesn't work
                net.Start("zz_hitmarker_sound_msg")
                net.Send(dmg:GetAttacker())
            end
        end
    end)
end
if CLIENT then
    net.Receive("zz_hitmarker_sound_msg", function()
		surface.PlaySound("hit.wav")
	end)
end


-- speedometer
if CLIENT then
	local recent_max = 0
	local recent_max_set_at = 0
	local recent_window = 5 --seconds
	hook.Add("DrawOverlay", "draw_speed_hook", function()
		if IsValid(LocalPlayer()) then
			local vel = LocalPlayer():GetVelocity()
			vel = math.Round(math.sqrt((vel.x^2+vel.y^2+vel.z^2)) / 27.119, 1)
			if vel >= 12 then
				draw.DrawText(vel.." mph", "DermaDefault", 288, 45, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(vel.." mph", "DermaDefault", 287, 44, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
			if vel > recent_max then
				recent_max_set_at = CurTime()
				recent_max = vel
			end
			if CurTime() - recent_max_set_at >= recent_window then
				recent_max = 0
			end
			if recent_max >= 12 then
				draw.DrawText(recent_max.." mph", "DermaDefault", 289, 66, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 288, 65, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 287, 64, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
		end
	end)
end




if SERVER then
	hook.Add("Tick", "dash_key", function()
		if (Entity(1):KeyDown(2)) then
			Entity(1):SetVelocity(Entity(1):GetAimVector()*100+Vector(0,0,20))
			-- if Entity(1):KeyDown(IN_MOVELEFT) then
			-- 	Entity(1):SetVelocity(Entity(1):GetAimVector()*100)
			-- end
			-- if Entity(1):KeyDown(IN_MOVERIGHT) then
			-- 	Entity(1):SetVelocity(Entity(1):GetAimVector()*100)
			-- end
			-- if Entity(1):KeyDown(IN_FORWARD) then
			-- 	Entity(1):SetVelocity(Entity(1):GetAimVector()*100)
			-- end	
			-- if Entity(1):KeyDown(IN_BACK) then
			-- 	Entity(1):SetVelocity(Entity(1):GetAimVector()*100)
			-- end
		end
	end)
	--hook.Remove("Tick","dash_key")
end


if SERVER then
	for ent in ipairs(entity.Lis)
end