local kamebeam = Material( "effect_texture/kamehameha_beam" )

function EFFECT:Init( data )
	self.Position = data:GetStart()
	self.EndPos = data:GetOrigin()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self:SetRenderBoundsWS( self.StartPos, self.EndPos )
	self.Dir = ( self.EndPos - self.StartPos ):GetNormalized()
	self.Dist = self.StartPos:Distance( self.EndPos )
	self.LifeTime = 1.2 - ( 1 / self.Dist )
	self.DieTime = CurTime() + self.LifeTime
end

function EFFECT:Think()
	if ( CurTime() > self.DieTime ) then return false end
	return true
end

function EFFECT:Render()
	local vec1 = ( CurTime() - self.DieTime ) / self.LifeTime
	local vec2 = ( self.DieTime - CurTime() ) / self.LifeTime
	local pos = self.EndPos - self.Dir * math.min( 1 - (vec1 * self.Dist), self.Dist )
	render.SetMaterial(kamebeam)
	render.DrawBeam( pos, self.EndPos, vec2 * 150, 0,
	self.Dist / 10, Color( 255, 255, 255, vec2 * 255 ) ) -- 10
end
