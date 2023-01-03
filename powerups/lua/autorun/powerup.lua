

if SERVER then	

	hook.Add("PlayerSay", "custom_commands_powerups", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!pups" then pups_on() end
		end
	end)

	function pups_on()
		_add_hook('TTTBeginRound', "spawn_pups", function()
			for i,ammo_ent in ipairs(ents.FindByClass("item_ammo_smg1*")) do
				local ent = ents.Create("ent1")
				if not IsValid(ent) then return end
				ent.SpawnPoint = ammo_ent:GetPos() + Vector(0,0,30)
				ent:SetPos(ent.SpawnPoint)
				ent:Spawn()
			end
		end)
	end

end
