
if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- config
	local FFA_ROUND_LEN = 60 -- minutes
	local RESPAWN_DELAY = 2 -- seconds
	local TTT_ROUND_LEN = 5

	AddCSLuaFile()
	
	hook.Add("PlayerSay", "custom_commands_ffa", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!ffa" then ffa_on()
			elseif text == "!ttt" then reg_ttt() 
			elseif text == "!block" then ffa_on() pups_on() end
		end
	end)

	-- restart round and begin free for all deags 
	function ffa_on()

		_drop_hooks()
		local died_with = {}  -- track what weapon player died with. Equip that weapon on spawn
		
		-- HOOKS
		-- assign innocent role to every player
		_add_hook("TTTBeginRound", "ffa_ForceRole", function()
			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
				ply:SetFrags(0)
			end
		end)

		-- on spawn: reset kill trackers, gain and equip weapons
		_add_hook("PlayerSpawn", "ffa_PlayerSpawn", function(ply, transition) 
			ply:SetRole(0)
			local last_wep = died_with[ply:UserID()]
			-- give weapon
			timer.Simple(0.1, function()
				ply:Give("awpv2")
				ply:Give("weapon_ttt_deaglev2")
				ply:Give("barrel_wand")
				if last_wep ~= nil then ply:Give(last_wep) end
			end)
			-- equip weapon
			timer.Simple(0.2, function() 
				if last_wep ~= nil and ply:HasWeapon(last_wep) then
					ply:SelectWeapon(last_wep)
				elseif ply:HasWeapon("barrel_wand") then -- default select
					ply:SelectWeapon("barrel_wand")
				end
			end)
			
		end)
		
		-- on pre-kill: award ammo, record victim's held weapon
		_add_hook("DoPlayerDeath", "ffa_DoPlayerDeath", function(ply, attacker, dmg)
			-- record what victim was holding when killed
			died_with[ply:UserID()] = ply:GetActiveWeapon():GetPrintName()
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
					if inflictor:IsWeapon() and inflictor:GetPrintName() == "barrel_wand" then
						print('x')
					else
						print('y')
						_headshot_effect(victim)
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
		RunConsoleCommand("ttt_preptime_seconds", "15")
		RunConsoleCommand("ttt_roundtime_minutes", TTT_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
	end
end