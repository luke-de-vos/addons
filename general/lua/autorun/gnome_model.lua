print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then
	-- set entity(1) playermodel to gnome
	local gnome_model = "models/splinks/gnome_chompski/player_gnome.mdl"
	concommand.Add("set_gnome", function(ply, cmd, args)
		local ent = ply
		if not IsValid(ent) then return end
		ent:SetModel(gnome_model)
	end)
	-- remove this concommand
	--concommand.Remove("set_gnome")
end