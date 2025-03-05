print("Executed lua: " .. debug.getinfo(1,'S').source)

-- SFX FOR KNIFE KILLS
if SERVER then
	local knife_stab_sound = Sound("physics/flesh/flesh_strider_impact_bullet1.wav")
    hook.Add("DoPlayerDeath", "SoundForKnifeKill", function(victim, attacker, dmginfo)
		local inflictor = dmginfo:GetInflictor()
		if IsValid(inflictor) then
			if inflictor.ClassName == "weapon_ttt_knife" or inflictor.ClassName == "ttt_knife_proj" then
				victim:EmitSound(knife_stab_sound, 62, 120, 1)
			end
		end
    end)
end