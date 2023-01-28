if SERVER then
   AddCSLuaFile()
end
ENT.Type = "anim"

ENT.PrintName = "Oddblock"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SpawnPoint = nil

if SERVER then
   function ENT:StartTouch(other_ent)
      if other_ent:IsPlayer() then
         RunConsoleCommand("ulx","force",other_ent:Nick(),"detective")
         block_id = other_ent:EntIndex()

         other_ent:PrintMessage(HUD_PRINTCENTER, "Block get!")
         other_ent:PrintMessage(HUD_PRINTTALK, other_ent:Nick().." got the block!")

         other_ent:EmitSound("AlyxEMP.Charge")
         _effect("Sparks", self:GetPos(), 5, 1.0, 0.5)

         self:Remove()
      end
   end
end

-- if CLIENT then
--    function ENT:Think()
--       e = EffectData()
--       e:SetOrigin(self:GetPos())
--       e:SetMagnitude(0.1)
--       e:SetScale(0.1)
--       e:SetRadius(10)
--       util.Effect("sparks", e, true, true)
--    end
-- end

