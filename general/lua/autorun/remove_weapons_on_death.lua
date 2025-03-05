print("Executed lua: " .. debug.getinfo(1,'S').source)

-- on DoPlayerDeath, remove magneto stick and crowbar from player
if SERVER then
	hook.Add("DoPlayerDeath", "RemoveMagnetoStickAndCrowbar", function(victim, attacker, dmginfo)
		victim:StripWeapon("weapon_zm_improvised")
		victim:StripWeapon("weapon_zm_carry")
	end)
end