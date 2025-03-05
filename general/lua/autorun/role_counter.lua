print("Executed lua: " .. debug.getinfo(1,'S').source)

-- when the round starts, print roles
if SERVER then
    -- UTILITY
    function _get_roles()
        local role_counts = {0,0,0,0}
        local role_index = nil
        for i,ply in ipairs(player.GetAll()) do
            role_index = ply:GetRole() + 1
            if role_index > 4 then
                role_index = 4
            end
            role_counts[role_index] = role_counts[role_index] + 1
        end
        local role_names = {'inno','traitor','detective', 'misc'}
        for role_index, count in ipairs(role_counts) do
            print(role_names[role_index]..': '..count)
        end
    end
	hook.Add("TTTBeginRound", "print_roles", function()
		_get_roles()
	end)
	
	-- print the number of players with each role at the start of each round
	hook.Add("TTTBeginRound", "PrintPlayerRoles", function()
		print("======")
		print("ROLES")
		local roleCounts = {}  -- Table to hold the count of each role

		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) then
				local role = ply:GetRoleString()  -- Assuming GetRoleString gets the role name as a string
				roleCounts[role] = (roleCounts[role] or 0) + 1  -- Increment the count for this role
			end
		end

		-- Print the count of each role
		for role, count in pairs(roleCounts) do
			print(count.." "..role)
		end
		print("======")
	end)
end