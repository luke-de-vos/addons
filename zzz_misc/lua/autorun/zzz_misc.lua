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
	function spawn_geag() 
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
	end
	function geag_alert(wep, owner)
		if wep:GetClass() == "weapon_ttt_powerdeagle" then
			owner:PrintMessage(HUD_PRINTCENTER, "GOLDEN DEAG EQUIPPED")
			owner:ChatPrint("GOLDEN DEAG EQUIPPED")
			owner:ChatPrint("Handle with care, soldier. Or don't.")
		end
	end
	hook.Add("TTTBeginRound", "spawn_1_geagle", spawn_geag)
	hook.Add("WeaponEquip","geag_alert", geag_alert)
	--hook.Remove("TTTBeginRound", "spawn_1_geagle")
	--hook.Remove("WeaponEquip","geag_alert")
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



-- DASH
if SERVER then
	-- toggle dashing with chat command
	util.AddNetworkString("dougie_dash_hook")
	hook.Add("PlayerSay", "custom_command_dash", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!dash" then
				net.Start("dougie_dash_hook")
				net.WriteBool(true)
				net.Broadcast()
			elseif text == "!dash_off" then
				net.Start("dougie_dash_hook")
				net.WriteBool(false)
				net.Broadcast()
			end
		end
	end)
	-- trigger dash serverside
	util.AddNetworkString("dougie_trigger_dash")
	net.Receive("dougie_trigger_dash", function(len)
		local ent_index = net.ReadUInt(32)
		local v = net.ReadVector()
		Entity(ent_index):SetVelocity(v)
		Entity(ent_index):EmitSound("Weapon_Crowbar.Single", 70, 50, 0.5, CHAN_BODY)
	end)
end
if CLIENT then
	net.Receive("dougie_dash_hook", function()
		if !net.ReadBool() then
			hook.Remove("Tick", "dash_key")
		else
			local dash_cooldown = 0.5 --seconds
			local next_dash_time = CurTime()
			hook.Add("Tick", "dash_key", function()
				if LocalPlayer():IsValid() and LocalPlayer():KeyDown(IN_ATTACK2) then -- IN_ATTACK2 : right click by default
					if CurTime() >= next_dash_time and LocalPlayer():OnGround() then
						next_dash_time = CurTime() + dash_cooldown
						local dashvec = LocalPlayer():GetAimVector()
						dashvec.z = 0.1
						local keys = {
							LocalPlayer():KeyDown(IN_FORWARD),
							LocalPlayer():KeyDown(IN_MOVERIGHT),
							LocalPlayer():KeyDown(IN_BACK),
							LocalPlayer():KeyDown(IN_MOVELEFT)}
						if keys[1] and keys[2] then dashvec:Rotate(Angle(0,-45,0))
						elseif keys[1] and keys[4] then dashvec:Rotate(Angle(0,45,0))
						elseif keys[3] and keys[2] then dashvec:Rotate(Angle(0,-135,0))
						elseif keys[3] and keys[4] then dashvec:Rotate(Angle(0,135,0))
						elseif keys[1] then
						elseif keys[4] then dashvec:Rotate(Angle(0,90,0))
						elseif keys[2] then dashvec:Rotate(Angle(0,-90,0))
						elseif keys[3] then dashvec:Rotate(Angle(0,180,0))
						else
							dashvec = Vector(0,0,1)
							dashvec:Mul(0.2)
						end
						dashvec:Mul(1500)
						net.Start("dougie_trigger_dash")
						net.WriteUInt(LocalPlayer():EntIndex(), 32)
						net.WriteVector(dashvec)
						net.SendToServer()
					end
				end
			end)
		end
	end)
end

-- cleanup command
hook.Add("PlayerSay", "custom_command_remove_ents", function(sender, text, teamChat)
	if sender:GetUserGroup() ~= "user" then
		if text == "!cleanup" then
			for i,ent in ipairs(ents.GetAll()) do
				local cla = ent:GetClass()
				if cla == "prop_physics" or cla == "prop_dynamic" then
					ent:Remove()
				elseif ent:IsWeapon() and !ent:GetOwner():IsValid() then
					ent:Remove()
				end
			end
		end
	end
end)