print("Executed lua: " .. debug.getinfo(1,'S').source)

-- arm damage
if SERVER then
	hook.Add("ScalePlayerDamage", "arm_damage3", function(ply, hitgroup, dmginfo) 
		if (hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM) then
			dmginfo:ScaleDamage(1.845) -- set arm damage equal to body damage
		 end
	end)
end