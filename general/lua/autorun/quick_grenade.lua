print("Executed lua: " .. debug.getinfo(1,'S').source)



-- Store previous weapons for each player
local player_previous_weapons = {}

if CLIENT then
	concommand.Add("quick_grenade", function()
		-- Send command to server
		net.Start("QuickGrenadeThrow")
		net.SendToServer()
	end)
end


if SERVER then

	local nade_quick_cook_times = {
		["weapon_ttt_smokegrenade"] = 1,
		["weapon_zm_molotov"] = 2,
		["weapon_ttt_confgrenade"] = 3,
		["weapon_ttt_frag"] = 5
	}

	local function quick_throw_grenade(ply)
		if not IsValid(ply) or not ply:Alive() then return end
		
		local current_weapon = ply:GetActiveWeapon()
		if not IsValid(current_weapon) then return end
		
		-- Store current weapon for switching back later
		player_previous_weapons[ply:SteamID()] = current_weapon:GetClass()
		
		-- Find a grenade in inventory
		local grenade = nil
		for _, wep in ipairs(ply:GetWeapons()) do
			if nade_quick_cook_times[wep:GetClass()] then
				grenade = wep
				break
			end
		end
		
		-- If we found a grenade, switch to it and use it
		if grenade then
			-- Switch to grenade using PlayerSelectWeapon
			grenade:SetDeploySpeed(9)
			ply:SelectWeapon(grenade:GetClass())
			grenade:SetNextPrimaryFire(0)
			grenade:SetNextSecondaryFire(0)
			grenade.detonate_timer = nade_quick_cook_times[grenade:GetClass()]
			-- Make sure the grenade is ready instantly
			timer.Simple(0.05, function()
				if IsValid(ply) and ply:Alive() and IsValid(grenade) then
					ply:ConCommand("+attack")
					timer.Simple(0.05, function()
						if IsValid(ply) and ply:Alive() then
							ply:ConCommand("-attack")
							-- -- Switch back to previous weapon
							-- timer.Simple(0.8, function()
							-- 	if IsValid(ply) and ply:Alive() then
							-- 		local prev_wep_class = player_previous_weapons[ply:SteamID()]
							-- 		if prev_wep_class then
							-- 			ply:SelectWeapon(prev_wep_class)
							-- 			-- Clear the stored weapon
							-- 			player_previous_weapons[ply:SteamID()] = nil
							-- 		end
							-- 	end
							-- end)
						end
					end)
				end
			end)
		end
	end

	-- Create network string
	util.AddNetworkString("QuickGrenadeThrow")
	
	-- Handle the grenade throw request from client
	net.Receive("QuickGrenadeThrow", function(len, ply)
		quick_throw_grenade(ply)
	end)

	concommand.Add("quick_grenade", function(ply, cmd, args)
		quick_throw_grenade(ply)
	end)
	
	-- Clean up when player disconnects
	hook.Add("PlayerDisconnected", "CleanupQuickGrenadeData", function(ply)
		if player_previous_weapons[ply:SteamID()] then
			player_previous_weapons[ply:SteamID()] = nil
		end
	end)


end