print("Executed lua: " .. debug.getinfo(1,'S').source)

-- cleanup command
hook.Add("PlayerSay", "custom_command_remove_ents", function(sender, text, teamChat)
	if sender:GetUserGroup() ~= "user" then
		if text == "!cleanup" then
			for i,ent in ipairs(ents.GetAll()) do
				local cla = ent:GetClass()
				if cla == "prop_physics" or cla == "prop_dynamic" then
					ent:Remove()
				elseif ent:IsWeapon() and !ent:GetOwner():IsValid() then
					ent:Remove()
				end
			end
		end
	end
end)