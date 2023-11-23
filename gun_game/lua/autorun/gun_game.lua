--gun_game
if SERVER then

	-- declare variables in scope shared between gg on/off functions
	local orig_preptime = nil
	local orig_roundtime = nil
	local orig_debug = nil

	local RESPAWN_DELAY = 2 -- seconds

	-- gungame con command
	concommand.Add("gungame", function(ply, cmd, args)
		if !ply:IsValid() then return end
		if !ply:IsAdmin() then return end

		if #args == 1 then 
			if args[1] == "off" then
				gungame_off()
			else
				local kills_to_win = tonumber(args[1])
				if kills_to_win and kills_to_win >= 1 then
					gungame_on(kills_to_win)
				end
			end
		else
			print("gungame command usage: gungame <kills_to_win or 'off'>")
		end
	end)

	local function get_guns_table()
		local weapon_options = {
			"awpv2",
			"barrel_wand",
			"melonlauncher",
			"ttt_thomas_swep",
			"weapon_banana",
			"weapon_minigun",
			"weapon_ttt_ak47gold",
			"weapon_ttt_aug",
			"weapon_ttt_deaglev2",
			"weapon_ttt_famas",
			"weapon_ttt_g3sg1",
			"weapon_ttt_glock",
			"weapon_ttt_homebat",
			"weapon_ttt_knife",
			"weapon_ttt_m16",
			"weapon_ttt_mp5",
			"weapon_ttt_p228",
			"weapon_ttt_pistol",
			"weapon_ttt_pump",
			"weapon_ttt_sg552",
			"weapon_ttt_shankknife",
			"weapon_ttt_tmp_s",
			"weapon_ttt_traitor_lightsaber",
			"weapon_zm_revolver",
			"weapon_zm_rifle",
			"weapon_zm_shotgun",
			"weapon_zm_sledge"
		}

		-- randomize order
		local rand_t = {}
		for i, gun_name in RandomPairs(weapon_options) do
			table.insert(rand_t, gun_name)
		end

		-- replace final weapon with crowbar
		table.remove(rand_t, #rand_t)
		table.insert(rand_t, "weapon_zm_improvised")

		return rand_t
	end

	local function update_weapon(ply, guns)
		ply:SetFOV(0, 0.15) -- adjust FOV to default over 0.15 seconds
		
		local on_gun_id = math.min(ply:Frags(), #guns) + 1 -- +1 because lua table indices begin at 1
		local gungame_gun = guns[on_gun_id] 
		
		timer.Simple(0.2, function()
			ply:StripWeapons()
			ply:Give(gungame_gun)
			ply:SelectWeapon(gungame_gun)
			_give_current_ammo(ply, 3)
		end)

		if gungame_gun == "weapon_ttt_homebat" then
			ply:SetWalkSpeed(325) -- extra speed for homerun bat
		else
			ply:SetWalkSpeed(250) -- default walk speed
		end

	end

	function gungame_on(kills_to_win)

		-- setup
		local guns = get_guns_table()
		local someone_already_won = false
		
		for i,ply in ipairs(player.GetAll()) do
			ply:SetRole(0)
			ply:SetFrags(0)
		end

		-- set players to innocent, reset frags, remove all weapons from map
		hook.Add("TTTBeginRound", "gg_BeginRound", function()
			PrintMessage(HUD_PRINTCENTER, "GUN GAME")
			someone_already_won = false

			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
				ply:SetFrags(0)
			end

			-- remove all weapons that spawned on map
			for id, ent in ipairs(ents.GetAll()) do
				if ent:IsWeapon() and !ent:GetOwner():IsPlayer() then
					ent:Remove()
				end
			end
			
		end)

		-- allow players to respawn themselves by chatting
		hook.Add("PlayerSay", "gg_chat_to_spawn", function(sender, text, teamChat)
			RunConsoleCommand("ulx", "respawn", sender:Name()) 
		end)

		-- on respawn: equip current gun game weapon
		hook.Add("PlayerSpawn", "gg_PlayerSpawn", function(ply, transition)
			ply:SetRole(0)
			update_weapon(ply, guns)
		end)

		-- on pre-kill: remove weapons so they are not dropped and clutter the map
		hook.Add("DoPlayerDeath", "gg_no_weapon_drop", function(victim, attacker, dmgInfo)
			if IsValid(victim:GetActiveWeapon()) then victim:GetActiveWeapon():Remove() end
			for i,ent in ipairs(victim:GetWeapons()) do
				ent:Remove()
			end
		end)

		-- on pre-kill: player moves onto next weapon or wins
		hook.Add("DoPlayerDeath", "gg_advancement", function(victim, attacker, dmgInfo)
			if !attacker:IsPlayer() then return end
			if victim == attacker then return end

			attacker:AddFrags(1)
			update_weapon(attacker, guns)
			if attacker:Frags() >= kills_to_win and !someone_already_won then
				someone_already_won = true
				PrintMessage(HUD_PRINTCENTER, attacker:Nick().." wins!")
				PrintMessage(HUD_PRINTTALK, attacker:Nick().." wins!")
				_highlight_kill(victim, attacker, 0.3, 5)
			end
		end)

		-- on kill: print killfeed, prepare respawn
		hook.Add("PlayerDeath", "gg_PlayerDeath", function(victim, inflictor, attacker)

			if (attacker:IsPlayer()) then
				if victim:LastHitGroup() == 1 then
					PrintMessage(HUD_PRINTTALK, attacker:Nick().." killed (X) "..victim:Nick())
				else
					PrintMessage(HUD_PRINTTALK, attacker:Nick().." killed "..victim:Nick())
				end
			else
				PrintMessage(HUD_PRINTTALK, victim:Nick() .. " died.")
			end

			timer.Simple(RESPAWN_DELAY, function()
				if IsValid(victim) and !victim:Alive() then
					victim:Spawn()
				end
			end)

		end)

		orig_roundtime = GetConVar("ttt_roundtime_minutes"):GetString()
		orig_debug = GetConVar("ttt_debug_preventwin"):GetString()
		orig_preptime = GetConVar("ttt_preptime_seconds"):GetString()

		RunConsoleCommand("ttt_roundtime_minutes", "60")
		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "1")
		RunConsoleCommand("ulx", "roundrestart")

	end

	function gungame_off()

		-- remove hooks
		hook.Remove("TTTBeginRound", "gg_BeginRound")
		hook.Remove("PlayerSay", "gg_chat_to_spawn")
		hook.Remove("PlayerSpawn", "gg_PlayerSpawn")
		hook.Remove("DoPlayerDeath", "gg_no_weapon_drop")
		hook.Remove("DoPlayerDeath", "gg_advancement")
		hook.Remove("PlayerDeath", "gg_PlayerDeath")

		RunConsoleCommand("ttt_roundtime_minutes", orig_roundtime)
		RunConsoleCommand("ttt_debug_preventwin", orig_debug)
		RunConsoleCommand("ttt_preptime_seconds", orig_preptime)
		RunConsoleCommand("ulx", "roundrestart")
	end
	
end