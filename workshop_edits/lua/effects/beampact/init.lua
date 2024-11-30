

function EFFECT:Init(data)
	--
	self.Position = data:GetOrigin()
	self.Forward = data:GetNormal()
	self.Angle = self.Forward:Angle()
	self.Right = self.Angle:Right()
	self.Scale = data:GetScale()
	--
	local emitter = ParticleEmitter(self.Position)	
//Trail	
		local particle = emitter:Add("effect_texture/beampact", self.Position)
		particle:SetVelocity(Vector (0,0,40))
		particle:SetDieTime(0.2)
		particle:SetStartAlpha(100)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.random(8,16)*self.Scale)
		particle:SetEndSize(math.random(8,16)*self.Scale*4)
		particle:SetRoll(math.Rand(0,360))
		particle:SetRollDelta(math.Rand(-1,1))
		particle:SetColor(255,255,255)
		particle:SetAirResistance(1000)
//Trail
	--NONE
//Burst
	--NONE
//Bits	
	emitter:Finish()
end


function EFFECT:Think()
	--
	return false
	--
end


function EFFECT:Render()
	--NONE	
end
