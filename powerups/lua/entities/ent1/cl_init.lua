include("shared.lua")

function ENT:Initialize()
	self.csModel = ClientsideModel("models/hunter/blocks/cube05x05x05.mdl")
end

function ENT:Draw()
	if not IsValid(self) then return end 
	if not IsValid(self.csModel) then return end 
	--self:DrawModel() -- draws server side model
	self.csModel:SetPos(self:GetPos() + Vector(0,0,math.sin(CurTime()*3)))
	self.csModel:SetAngles(Angle(0, CurTime()*90%360, 0)) 
end

function ENT:OnRemove()
	self.csModel:Remove()
end