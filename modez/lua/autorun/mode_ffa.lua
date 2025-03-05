-- display game mode at top of screen
if SERVER then
	util.AddNetworkString("ffa_power_message")

	function ffa_show_game_mode(status)
		net.Start("ffa_power_message")
			net.WriteInt(status, 32)
		net.Broadcast()
	end

elseif CLIENT then
	local function ffa_show_game_mode(status)
	
		if status == 1 then
			-- prepare text to display
			local text = "FFA"
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
			hook.Add("HUDPaint", "ffa_print_game_mode", function()
				draw.RoundedBox(0, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
				draw.SimpleText(text, font, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end)

		elseif status == 0 then
			hook.Remove("HUDPaint", "ffa_print_game_mode")

		else
			print("show_game_mode: invalid argument, must be 0 or 1")

		end
	end

	net.Receive("ffa_power_message", function()
		local status = net.ReadInt(32)
		ffa_show_game_mode(status)
	end)
end

if SERVER then

	--mode_ffa
	print("Executed lua: " .. debug.getinfo(1,'S').source)

	-- config
	local RESPAWN_DELAY = 2 -- seconds

	-- declare variables in scope shared between ffa on/off functions
	local orig_preptime = nil
	local orig_roundtime = nil
	
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
			req_weapon = "weapon_zm_mac10"
			return
		end

		-- allow players to respawn themselves by chatting
		hook.Add("PlayerSay", "ffa_chat_to_spawn", function(sender, text, teamChat)
			RunConsoleCommand("ulx", "respawn", sender:Name()) 
		end)

		-- assign gamer role to every player
		hook.Add("TTTBeginRound", "ffa_ForceRole", function()
			for i,ply in ipairs(player.GetAll()) do
				if ply:GetRoleString() != "gamer" then	
					RunConsoleCommand("ulx", "force", ply:Nick(), "gamer")
				end
				ply:SetFrags(0)
			end
		end)

		-- on spawn: reset kill trackers, gain and equip weapons
		hook.Add("PlayerLoadout", "ffa_PlayerLoadout", function(ply)

			-- set role to gamer
			if ply:GetRoleString() != "gamer" then
				RunConsoleCommand("ulx", "force", ply:Nick(), "gamer")
			end

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
			ply:StripWeapons()
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
				if IsValid(victim) then
					RunConsoleCommand("ulx", "respawn", victim:Nick())
				else
					print("ffa_PlayerDeath() failed: victim invalid or alive.")
				end
			end)

		end)

		-- -- record original values of cvars
		-- orig_preptime = GetConVar("ttt_preptime_seconds"):GetString()
		-- orig_roundtime = GetConVar("ttt_roundtime_minutes"):GetString()

		RunConsoleCommand("ttt_debug_preventwin", "1")
		RunConsoleCommand("ttt_preptime_seconds", "1")
		RunConsoleCommand("ttt_roundtime_minutes", "60")

		ffa_show_game_mode(1)
		RunConsoleCommand("ulx", "roundrestart")
		
	end

	-- undo ffa_on()
	function ffa_off()

		-- remove hooks
		hook.Remove("PlayerSay", "ffa_chat_to_spawn")
		hook.Remove("TTTBeginRound", "ffa_ForceRole")
		hook.Remove("PlayerLoadout", "ffa_PlayerLoadout")
		hook.Remove("DoPlayerDeath", "ffa_DoPlayerDeath")
		hook.Remove("PlayerDeath", "ffa_PlayerDeath")

		-- RunConsoleCommand("ttt_preptime_seconds", orig_preptime)
		-- RunConsoleCommand("ttt_roundtime_minutes", orig_roundtime)
		RunConsoleCommand("ttt_preptime_seconds", "25")
		RunConsoleCommand("ttt_roundtime_minutes", "8")

		ffa_show_game_mode(0)
		RunConsoleCommand("ttt_debug_preventwin", "0")
		RunConsoleCommand("ulx", "roundrestart")
	end
end


