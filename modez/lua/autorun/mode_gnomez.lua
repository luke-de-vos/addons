-- display game mode at top of screen
if SERVER then
	util.AddNetworkString("gnomez_power_message")

	function gnomez_show_game_mode(status)
		net.Start("gnomez_power_message")
			net.WriteInt(status, 32)
		net.Broadcast()
	end

elseif CLIENT then
	local function gnomez_show_game_mode(status)
	
		if status == 1 then
			-- prepare text to display
			local text = "Gnomez"
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
			hook.Add("HUDPaint", "gnomez_print_game_mode", function()
				draw.RoundedBox(0, boxX, boxY, boxWidth, boxHeight, Color(0, 0, 0, 200))
				draw.SimpleText(text, font, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end)

		elseif status == 0 then
			hook.Remove("HUDPaint", "gnomez_print_game_mode")

		else
			print("show_game_mode: invalid argument, must be 0 or 1")

		end
	end

	net.Receive("gnomez_power_message", function()
		local status = net.ReadInt(32)
		gnomez_show_game_mode(status)
	end)
end


-- gnome game mode
if SERVER then

	-- spawn barrel func
	-- Function to spawn a barrel
	local function spawn_gnome_spawner(pos)
		local spawner = ents.Create("prop_physics") -- Creating a physics prop

		if not IsValid(spawner) then return end

		-- set model to something related to gnomes
		spawner:SetModel("models/props_junk/wood_crate001a.mdl")
		spawner:SetPos(pos) -- Set position
		spawner:Spawn() -- Spawn the entity

		local phys = spawner:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake() -- Wake up the physics object so it reacts to the world
		end

		-- set the spawner to a collision group so that it does not collide with players
		spawner:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		-- make box heavy
		phys:SetMass(40)

		return spawner
	end

	local scapers = {}
	local start_time = 0

	function is_gnome(ply)
		if scapers[ply:Nick()] != nil then
			return false
		else
			return true
		end
	end

	function slow_mo()
		-- temporarily slow down time
		game.SetTimeScale(0.2)
		timer.Simple(4 * 0.2, function()
			game.SetTimeScale(1)
		end)
	end

	concommand.Add("gnomez", function(ply, cmd, args)

		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end 
		local mode = args[1]

		if mode == "on" then

			start_time = CurTime()

			RunConsoleCommand("sv_playermodel_selector_force", "0")

			-- set landscapers
			local random_no = math.random(1, #player.GetAll()-1)
			print(random_no)
			scapers = {}
			scapers[Entity(random_no):Nick()] = true
			scapers[Entity(random_no+1):Nick()] = true

			-- on round start, set roles
			hook.Add("TTTBeginRound", "gnomez_TTTBeginRound", function()
				for _, ent in ipairs(ents.GetAll()) do
					if ent:IsWeapon() or string.sub(ent:GetClass(), 1, 5) == "item_" then
						ent:Remove()
					end
				end
				local gnomes = {}
				timer.Simple(0.5, function()
					for i,ply in ipairs(player.GetAll()) do
						if is_gnome(ply) then
							RunConsoleCommand("ulx", "force", ply:Nick(), "gnome")
							SendColouredChat1(ply, "Landscapers are destroying your home. Eliminate them!", Color(255, 0, 0, 255))
							-- add ent index to table of gnomes
							table.insert(gnomes, ply:EntIndex())
						else
							RunConsoleCommand("ulx", "force", ply:Nick(), "landscaper")
							SendColouredChat1(ply, "The gnomes are back. And they're pissed.", Color(255, 0, 0, 255))
						end
					end

					-- spawn gnome spawner at farthest gnome
					local farthest_gnome = get_farthest_gnome()
					local spawn_pos = farthest_gnome:GetPos()
					gnome_spawner = spawn_gnome_spawner(spawn_pos + Vector(0, 0, 15))
					if IsValid(gnome_spawner) then
						gnome_spawner:SetVar("igs", true)
						gnome_spawner:SetVar("igs_canspawn", true)
					end
					
					-- teleport all players to gnome spawner
					for i,ply in ipairs(player.GetAll()) do
						if is_gnome(ply) then
							timer.Simple(0.1*i, function()
								spawn_at_spawner(ply)
							end)
						end
					end

				end)
			end)

			-- Hook into EntityTakeDamage
			hook.Add("EntityTakeDamage", "gnomez_spawner_damage_control", function(target, dmginfo)
				if IsValid(target) and target:GetVar("igs") then

					-- if the damage isn't from weapon_zm_improvised, then cancel the damage
					if dmginfo:GetInflictor():GetClass() != "weapon_zm_improvised" then
						dmginfo:SetDamage(0)
					end

					target:SetVar("igs_canspawn", false)
					spawner:SetColor(Color(255, 0, 0, 255))
					timer.Simple(5, function()
						if not IsValid(target) then return end
						target:SetVar("igs_canspawn", true)
						spawner:SetColor(Color(0, 0, 0, 0))
					end)
				end

			end)

			-- if a landscaper dies and no landscapers remain, gnomes win
			hook.Add("PlayerDeath", "gnomez_gnome_win_condition", function(victim, inflictor, attacker)
				if not is_gnome(victim) then
					local landscapers_alive = false
					for i,ply in ipairs(player.GetAll()) do
						if not is_gnome(ply) and ply:Alive() then
							landscapers_alive = true
							break
						end
					end
					if not landscapers_alive then
						local time_survived = math.floor(CurTime() - start_time)
						PrintMessage(HUD_PRINTTALK, "The gnomes have won!")
						PrintMessage(HUD_PRINTTALK, "Landscapers survived for "..time_survived.." seconds.")
						slow_mo()
					end
				else
					-- if a gnome dies, check if any gnomes remain
					if IsValid(gnome_spawner) then return end
					local gnomes_alive = false
					for i,ply in ipairs(player.GetAll()) do
						if is_gnome(ply) and ply:Alive() then
							gnomes_alive = true
							break
						end
					end
					if not gnomes_alive then
						local time_survived = math.floor(CurTime() - start_time)
						PrintMessage(HUD_PRINTTALK, "The landscapers have won!")
						PrintMessage(HUD_PRINTTALK, "Gnomes survived for "..time_survived.." seconds.")
						slow_mo()
					end
				end
			end)

			function spawn_at_spawner(ply)
				if IsValid(gnome_spawner) then
					ply:SetPos(gnome_spawner:GetPos()) -- box pos is in center of model
					ply:EmitSound("Weapon_357.Spin")
				else
					print("gnome spawner is not valid")
				end
			end

			-- when a player dies, respawn them if they are a gnome
			hook.Add("PlayerDeath", "gnomez_respawn_gnomes", function(victim, inflictor, attacker)
				if is_gnome(victim) then
					timer.Simple(2, function()
						if not IsValid(victim) then return end
						if not IsValid(gnome_spawner) then return end
						RunConsoleCommand("ulx", "respawn", victim:Nick())
						timer.Simple(0.1, function()
							spawn_at_spawner(victim)
						end)
					end)
				end
			end)

			-- set gnome spawn pos to barrel
			hook.Add("PlayerSelectSpawn", "gnome_spawner_pos", function(ply, transition)
				if transition then return end
				if is_gnome(ply) then
					print('spawning gnome at barrel')
					return gnome_spawner
				end
			end)
			hook.Remove("PlayerSelectSpawn", "gnome_spawner_pos")

			-- on pre-kill: remove weapons so they are not dropped and clutter the map
			hook.Add("DoPlayerDeath", "gnomez_DoPlayerDeath", function(ply, attacker, dmg)
				if is_gnome(ply) then
					-- for each of ply's weapons, 
					for _, weapon in ipairs(ply:GetWeapons()) do
						-- remove the weapon
						if weapon:GetClass() != "weapon_zm_shotgun" then
							ply:StripWeapon(weapon:GetClass())
						end
					end
				end
			end)

			-- on kill: award frag, print killfeed
			hook.Add("PlayerDeath", "gnomez_PlayerDeath", function(victim, inflictor, attacker)
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
			end)


			-- prevent gnomes from damaging other gnoems
			hook.Add("EntityTakeDamage", "gnomez_no_gnome_damage", function(target, dmginfo)
				if not IsValid(target) or not IsValid(dmginfo:GetAttacker()) then return end
				print(dmginfo:GetAttacker())
				if is_gnome(target) and is_gnome(dmginfo:GetAttacker()) then
					dmginfo:SetDamage(0)

				end
			end)


			RunConsoleCommand("ttt_preptime_seconds", "1")
			RunConsoleCommand("ttt_roundtime_minutes", "60")

			gnomez_show_game_mode(1)
			RunConsoleCommand("ttt_debug_preventwin", "1")
			RunConsoleCommand("ulx", "roundrestart")

		elseif mode == "off" then

			RunConsoleCommand("sv_playermodel_selector_force", "1")

			-- remove hooks
			hook.Remove("TTTBeginRound", "gnomez_TTTBeginRound")
			hook.Remove("EntityTakeDamage", "gnomez_spawner_damage_control")
			hook.Remove("PlayerDeath", "gnomez_gnome_win_condition")
			hook.Remove("PlayerDeath", "gnomez_respawn_gnomes")
			hook.Remove("PlayerSelectSpawn", "gnome_spawner_pos")
			hook.Remove("DoPlayerDeath", "gnomez_DoPlayerDeath")
			hook.Remove("PlayerDeath", "gnomez_PlayerDeath")
			hook.Remove("EntityTakeDamage", "gnomez_no_gnome_damage")

			scapers = {}

			RunConsoleCommand("ttt_preptime_seconds", "25")
			RunConsoleCommand("ttt_roundtime_minutes", "8")

			gnomez_show_game_mode(0)
			RunConsoleCommand("ttt_debug_preventwin", "0")
			RunConsoleCommand("ulx", "roundrestart")

		else
			print("invalid mode")
		end

	end)

end




if SERVER then

	-- Function to find the farthest gnome from any landscaper
	function get_farthest_gnome()
		local allPlayers = player.GetAll()
		local gnomes = {}
		local landscapers = {}

		-- Separate players into gnomes and landscapers
		for _, ply in ipairs(allPlayers) do
			if not IsValid(ply) then continue end
			if not ply:Alive() then continue end

			if is_gnome(ply) then
				table.insert(gnomes, ply)
			else
				table.insert(landscapers, ply)
			end

		end

		if #gnomes == 0 || #landscapers == 0 then
			return nil, -1
		end

		local farthestGnome = nil
		local maxDistance = -1

		-- Iterate through each gnome
		for _, gnome in ipairs(gnomes) do
			local gnomePos = gnome:GetPos()
			local closestDistance = math.huge

			-- Find the closest landscaper to this gnome
			for _, landscaper in ipairs(landscapers) do
				local distance = gnomePos:Distance(landscaper:GetPos())
				closestDistance = math.min(closestDistance, distance)
			end

			-- Check if this gnome is the farthest from any landscaper
			if closestDistance > maxDistance then
				farthestGnome = gnome
				maxDistance = closestDistance
			end
		end

		return farthestGnome
	end

end