print("Executed lua: " .. debug.getinfo(1,'S').source)




if CLIENT then
	concommand.Add("quick_grenade", function()
		LocalPlayer():EmitSound("WeaponFrag.Throw", 75, 100, 0.8, CHAN_BODY)
		-- Send command to server
		net.Start("QuickGrenadeThrow")
		net.SendToServer()
	end)
	-- play throw sound effect
end


if SERVER then

	local grenade_classes = {
		["weapon_ttt_smokegrenade"] = true,
		["weapon_zm_molotov"] = true,
		["weapon_ttt_confgrenade"] = true,
		["weapon_ttt_frag"] = true
	}

	local function quick_throw_grenade(ply)
		if not IsValid(ply) or not ply:Alive() then return end
		
		local current_weapon = ply:GetActiveWeapon()
		if not IsValid(current_weapon) then return end
		
		-- Find a grenade in inventory
		local grenade = nil
		-- check active weapon first
		if grenade_classes[current_weapon:GetClass()] then
			grenade = current_weapon
		else
			for _, wep in ipairs(ply:GetWeapons()) do
				if grenade_classes[wep:GetClass()] then
					grenade = wep
					break
				end
			end
		end
		
		-- If we found a grenade, switch to it and use it
		if grenade then
			-- Switch to grenade using PlayerSelectWeapon
			grenade:SetDeploySpeed(9)
			ply:SelectWeapon(grenade:GetClass())
			grenade:SetNextPrimaryFire(0)
			grenade:SetNextSecondaryFire(0)
			if grenade:GetClass() == "weapon_ttt_smokegrenade" then
				grenade.detonate_timer = 1
			end
			-- Make sure the grenade is ready instantly
			timer.Simple(0.05, function()
				if IsValid(ply) and ply:Alive() and IsValid(grenade) then
					ply:ConCommand("+attack")
					timer.Simple(0.05, function()
						if IsValid(ply) and ply:Alive() then
							ply:ConCommand("-attack")
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
	

end