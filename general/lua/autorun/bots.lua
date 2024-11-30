
if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	AddCSLuaFile()
	
	hook.Add("PlayerSay", "custom_commands_bots", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!bots_on" then bots_on()
			elseif text == "!bots_off" then bots_off() 
			elseif text == "!fight" then bot_fight() end
		end
	end)

	-- spawn bots until there are 16 players
	function bots_on()
		for i=1,16-player.GetCount() do
			--player.CreateNextBot("Bot" .. i) -- bots created with this func do not move for some reason
			RunConsoleCommand("bot") 
		end
		timer.Simple(1, function() 
			RunConsoleCommand("bot_zombie","1")
		end)	
	end
	-- kick bots
	function bots_off()
		for i, bot in ipairs(player.GetBots()) do
			bot:Kick()
		end
	end
	
	function bot_fight()
		_add_hook("Think", "BW_bot_behavior", function()
			for i,ply in ipairs(player.GetAll()) do
				if ply:SteamID() != "BOT" then continue end
				local target = get_closest_player(ply)
				if target != nil then
					if IsValid(ply) then
						local r = math.random()
						if r <= 0.01 then -- do leap
							ply:SetEyeAngles((target:GetPos() + Vector(0,0,500) - ply:GetPos()):Angle())
							attempt_attack(ply, 2) 
						elseif r <= 0.50 then -- attack
							local posdiff = target:GetPos() - ply:GetPos() + VectorRand(-20,20)
							ply:SetEyeAngles(posdiff:Angle())
							local tr = ply:GetEyeTrace()
							if tr.Entity:IsPlayer() then
								if _get_euc_dist(tr.Entity:GetPos(), ply:GetPos()) < 6000 then
									attempt_attack(ply, 3)
								else
									attempt_attack(ply, 1)
								end
								if math.random() < 0.75 then -- chance for bot target to attempt parry
									if target:SteamID() == "BOT" then attempt_attack(target, 2) end
								end
							elseif _get_euc_dist(tr.HitPos, ply:GetPos()) < 10 then -- likely face against wall
								ply:GetActiveWeapon():SecondaryAttack()
							end
						end
					end
				end
			end
		end)
	end

	function attempt_attack(ply, attack_type)
		-- attack_type (int) 1 or 2 for primary and secondary attack respectively
		timer.Simple(0.5, function()
			if IsValid(ply) and IsValid(ply:GetActiveWeapon()) then
				if attack_type == 1 then
					ply:GetActiveWeapon():PrimaryAttack()
				elseif attack_type == 2 then
					ply:GetActiveWeapon():SecondaryAttack()		
				elseif attack_type == 3 then
					ply:GetActiveWeapon():Reload()
				end			
			end
		end)
	end	

	function get_closest_player(source)
		if !IsValid(source) then return end
		local prop_pos = source:GetPos()
		local best_ply = nil
		local this_distance = 0
		local lowest_distance = 9999999
		for i, ply in ipairs(player.GetAll()) do
			if source:Nick() == ply:Nick() then continue end
			if not ply:Alive() then continue end
			--if ply:GetRole() != ROLE_INNOCENT then continue end
			local ply_pos = ply:GetPos()
			ply_pos.z = ply_pos.z + 30 -- center mass
			this_distance = _get_euc_dist(prop_pos, ply_pos)
			if this_distance < lowest_distance then
				lowest_distance = this_distance
				best_ply = ply
			end
		end
		return best_ply
	end

	
end