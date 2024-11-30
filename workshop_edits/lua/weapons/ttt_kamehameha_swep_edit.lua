

-- TTT VALUES
SWEP.PrintName			= "Kamehameha 2"
SWEP.Author             = "Lord Hamster, dev douglas"
SWEP.Base 				= TTT and "weapon_tttbase" or "weapon_base"
SWEP.Instructions       = "OVER 9000!!!"
SWEP.Kind 				= WEAPON_EQUIP1
SWEP.CanBuy = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
SWEP.LimitedStock 		= true
SWEP.InLoadoutFor 		= nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.AutoSpawnable = false
SWEP.HoldType = "normal"
SWEP.UseHands = true


--
SWEP.AdminSpawnable		= true
SWEP.ViewModelFlip = false
SWEP.ViewModel			= Model("models/weapons/kamehameha_viewmodel.mdl")
SWEP.WorldModel			= Model("models/weapons/kamehameha_viewmodel.mdl")
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.FiresUnderwater = true



--
SWEP.Primary.Damage         = 100
SWEP.Primary.ClipSize         	= 80
SWEP.Primary.DefaultClip    	= 80
SWEP.Primary.Automatic         	= true
SWEP.Primary.Ammo         	= "ki"
SWEP.Primary.Force		= 1000
SWEP.Primary.Cone		= 0.0001
SWEP.Primary.Delay = 50
--
SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false
--
SWEP.Slot				= 1
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true

util.PrecacheModel( SWEP.ViewModel )
util.PrecacheModel( SWEP.WorldModel )
--

   SWEP.Icon = "VGUI/ttt/icon_kamehameha_ttt"
   SWEP.Slot = 2
   SWEP.Category  = "Other"
SWEP.EquipMenuData = {
      type  = "item_weapon",
      name  = "Kamehameha",
      desc  = "Over 9000. Freezes the Traitor when firing. Watch out for the blast!!"
   };


if SERVER then
	-- (assumes workshop addon is installed on server)
	-- resource.AddFile("effect_texture/kamehameha_beam.vmt")
	-- resource.AddFile("effect_texture/kamehameha_beam.vtf")
	-- resource.AddFile("VGUI/ttt/icon_kamehameha_ttt.vtf")
	-- resource.AddFile("VGUI/ttt/icon_kamehameha_ttt.vtf")
	-- resource.AddFile("weapons/shoot/kamehame.wav")
	-- resource.AddFile("weapons/shoot/ha.wav")
end

function SWEP:IsEquipment() return false end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:Initialize()
	self.addhp = 0
	self.timehp = 0
	self:SetWeaponHoldType( self.HoldType )
end

function SWEP:DoImpactEffect( trace, damageType )
	local effects = EffectData()
	effects:SetOrigin(trace.HitPos + Vector( math.Rand( -0.5, 0.5 ), math.Rand( -0.5, 0.5 ), math.Rand( -0.5, 0.5 ) ))
	effects:SetScale(0.35)--0.35
	effects:SetRadius(30)
	effects:SetMagnitude(3)
	effects:SetAngles(Angle(0,90,0))	
	util.Effect( "none", effects )
	return true
end

function SWEP:SecondaryAttack()
	return true
end

function SWEP:Think()	
end

