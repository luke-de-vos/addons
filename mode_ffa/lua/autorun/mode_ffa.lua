
if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- config
	local FFA_ROUND_LEN = 60 -- minutes
	local RESPAWN_DELAY = 2 -- seconds
	local TTT_ROUND_LEN = 8

	AddCSLuaFile()
	
	local DEFAULT_WEAPON = "weapon_zm_revolver"
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

		_add_hook("PlayerSay", "ffa_chat_to_spawn", function(sender, text, teamChat)
			RunConsoleCommand("ulx", "respawn", sender:Name()) 
		end)

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
		_add_hook("PlayerLoadout", "ffa_PlayerLoadout", function(ply)
			ply:SetRole(0)
			local given_weapon = nil
			--local last_wep = died_with[ply:UserID()]
			-- give weapon
			if !(ply:Give(req_weapon)) then
				ply:Give(DEFAULT_WEAPON)
			end
			ply:Give("weapon_zm_improvised")
			ply:Give("weapon_ttt_unarmed")

			-- equip weapon
			timer.Simple(0.2, function()
				ply:SelectWeapon(req_weapon)
				_give_current_ammo(ply, 10)
			end)

			return true -- override default loadout
			
		end)
		
		-- on pre-kill: award ammo, record victim's held weapon
		_add_hook("DoPlayerDeath", "ffa_DoPlayerDeath", function(ply, attacker, dmg)
			-- record what victim was holding when killed
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then
				died_with[ply:UserID()] = wep:GetClass()
			elseif !IsValid(died_with[ply:UserID()]) then
				died_with[ply:UserID()] = DEFAULT_WEAPON
			end -- don't update if something already there
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

		RunConsoleCommand("ttt_inno_shop_fallback", "innocent")
		RunConsoleCommand("ttt_inno_credits_starting", "10")
		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "1")
		RunConsoleCommand("ttt_roundtime_minutes", FFA_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
		
	end

	-- undo ffa_on()
	function reg_ttt()
		_drop_hooks()
		RunConsoleCommand("ttt_inno_credits_starting", "0")
		RunConsoleCommand("ttt_debug_preventwin", "0")
		RunConsoleCommand("ttt_preptime_seconds", "25")
		RunConsoleCommand("ttt_roundtime_minutes", TTT_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
		RunConsoleCommand("ttt_inno_shop_fallback", "DISABLED")
	end
end


