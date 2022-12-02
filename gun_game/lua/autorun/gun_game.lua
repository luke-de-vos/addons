--gun_game
if SERVER then

	print("Executed lua: " .. debug.getinfo(1,'S').source)

	local someone_already_won = false

	local GUN_GAME_ROUND_LEN = 30
	local INCREASED_SPEED = 325
	local RESPAWN_DELAY = 2 -- seconds
	local TTT_ROUND_LEN = 5
	local guns = {}

	-- enable chat command
	hook.Add("PlayerSay", "custom_commands_gungame", function(sender, text, teamChat)
		args = _parse_command(sender, text, "!gungame")
		if args then
			local kills_to_win = tonumber(args[2])
			if kills_to_win and kills_to_win >= 1 then
				gungame_on(kills_to_win)
			end
		end
	end)

	local function update_weapon(ply, guns, kills_to_win)
		ply:SetFOV(0, 0.15) -- set fov to default
		ply:SetWalkSpeed(250) -- set movement speed to default
		
		local gungame_gun = nil
		if ply:Frags() >= kills_to_win-1 then -- last kill always crowbar
			gungame_gun = "weapon_zm_improvised"
		else
			gungame_gun = guns[(ply:Frags()%#guns)+1] -- +1 bc lua tables indices begin at 1
		end
		if gungame_gun == nil then
			return 0
		end
		
		timer.Simple(0.2, function()
			ply:StripWeapons()
			ply:Give(gungame_gun)
			ply:SelectWeapon(gungame_gun)
			_give_current_ammo(ply, 3)
		end)
		if gungame_gun == "weapon_ttt_homebat" then
			ply:SetWalkSpeed(INCREASED_SPEED)
		end
	end

	local function get_guns_table()
		local t = {
			"awpv2",
			"fast_frag",
			"barrel_wand",
			"melonlauncher",
			"ttt_thomas_swep",
			"ttt_weapon_eagleflightgun",
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
		for i, gun_name in RandomPairs(t) do
			table.insert(rand_t, gun_name)
		end
		return rand_t
	end
	
	function gungame_on(kills_to_win)
		-- setup
		_drop_hooks()
		someone_already_won = false
		guns = get_guns_table()
		for i, ply in ipairs(player.GetAll()) do
			ply:SetFrags(0)
		end
		RunConsoleCommand("ttt_roundtime_minutes", GUN_GAME_ROUND_LEN)
		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "2")
		RunConsoleCommand("ulx", "roundrestart")
		
		-- HOOKS
		-- assign innocent role to every player
		_add_hook("TTTBeginRound", "gg_ForceRole", function()
			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
			end
		end)

		-- on respawn: equip current gun game weapon
		_add_hook("PlayerSpawn", "gg_spawn", function(ply, transition)
			ply:SetRole(0)
			update_weapon(ply, guns, kills_to_win)
		end)

		-- on pre-kill: victim does not drop weapon, player moves onto next weapon or wins
		_add_hook("DoPlayerDeath", "gg_advancement", function(victim, attacker, dmgInfo)
			if victim:GetActiveWeapon():IsValid() then
				victim:GetActiveWeapon():Remove()
			end
			if attacker:IsPlayer() and attacker ~= victim then
				attacker:AddFrags(1)
				if dmgInfo:GetInflictor():IsWeapon() and dmgInfo:GetInflictor():GetPrintName() == "weapon_zm_improvised" then
					if !someone_already_won then
						someone_already_won = true
						PrintMessage(HUD_PRINTCENTER, attacker:GetName().." wins!")
						PrintMessage(HUD_PRINTTALK, attacker:GetName().." wins!")
						_highlight_kill(victim, attacker, 0.2, 5)
					end
				else
					update_weapon(attacker, guns, kills_to_win)
				end
			end
		end)

		-- on kill: play headshot effect, print killfeed, begin respawn
		_add_hook("PlayerDeath", "gg_PlayerDeath", function(victim, inflictor, attacker)
			if (attacker:IsPlayer()) then
				if victim:LastHitGroup() == 1 then
					_headshot_effect(victim)
				end
			end
			_print_kill(victim, attacker)
			_respawn(victim, RESPAWN_DELAY) 
		end)
	end
	
end