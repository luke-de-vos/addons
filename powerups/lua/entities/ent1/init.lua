if SERVER then
   AddCSLuaFile()
end
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube05x05x05.mdl") --models/props_c17/oildrum001.mdl
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	
	self:GetPhysicsObject():Wake()
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	self:SetTrigger(true)

end

function ENT:StartTouch(other_ent)
	if other_ent:IsPlayer() then
		other_ent:ChatPrint("Powerup!")
		other_ent:EmitSound("AlyxEMP.Charge")
		other_ent:SetHealth(other_ent:Health()+500)
		_effect("Sparks", self:GetPos(), 5, 0.5, 0.5)
		local respawn_point = self.SpawnPoint
		self:Remove()

		-- respawn powerup
		timer.Simple(5, function()
			local ent = ents.Create("ent1")
			if not IsValid(ent) then return end
			ent.SpawnPoint = respawn_point
			ent:SetPos(ent.SpawnPoint)
			ent:Spawn()
		end)

	end
end