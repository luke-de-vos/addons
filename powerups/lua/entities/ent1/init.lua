if SERVER then
   AddCSLuaFile()
end
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

block_id = 1 -- initial

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube05x05x05.mdl") --models/props_c17/oildrum001.mdl --models/noesis/donut.mdl
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	
	self:GetPhysicsObject():Wake()
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	self:SetTrigger(true)
	self:DrawShadow(true)
	if SERVER then
		_effect("Sparks", self:GetPos(), 5, 1.0, 0.5)
		--sound.Play("Weapon_Crossbow.BoltHitWorld", self:GetPos(), 100, 100, 100)
		block_id = self:EntIndex()
	end

end