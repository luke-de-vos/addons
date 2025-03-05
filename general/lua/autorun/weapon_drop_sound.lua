print("Executed lua: " .. debug.getinfo(1,'S').source)

-- DROP WEAPON SOUND EFFECT
if SERVER then
	hook.Add("PlayerDroppedWeapon", "sfx_drop_hook", function(owner, wep)
		owner:EmitSound("WeaponFrag.Roll", 20, 100, 0.7, CHAN_AUTO)
	end)
end