function SWEP:PrimaryAttack()

    if (self.Weapon:Clip1() < 50) then return end

	local ply = self.Owner

	if SERVER then
		sound.Play("weapons/shoot/kamehame.wav", ply:GetPos(), 80, 100, 1.0, 0)
	end

	-- hold type while charging
	self:SetHoldType("melee2")
	self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	-- do util.Effect waterexplosion at player's location every 0.1 seconds for 3.4 seconds
	local repetitions = 30
	local on_rep = 0
	timer.Create( "charge_effect_timer"..self.Owner:Nick(), 0.1, repetitions, function()
		if !IsValid(self) or !self.Owner:Alive() then return end
		on_rep = on_rep + 1
		local eff = EffectData()
		eff:SetOrigin(self.Owner:GetAttachment(5).Pos)
		eff:SetScale(1 * (on_rep/repetitions))
		eff:SetMagnitude(3 * (on_rep/repetitions))
		eff:SetRadius(20 * (on_rep/repetitions))
		eff:SetNormal(self.Owner:GetAimVector())
		util.Effect("sparks", eff, false, true)
	end)

	timer.Create( "FinalHA"..self.Owner:Nick(), 3.4, 1, function()
		if !IsValid(self) or !self.Owner:Alive() then return end

		local original_velocity = self.Owner:GetVelocity()
		self.Owner:SetVelocity(-original_velocity)
		local original_movetype = self.Owner:GetMoveType()
		self.Owner:SetMoveType(MOVETYPE_NONE)
    	self.Owner:Freeze(true)

		self:SetHoldType("duel") -- hold type while firing
		for k, v in pairs( player.GetAll( ) ) do
			v:ConCommand( "play weapons/shoot/ha.wav\n" )
		end
		--sound.Play("weapons/shoot/ha.wav", ply:GetPos(), 150, 100, 1.0, 0)

		-- create beam
		local beam_bullet = {}
		beam_bullet.HullSize = 25
		beam_bullet.Attacker = self.Owner
		beam_bullet.Spread 	= Vector(0, 0, 0)
		beam_bullet.Num = 1
		beam_bullet.Tracer = 1
		beam_bullet.TracerName = "kamebeam"
		beam_bullet.Damage	= 100
		beam_bullet.AmmoType = "ki"
		beam_bullet.Force = 30			
		beam_bullet.Src = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * beam_bullet.HullSize * 2)
		beam_bullet.Dir = self.Owner:GetAimVector()
		beam_bullet.IgnoreEntity = self.Owner

		local impact_eff = EffectData()
		local kmins = Vector(1,1,1) * -beam_bullet.HullSize
		local kmaxs = Vector(1,1,1) * beam_bullet.HullSize

		local trace = self.Owner:GetEyeTrace()	
		--sound.Play("weapons/shoot/ha.wav", trace.HitPos, 90, 100, 1.0, 0)

		local beam_step = 0
		timer.Create( "Beam"..self.Owner:Nick(), 0.010, self.Primary.ClipSize, function()
			if !IsValid(self) or !self.Owner:Alive() then return end
			beam_step = beam_step + 1
			trace = self.Owner:GetEyeTrace()
        	self:TakePrimaryAmmo(1)
   			self.Owner:FireBullets(beam_bullet)
			impact_eff:SetOrigin(trace.HitPos)
			impact_eff:SetMagnitude(3.1)
			impact_eff:SetRadius(200)
			impact_eff:SetScale(10)
			impact_eff:SetAngles(Angle(0,90,0))
			util.Effect( "beampact", impact_eff )
			util.BlastDamage(self, self.Owner, trace.HitPos, 175, 250)
			util.BlastDamage(self, self.Owner, trace.HitPos, 325, 2)
			if beam_step % 18 == 0 then
				-- explosion effect at trace.HitPos
				effect = EffectData()
				effect:SetStart(trace.HitPos)
				effect:SetOrigin(trace.HitPos)
				effect:SetScale(1)
				effect:SetRadius(10)
				effect:SetMagnitude(1)
				util.Effect("Explosion", effect, true, true)
			end

			sound.Play("weapons/explosion/dbzexplosion.wav", trace.HitPos, 20)
    	end)
	
		-- unfreeze player after beam is done
		timer.Simple(1.8, function()
		if ply:Alive() then
			self.Owner:Freeze(false) 
			if original_movetype == MOVETYPE_NONE then
				self.Owner:SetMoveType(MOVETYPE_WALK)
			else
				self.Owner:SetMoveType(original_movetype)
			end
			self:SetHoldType(self.HoldType)
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE) -- (first person) put hands down 
		end
	end)
		
	end)
	
	self:SetNextPrimaryFire( CurTime() + 8 )  
end
 
function SWEP:Deploy()
	self.Weapon:SendWeaponAnim( ACT_VM_HOLSTER )
	self:SetHoldType(self.HoldType)
	return true;
end

function SWEP:Holster()
	return true;
end


function SWEP:OnDrop()
	self:Remove()
end

function SWEP:SetIronsights()
	return
end

function SWEP:SetZoom()
	return
end

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end
end