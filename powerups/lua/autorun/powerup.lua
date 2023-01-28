print("Executed lua: " .. debug.getinfo(1,'S').source)

if CLIENT then
	net.Receive("powerup_waypoint_msg", function() 
		RADAR.targets = {}
		local pos = Vector()
		pos.x = net.ReadInt(32)
		pos.y = net.ReadInt(32)
		pos.z = net.ReadInt(32)
		table.insert(RADAR.targets, {role=0, pos=pos})
		RADAR.enable = true
	end)
end

if SERVER then	
	hook.Add("PlayerSay", "custom_commands_powerups", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!pups" then pups_on() end
		end
	end)
end

function pups_on()
	if SERVER then
		util.AddNetworkString("powerup_waypoint_msg")
		-- block initial spawn
		_add_hook('TTTBeginRound', "spawn_pups", function()
			for i,ammo_ent in ipairs(ents.FindByClass("item_ammo_smg1*")) do
				local ent = ents.Create("ent1")
				if not IsValid(ent) then return end
				ent.SpawnPoint = ammo_ent:GetPos() + Vector(0,0,30)
				ent:SetPos(ent.SpawnPoint)
				ent:Spawn()
			end
		end)

		-- serverside think handles score and radar
		local lrt = CurTime()
		_add_hook("Think", "gm_tick_powerup", function()
			--print(CurTime().." "..block_id)
			if CurTime() - lrt >= 1 then
				lrt = CurTime()
				local ent = Entity(block_id)
				if IsValid(ent) then
					if ent:IsPlayer() then
						ent:AddFrags(1)
						if ent:Frags() == 200 then
							PrintMessage(HUD_PRINTCENTER, ent:Nick().." wins!")
						end
					end
					local block_pos = ent:GetPos()
					if ent:IsPlayer() then block_pos.z = block_pos.z + 45 end
					net.Start("powerup_waypoint_msg")
					net.WriteInt(block_pos.x, 32)
					net.WriteInt(block_pos.y, 32)
					net.WriteInt(block_pos.z, 32)
					local rec = RecipientFilter()
					rec:AddAllPlayers()
					net.Send(rec)
				end
			end
		end)

		-- 
		_add_hook("DoPlayerDeath", "powerup_shared_death", function(victim, attacker, dmg)
			-- spawn block if necessary
			if victim:EntIndex() == block_id then
				local ent = ents.Create("ent1")
				if not IsValid(ent) then return end
				ent:SetPos(victim:GetPos()+Vector(0,0,30))
				ent:Spawn()
				PrintMessage(HUD_PRINTTALK, "BLOCK: DROPPED")
				victim:SetRole(0)
			end
			-- bonus points if block holder got the kill
			if attacker:IsPlayer() and attacker:GetRole() == 2 then
				attacker:AddFrags(10)
				if ent:Frags() == 200 then
					PrintMessage(HUD_PRINTCENTER, ent:Nick().." wins!")
				end
			end
		end)
	end
end