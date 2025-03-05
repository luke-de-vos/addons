print("Executed lua: " .. debug.getinfo(1,'S').source)


if SERVER then
	-- create network message for receiving command to give a weapon
	util.AddNetworkString("doug_give_weapon")
	net.Receive("doug_give_weapon", function(len, ply)
		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end
		local weapon_class = net.ReadString()
		ply:Give(weapon_class)
		print("doug_give_weapon "..ply:GetName().." "..weapon_class)
	end)

	-- add command to spawn Entity(2) at Entity(1)'s aimvector hitpos
	concommand.Add("spawnat", function(ply, cmd, args)
		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end 
		local ent_id = args[1]
		local ent = Entity(ent_id)
		ent:EmitSound("WeaponFrag.Roll", 50, 120, 0.7, CHAN_AUTO)
		ent:SetPos(ply:GetEyeTrace().HitPos)
		ent:EmitSound("WeaponFrag.Roll", 50, 120, 0.7, CHAN_AUTO)
		-- play spark effect at original pos and hit pos
		local effectdata = EffectData()
		effectdata:SetOrigin(ent:GetPos())
		effectdata:SetStart(ent:GetPos())
		util.Effect("ElectricSparks", effectdata)
		effectdata:SetOrigin(ent:GetEyeTrace().HitPos)
		effectdata:SetStart(ent:GetEyeTrace().HitPos)
		util.Effect("ElectricSparks", effectdata)
	end)
end

-- GIVE ME COMMAND
if CLIENT then
	-- Function to get all available weapons in the game
	local function GetAllWeapons()
		local these_weapons = {}
		for _, weapon in pairs(weapons.GetList()) do
			if weapon and weapon.ClassName then
				table.insert(these_weapons, weapon.ClassName)
			end
		end
		return these_weapons
	end
	
	-- Function to find matching weapon names for autocomplete
	local function matchingWeaponNames(input)
		local matches = {}
		local all_weapons = GetAllWeapons()
		
		input = input:Trim():lower()
		
		for _, weaponClass in ipairs(all_weapons) do
			if weaponClass:lower():find(input) then
				table.insert(matches, weaponClass)
			end
		end
		
		return matches
	end
	
	-- Function that handles autocomplete
	local function givemeAutoComplete(command, args)
		args = args:Trim():lower()
		
		local suggestions = {}
		local matches = matchingWeaponNames(args)
		
		for _, weaponClass in ipairs(matches) do
			local suggestion = command .. " " .. weaponClass
			table.insert(suggestions, suggestion)
		end
		
		return suggestions
	end
	
	-- Main command function
	local function givemeCommand(ply, cmd, args)
		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end 
		local weapon_class = args[1]
		net.Start("doug_give_weapon")
		net.WriteString(weapon_class)
		net.SendToServer()
	end
	
	-- Register the command with autocomplete
	concommand.Add("giveme", givemeCommand, givemeAutoComplete)
	

end