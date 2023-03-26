
if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- config
	local FFA_ROUND_LEN = 60 -- minutes
	local RESPAWN_DELAY = 2 -- seconds
	local TTT_ROUND_LEN = 8

	AddCSLuaFile()
	
	local DEFAULT_WEAPON = "barrel_wand"
	local req_weapon = DEFAULT_WEAPON -- DEFAULT. USED UNLESS SPECIFIED IN COMMAND
	hook.Add("PlayerSay", "custom_commands_ffa", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			args = _my_split(text, " ")
			if args then
				if args[1] == '!ffa' then
					if #args > 1 then
						req_weapon = args[2]
						if req_weapon == "mywep" and IsValid(sender:GetActiveWeapon()) then
							req_weapon = sender:GetActiveWeapon():GetClass()
						end
					end
					ffa_on(req_weapon)
				elseif args[1] == "!ttt" then reg_ttt() 
				elseif args[1] == "!block" then ffa_on(req_weapon) pups_on() end
			end
		end
	end)

	-- restart round and begin free for all deags 
	function ffa_on(req_weapon)
		_drop_hooks()
		local died_with = {}  -- track what weapon player died with. Equip that weapon on spawn
		
		-- HOOKS
		-- assign innocent role to every player
		_add_hook("TTTBeginRound", "ffa_ForceRole", function()
			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
				ply:SetFrags(0)
				died_with = {}
			end
		end)

		-- on spawn: reset kill trackers, gain and equip weapons
		_add_hook("PlayerSpawn", "ffa_PlayerSpawn", function(ply, transition)
			ply:SetRole(0)
			local given_weapon = nil
			local last_wep = died_with[ply:UserID()]
			-- give weapon
			timer.Simple(0.2, function()
				if last_wep ~= nil then
					ply:Give(last_wep)
					given_weapon = last_wep
				else
					local gave_request = nil
					gave_request = IsValid(ply:Give(req_weapon))
					given_weapon = req_weapon
					if !gave_request then
						print('Failed to GIVE '..req_weapon)
						ply:Give(DEFAULT_WEAPON)
						given_weapon = DEFAULT_WEAPON
					end
				end
			end)
			if last_wep ~= nil then
				ply:Give(last_wep)
				given_weapon = last_wep
			else
				local gave_request = nil
				gave_request = IsValid(ply:Give(req_weapon))
				given_weapon = req_weapon
				if !gave_request then
					print('Failed to GIVE '..req_weapon)
					ply:Give(DEFAULT_WEAPON)
					given_weapon = DEFAULT_WEAPON
				end
			end

			-- equip weapon
			timer.Simple(0.3, function()
				ply:SelectWeapon(req_weapon)
				_give_current_ammo(ply, 10)
			end)
			
		end)
		
		-- on pre-kill: award ammo, record victim's held weapon
		_add_hook("DoPlayerDeath", "ffa_DoPlayerDeath", function(ply, attacker, dmg)
			-- record what victim was holding when killed
			died_with[ply:UserID()] = ply:GetActiveWeapon():GetClass()
			-- killer gets a mag for current weapon
			if (attacker:IsPlayer() and attacker:UserID() ~= ply:UserID() ) then 
				_give_current_ammo(attacker, 1)
				--attacker:AddFrags(1)
			end
			-- do not drop weapons
			if IsValid(ply:GetActiveWeapon()) then ply:GetActiveWeapon():Remove() end
			for i,ent in ipairs(ply:GetWeapons()) do
				ent:Remove()
			end
			
		end)
		
		-- on kill: play headshot effect, print killfeed, begin respawn
		_add_hook("PlayerDeath", "ffa_PlayerDeath", function(victim, inflictor, attacker)
			if (attacker:IsPlayer()) then
				attacker:AddFrags(1)
				if victim:LastHitGroup() == 1 then
					if inflictor:GetClass() != 'prop_physics' then
						--_headshot_effect(victim)
					end
				end
			end
			_print_kill(victim, attacker)
			_respawn(victim, RESPAWN_DELAY) 
		end)	

		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "2")
		RunConsoleCommand("ttt_roundtime_minutes", FFA_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
		
	end

	-- undo ffa_on()
	function reg_ttt()
		_drop_hooks()
		RunConsoleCommand("ttt_debug_preventwin", "0")
		RunConsoleCommand("ttt_preptime_seconds", "25")
		RunConsoleCommand("ttt_roundtime_minutes", TTT_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
	end
end