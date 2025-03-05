print("Executed lua: " .. debug.getinfo(1,'S').source)

-- hitmarker sound
if SERVER then
    resource.AddFile("sound/hit.wav")
    util.AddNetworkString("zz_hitmarker_sound_msg")
    hook.Add("EntityTakeDamage", "zz_hitmarker_sound", function(vic, dmg)
        if vic:IsPlayer() and dmg:GetAttacker():IsPlayer() then
            if dmg:GetDamage() >= 1 then -- this doesn't work
                net.Start("zz_hitmarker_sound_msg")
                net.Send(dmg:GetAttacker())
            end
        end
    end)
end
if CLIENT then
    net.Receive("zz_hitmarker_sound_msg", function()
		surface.PlaySound("hit.wav")
	end)
end