-- GUN GAME
-- addon by 

-- display game mode at top of screen
if SERVER then
	util.AddNetworkString("gg_power_message")

	function gg_show_game_mode(status)
		net.Start("gg_power_message")
			net.WriteInt(status, 32)
		net.Broadcast()
	end

elseif CLIENT then
	local function gg_show_game_mode(status)
	
		if status == 1 then
			-- prepare text to display
			local text = "GUN GAME"
			local font = "TargetID"
			local textColor = Color(255, 255, 255, 255) -- White color

			surface.SetFont(font)
			local textWidth, textHeight = surface.GetTextSize(text)
			local x = ScrW() / 2 - textWidth / 2
			local y = 50 -- Adjust this value to move the text up or down

			-- prepare box
			local boxWidth = textWidth + 11
			local boxHeight = textHeight + 10
			local boxX = x - 5
			local boxY = y - 5

			-- display prepared UI elements
			hook.Add("HUDPaint", "gg_print_game_mode", function()
				draw.RoundedBox(0, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
				draw.SimpleText(text, font, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end)

		elseif status == 0 then
			hook.Remove("HUDPaint", "gg_print_game_mode")

		else
			print("show_game_mode: invalid argument, must be 0 or 1")

		end
	end

	net.Receive("gg_power_message", function()
		local status = net.ReadInt(32)
		gg_show_game_mode(status)
	end)
end


--gun_game
if SERVER then

	--mode_gg
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- declare variables in scope shared between gg on/off functions
	local orig_preptime = nil
	local orig_roundtime = nil

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

    local camera_model = Model( "models/dav0r/camera.mdl" )
    local function highlight_kill(ply, slo_scale, duration)
        local camera = ents.Create("prop_dynamic")
        if not IsValid(camera) then return end

        camera:SetModel(camera_model) 
        camera:SetPos(ply:GetShootPos() + ply:GetAimVector()*200) -- Set position
        camera:SetAngles((-ply:GetAimVector()):Angle()) -- Set angles
        camera:SetSolid(SOLID_NONE)
        camera:SetMoveType(MOVETYPE_NONE)
        camera:SetRenderMode(RENDERMODE_NONE)
        camera:Spawn() -- Spawn the entity

        --camera:SetParent(ply:GetActiveWeapon()) -- causes other players to not be rendered sometimes (not sure why)

        -- update time scale and player views
        game.SetTimeScale(slo_scale)
        for i,ply in ipairs(player.GetAll()) do
            ply:SetViewEntity(camera)
            ply:CrosshairDisable()
        end

		ply:DoAttackEvent()

        -- cleanup
        timer.Simple(duration * slo_scale, function() 
            game.SetTimeScale(1)
            for i,ply in ipairs(player.GetAll()) do
                ply:SetViewEntity(ply)
                ply:CrosshairEnable()
            end
            camera:Remove() 
        end)

    end

	local function get_guns_table(kills_to_win)
		local weapon_options = {
			"awpv2",
			"barrel_wand",
			"melonlauncher",
			"ttt_thomas_swep",
			"weapon_banana",
			"weapon_minigun",
			"weapon_sp_winchester",
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
			if #rand_t >= kills_to_win then break end
		end

		-- replace final weapon with crowbar
		table.remove(rand_t, #rand_t)
		table.insert(rand_t, "weapon_zm_improvised")

		return rand_t
	end

	local function update_weapon(ply, guns)
		ply:SetFOV(0, 0.15) -- adjust FOV to default over 0.15 seconds
		
		local on_gun_id = math.min(ply:Frags() + 1, #guns) -- +1 because lua table indices begin at 1
		local gungame_gun = guns[on_gun_id]
		
		ply:StripWeapons()
		ply:Give("weapon_ttt_unarmed")
		ply:Give(gungame_gun)
		timer.Simple(0.2, function()
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
		local guns = get_guns_table(kills_to_win)
		local someone_already_won = false

		-- allow players to respawn themselves by chatting
		hook.Add("PlayerSay", "gg_chat_to_spawn", function(sender, text, teamChat)
			RunConsoleCommand("ulx", "respawn", sender:Name()) 
		end)

		-- reset score, remove all weapons from map
		hook.Add("TTTPrepareRound", "gg_TTTPrepareRound ", function()	
			-- reset		
			guns = get_guns_table(kills_to_win) -- get new gun order
			someone_already_won = false
			for i,ply in ipairs(player.GetAll()) do
				ply:SetFrags(0)
			end

			-- remove all weapons that spawned on map
			for id, ent in ipairs(ents.GetAll()) do
				if ent:IsWeapon() and !ent:GetOwner():IsPlayer() then
					ent:Remove()
				end
			end
			
		end)

		hook.Add("TTTBeginRound", "gg_TTTBeginRound", function()
			PrintMessage(HUD_PRINTTALK, "GUN GAME")
			for i,ply in ipairs(player.GetAll()) do
				ply:SetRole(0)
				ply:SetFrags(0)
			end
		end)

		-- on loadout: set role, gain and equip weapons
		hook.Add("PlayerLoadout", "gg_PlayerLoadout", function(ply)

			-- set role to innocent
			ply:SetRole(0)

			-- give weapon
			update_weapon(ply, guns)
			ply:Give("weapon_ttt_unarmed")
			
			-- override default loadout
			return true 
			
		end)

		-- on pre-kill: remove weapons so they are not dropped and clutter the map
		hook.Add("DoPlayerDeath", "gg_no_weapon_drop", function(victim, attacker, dmgInfo)
			if IsValid(victim) then
				victim:StripWeapons()
			end
		end)

		hook.Add("PlayerDeath", "gg_PlayerDeath_advancement", function(victim, inflictor, attacker)
			if !attacker:IsPlayer() then return end
			if victim == attacker then return end

			attacker:AddFrags(1)
			if attacker:Frags() >= kills_to_win then
				if inflictor:GetClass() == "weapon_zm_improvised" and !someone_already_won then
					someone_already_won = true
					PrintMessage(HUD_PRINTCENTER, attacker:Nick().." wins!")
					PrintMessage(HUD_PRINTTALK, attacker:Nick().." wins!")
					highlight_kill(attacker, 0.3, 5)
				end
			else
				update_weapon(attacker, guns)
			end
		end)

		-- on kill: print killfeed, prepare respawn
		hook.Add("PlayerDeath", "gg_PlayerDeath_respawn", function(victim, inflictor, attacker)
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
				if IsValid(victim) then
					RunConsoleCommand("ulx", "respawn", victim:Nick())
				end
			end)
		end)

		--orig_roundtime = GetConVar("ttt_roundtime_minutes"):GetString()
		--orig_preptime = GetConVar("ttt_preptime_seconds"):GetString()

		RunConsoleCommand("ttt_roundtime_minutes", "60")
		RunConsoleCommand("ttt_preptime_seconds", "1")

		gg_show_game_mode(1)
		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ulx", "roundrestart")

	end

	function gungame_off()

		-- remove hooks
		hook.Remove("PlayerSay", "gg_chat_to_spawn")
		hook.Remove("TTTPrepareRound", "gg_TTTPrepareRound")
		hook.Remove("TTTBeginRound", "gg_TTTBeginRound")
		hook.Remove("PlayerLoadout", "gg_PlayerLoadout")
		hook.Remove("DoPlayerDeath", "gg_no_weapon_drop")
		hook.Remove("PlayerDeath", "gg_PlayerDeath_advancement")
		hook.Remove("PlayerDeath", "gg_PlayerDeath_respawn")

		RunConsoleCommand("ttt_roundtime_minutes", "8")
		RunConsoleCommand("ttt_preptime_seconds", "25")
		
		gg_show_game_mode(0)
		RunConsoleCommand("ttt_debug_preventwin", "0")
		RunConsoleCommand("ulx", "roundrestart")
	end
	
end