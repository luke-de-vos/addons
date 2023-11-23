
if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- config
	local FFA_ROUND_LEN = 60 -- minutes
	local RESPAWN_DELAY = 2 -- seconds

	-- declare variables in scope shared between ffa on/off functions
	local orig_preptime = nil
	local orig_roundtime = nil
	local orig_credits = nil
	local orig_debug = nil
	local orig_shop = nil

	
	-- con command instead
	concommand.Add("ffa", function(ply, cmd, args)
		if !IsValid(ply) then return end
		if !ply:IsAdmin() then return end

		if args[1] == "on" then
			ffa_on(ply:GetActiveWeapon():GetClass())
		elseif args[1] == "off" then
			ffa_off()
		else
			print("Invalid argument. Please use 'on' or 'off'.")
		end

	end)
	

	-- restart round and begin ffa
	function ffa_on(req_weapon)

		if weapons.Get(req_weapon) == nil then
			print("ffa_on() failed: req_weapon invalid.")
			return
		end

		-- allow players to respawn themselves by chatting
		hook.Add("PlayerSay", "ffa_chat_to_spawn", function(sender, text, teamChat)
			RunConsoleCommand("ulx", "respawn", sender:Name()) 
		end)

		-- assign innocent role to every player
		hook.Add("TTTBeginRound", "ffa_ForceRole", function()
			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
				ply:SetFrags(0)
			end
		end)

		-- on spawn: reset kill trackers, gain and equip weapons
		hook.Add("PlayerLoadout", "ffa_PlayerLoadout", function(ply)

			-- set role to innocent
			ply:SetRole(0)

			-- give weapon
			ply:Give(req_weapon)
			ply:Give("weapon_zm_improvised")
			ply:Give("weapon_ttt_unarmed")
			ply:Give("weapon_zm_carry")

			-- equip weapon
			timer.Simple(0.2, function()
				ply:SelectWeapon(req_weapon)
				_give_current_ammo(ply, 10)
			end)

			return true -- override default loadout
			
		end)
		
		-- on pre-kill: remove weapons so they are not dropped and clutter the map
		hook.Add("DoPlayerDeath", "ffa_DoPlayerDeath", function(ply, attacker, dmg)
			if IsValid(ply:GetActiveWeapon()) then ply:GetActiveWeapon():Remove() end
			for i,ent in ipairs(ply:GetWeapons()) do
				ent:Remove()
			end
		end)
		
		-- on kill: award frag, print killfeed, prepare respawn
		hook.Add("PlayerDeath", "ffa_PlayerDeath", function(victim, inflictor, attacker)

			if (attacker:IsPlayer()) then
				attacker:AddFrags(1)
				if victim:LastHitGroup() == 1 then
					PrintMessage(HUD_PRINTTALK, attacker:GetName().." killed (X) "..victim:GetName())
				else
					PrintMessage(HUD_PRINTTALK, attacker:GetName().." killed "..victim:GetName())
				end
			else
				PrintMessage(HUD_PRINTTALK, victim:GetName() .. " died.")
			end

			timer.Simple(RESPAWN_DELAY, function()
				if IsValid(victim) and !victim:Alive() then
					victim:Spawn()
				end
			end)

		end)

		-- record original values of cvars
		orig_shop = GetConVar("ttt_inno_shop_fallback"):GetString()
		orig_credits = GetConVar("ttt_inno_credits_starting"):GetString()
		orig_debug = GetConVar("ttt_debug_preventwin"):GetString()
		orig_preptime = GetConVar("ttt_preptime_seconds"):GetString()
		orig_roundtime = GetConVar("ttt_roundtime_minutes"):GetString()

		RunConsoleCommand("ttt_inno_shop_fallback", "innocent")
		RunConsoleCommand("ttt_inno_credits_starting", "99")
		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "1")
		RunConsoleCommand("ttt_roundtime_minutes", FFA_ROUND_LEN)
		RunConsoleCommand("ulx", "roundrestart")
		
	end

	-- undo ffa_on()
	function ffa_off()
		hook.Remove("PlayerSay", "ffa_chat_to_spawn")
		hook.Remove("TTTBeginRound", "ffa_ForceRole")
		hook.Remove("PlayerLoadout", "ffa_PlayerLoadout")
		hook.Remove("DoPlayerDeath", "ffa_DoPlayerDeath")
		hook.Remove("PlayerDeath", "ffa_PlayerDeath")

		RunConsoleCommand("ttt_inno_shop_fallback", orig_shop)
		RunConsoleCommand("ttt_inno_credits_starting", orig_credits)
		RunConsoleCommand("ttt_debug_preventwin", orig_debug)
		RunConsoleCommand("ttt_preptime_seconds", orig_preptime)
		RunConsoleCommand("ttt_roundtime_minutes", orig_roundtime)
		RunConsoleCommand("ulx", "roundrestart")
	end
end


