AddCSLuaFile()

SWEP.Base = "weapon_tttbase"

if SERVER then
	--resource.AddFile("materials/VGUI/ttt/icon_posswitch.vmt")
	--resource.AddFile("materials/VGUI/ttt/icon_posswitch.vtf")
	resource.AddFile("materials/VGUI/ttt/icon_prop_siccer.png")
end

if CLIENT then
	SWEP.PrintName		=	"Prop Siccer"
	SWEP.Slot			=	7
	SWEP.Icon 			=	"VGUI/ttt/icon_prop_siccer.png"
	SWEP.DrawAmmo		=	false
	SWEP.DrawCrosshair	=	true
	SWEP.ViewModel		= "models/weapons/v_pistol.mdl"
	SWEP.ViewModelFlip       = false
	SWEP.ViewModelFOV        = 54
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "Point and shoot at a prop. Prop launches at nearest player."
	};
end

SWEP.Spawnable		=	true

SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 20
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.WorldModel			= "models/weapons/w_pistol.mdl"

SWEP.Kind                   = WEAPON_EQUIP2
SWEP.CanBuy                 = {ROLE_TRAITOR, ROLE_INNOCENT, ROLE_DETECTIVE}
SWEP.LimitedStock           = true
SWEP.WeaponID               = PROP_SICCER

SWEP.IronSightsPos         = Vector( 5, -15, -2 )
SWEP.IronSightsAng         = Vector( 2.6, 1.37, 3.5 )


function SWEP:PrimaryAttack()
	if SERVER then
		local target_ent = self:GetOwner():GetEyeTrace().Entity
		if IsValid(target_ent) and not target_ent:IsPlayer() then
			target_ent:SetPhysicsAttacker(self:GetOwner(), 3)
			sic(target_ent)
			-- check if it moved. if it moved, take ammo
			start_pos = target_ent:GetPos()
			timer.Simple(0.1, function()
				if target_ent:GetPos() != start_pos then
					self:TakePrimaryAmmo(1)
				end
			end)
		else
			print('not a phys object')
		end
	end
end

function sic(prop_ent)
	local float_duration = 1.5
	
	prop_ent:GetPhysicsObject():Wake()
	prop_ent:Ignite(float_duration, 10)
	float(prop_ent)
	timer.Simple(float_duration, function() 
		if IsValid(prop_ent) then 
			local vec = get_vec_to_closest_player(prop_ent:GetPos())
			if vec != nil then
				launch(prop_ent, vec)
			end
		end
	end)
end

function float(prop_ent)
	phys = prop_ent:GetPhysicsObject()
	phys:EnableGravity(false)
	force = Vector(0,0,1) * 3000 * phys:GetMass() * engine.TickInterval()
	phys:ApplyForceCenter(force)
	
end

function get_vec_to_closest_player(prop_pos)
	local best_vec = nil
	local this_distance = 0
	local lowest_distance = 9999999
	for i, ply in ipairs(player.GetAll()) do 
		if not ply:Alive() then continue end
		ply_pos = ply:GetPos()
		ply_pos.z = ply_pos.z + 30 -- center mass
		this_distance = _get_euc_dist(prop_pos, ply_pos)
		if this_distance < lowest_distance then
			lowest_distance = this_distance
			best_vec = ply_pos-prop_pos 
		end
	end
	return best_vec
end

function launch(prop_ent, vec)
	--normalize
	vec = _normalize_vec(vec, 1)
	local phys = prop_ent:GetPhysicsObject()
	phys:EnableGravity(true)
	local force = vec * 1000000 * phys:GetMass() * engine.TickInterval()
    phys:ApplyForceCenter(force)
	prop_ent:EmitSound("FX_RicochetSound.Ricochet", 120)
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
   --if not self.IronSightsPos then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

   local bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   self:SetZoom(bIronsights)
   if (CLIENT) then
      self:EmitSound("Weapon_Binoculars.Special2", 80)
   end

   self:SetNextSecondaryFire( CurTime() + 0.3)
end

function SWEP:Reload()
	return
end

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.PreDrop(self)
end

function SWEP:Holster()
   self:SetIronsights(false)
   self:SetZoom(false)
   return true
end

function SWEP:SetZoom(state)
   if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
      if state then
         self:GetOwner():SetFOV(20, 0.15) -- zoom in twice as fast
      else
         self:GetOwner():SetFOV(0, 0.1) -- zoom out twice as fast
      end
   end
end

if CLIENT then
   local scope = surface.GetTextureID("sprites/scope")
   function SWEP:DrawHUD()
      if self:GetIronsights() then
         surface.SetDrawColor( 0, 0, 0, 255 )
         
         local scrW = ScrW()
         local scrH = ScrH()

         local x = scrW / 2.0
         local y = scrH / 2.0
         local scope_size = scrH

         -- crosshair
         local gap = 80
         local length = scope_size
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         gap = 0
         length = 50
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )


         -- cover edges
         local sh = scope_size / 2
         local w = (x - sh) + 2
         surface.DrawRect(0, 0, w, scope_size)
         surface.DrawRect(x + sh - 2, 0, w, scope_size)
         
         -- cover gaps on top and bottom of screen
         surface.DrawLine( 0, 0, scrW, 0 )
         surface.DrawLine( 0, scrH - 1, scrW, scrH - 1 )

         surface.SetDrawColor(255, 0, 0, 255)
         surface.DrawLine(x, y, x + 1, y + 1)

         -- scope
         surface.SetTexture(scope)
         surface.SetDrawColor(255, 255, 255, 255)

         surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)
      else
         return self.BaseClass.DrawHUD(self)
      end
   end

	function SWEP:AdjustMouseSensitivity()
		return (self:GetIronsights() and 0.2) or nil
	end
end
