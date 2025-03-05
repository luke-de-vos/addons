print("Executed lua: " .. debug.getinfo(1,'S').source)

-- head size changer
if SERVER then
	concommand.Add("scale_head", function( ply, cmd, args )
		if !IsValid(ply) then return end
		-- player can only increase head size
		if tonumber(args[1]) < 1 then return end
		
		local boneID = ply:LookupBone("ValveBiped.Bip01_Head1")
		local scale = tonumber(args[1])
		ply:ManipulateBoneScale(boneID, Vector(1,1,1) * scale)
	end)
end