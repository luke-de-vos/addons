if SERVER then
   AddCSLuaFile()
end
ENT.Type = "anim"

ENT.PrintName = "Coin Pickup"
ENT.Spawnable = true
--ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SpawnPoint = nil

if SERVER then
   _add_hook("DoPlayerDeath", "powerup_shared_death", function(victim, attacker, dmg)
      print('x')
      if victim:GetActiveWeapon():GetClass() == "barrel_wand" then  
         print('y')
         if victim:GetActiveWeapon().HasBlock then
            print('z')
            local ent = ents.Create("ent1")
            if not IsValid(ent) then return end
            ent:SetPos(victim:GetPos()+Vector(0,0,30))
            ent:Spawn()
         end
      end   
   end)  
end