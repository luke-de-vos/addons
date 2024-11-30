AddCSLuaFile()

SWEP.HoldType                = "melee"

if CLIENT then
   SWEP.PrintName            = "Muddy Crowbar"
   SWEP.Slot                 = 1

   SWEP.DrawCrosshair        = false
   SWEP.ViewModelFlip        = false
   SWEP.ViewModelFOV         = 54

   SWEP.Icon                 = "vgui/ttt/icon_cbar"
end

SWEP.Base                    = "weapon_tttbase"

SWEP.UseHands                = true
SWEP.ViewModel               = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel              = "models/weapons/w_crowbar.mdl"

SWEP.Primary.Damage          = 2
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 0.35
SWEP.Primary.Ammo            = "none"
SWEP.Primary.Cone            = 0.00
SWEP.Primary.Recoil          = 0.00

SWEP.Secondary.ClipSize      = -1
SWEP.Secondary.DefaultClip   = -1
SWEP.Secondary.Automatic     = true
SWEP.Secondary.Ammo          = "none"
SWEP.Secondary.Delay         = 0.3

SWEP.HeadshotMultiplier      = 5


SWEP.CanBuy                  = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}

SWEP.Kind                    = WEAPON_MELEE
-- SWEP.WeaponID                = AMMO_CROWBAR 

SWEP.NoSights                = true
SWEP.IsSilent                = true

SWEP.Weight                  = 5
SWEP.AutoSpawnable           = false

--SWEP.AllowDelete             = false -- never removed for weapon reduction
SWEP.AllowDelete             = true
SWEP.AllowDrop               = true

local sound_single = Sound("Weapon_Crowbar.Single")
local sound_open = Sound("DoorHandles.Unlocked3")


SWEP.PrintName = "Melee Weapon"
SWEP.Author = "Your Name"
SWEP.Instructions = "Primary fire to attack"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.MeleeRange = 65 -- Melee range in units
SWEP.MeleeHullSize = 5 -- Hull size used for the melee swep's collision checks. Range is approximately 2x the hull size.
SWEP.ImpactSound = Sound("physics/metal/metal_grenade_impact_hard1.wav")





function SWEP:PrimaryAttack()
   local ply = self:GetOwner()
    
   ply:FireBullets({
      Attacker = ply,
      Damage = self.Primary.Damage,
      Force = 5,
      HullSize = self.MeleeHullSize,
      Src = ply:GetShootPos(),
      Dir = ply:GetAimVector(),
      Distance = self.MeleeRange,
      IgnoreEntity = ply,
      AmmoType = self.Primary.Ammo,
      Tracer = 0
   })

   if SERVER then
      if IsFirstTimePredicted() then
         ply:EmitSound(sound_single)
         self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
         self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
      end
   end


   -- if SERVER then
   --    if IsFirstTimePredicted() then
   --       if IsValid(ent) and ent:IsPlayer() then
   --          ent:EmitSound(self.ImpactSound, 90, math.random(150, 200))
   --       end
   --       ply:EmitSound(sound_single)
   --    end
   -- end

    -- Set next primary fire, play swing animations, etc.
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end


-- function SWEP:PrimaryAttack()
--    local ply = self:GetOwner()
--    if not IsValid(ply) then return end

--    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay) -- Cooldown before the next attack

--    local attackOrigin = ply:GetShootPos()
--    local forward = ply:GetAimVector()
--    local targets = ents.FindInCone(attackOrigin, forward, self.MeleeRange, math.cos(math.rad(self.MeleeAngle)))
--     -- print distance to point hit by eye trace
--    print((ply:GetEyeTrace().HitPos - ply:GetShootPos()):Length())


--     for _, target in pairs(targets) do
--         if (target:IsPlayer() or target:IsRagdoll()) and target != ply then
--             local dmginfo = DamageInfo()
--             dmginfo:SetDamage(self.Primary.Damage) -- Set the damage amount
--             dmginfo:SetAttacker(ply)
--             dmginfo:SetInflictor(self)
--             dmginfo:SetDamageType(DMG_CLUB)

--             -- shoot bullets
--             --if SERVER then
--                print("shoot bullets")
--                local ply = Entity(1)
--                local bullet = {}
--                bullet.Num = 1
--                bullet.Src = ply:GetShootPos()
--                -- dir = difference between player's eye position and target center
--                bullet.Dir = (target:GetPos() + Vector(0,0,39)) - ply:GetShootPos()
--                bullet.Spread = Vector(0, 0, 0)
--                bullet.Tracer = 0
--                bullet.Force = 1
--                bullet.Damage = 1
--                ply:FireBullets(bullet)
--             --end

--             -- if SERVER then
--             --     target:TakeDamageInfo(dmginfo)
--             -- end

--             -- Optional: Play hit sound
--          -- target:EmitSound("your/hit/sound.wav")
--       end
--    end

--    -- Optional: Play attack animation
--    if #targets > 0 then
--       self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
--    else
--       self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
--    end   
--    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )


--    -- Optional: Play swing sound
--    if SERVER then
--       ply:EmitSound(sound_single)
--    end
-- end



function SWEP:SecondaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
   self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay)

   local ply = self:GetOwner()
   if not IsValid(ply) then return end
   local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

   local attackOrigin = ply:GetShootPos()
   local forward = ply:GetAimVector()

   if CLIENT then
      AddSphere(ply:GetPos(), self.MeleeRange, 5)
   end

   if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and (self:GetOwner():EyePos() - tr.HitPos):Length() < 100 then
      local ply = tr.Entity

      if SERVER and (not ply:IsFrozen()) then
         local pushvel = tr.Normal * GetConVar("ttt_crowbar_pushforce"):GetFloat()

         -- limit the upward force to prevent launching
         pushvel.z = math.Clamp(pushvel.z, 50, 100)

         ply:SetVelocity(ply:GetVelocity() + pushvel)
         self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
         

         ply.was_pushed = {att=self:GetOwner(), t=CurTime(), wep=self:GetClass()} --, infl=self}
      end

      self.Weapon:EmitSound(sound_single)      
      self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
      self:GetOwner():SetAnimation( PLAYER_ATTACK1 )


      self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
   end
   
end

function SWEP:GetClass()
	return "weapon_ttt_muddy_crowbar"
end

function SWEP:OnDrop()
	--self:Remove()
end
