AddCSLuaFile()

if SERVER then
	resource.AddFile("materials/VGUI/ttt/icon_barrel_wand.jpg")
end

SWEP.Base = "weapon_tttbase"

SWEP.ShootSound = 	Sound("Weapon_Crossbow.BoltFly")
SWEP.ReloadSound = 	Sound("Weapon_StunStick.Activate")

SWEP.ViewModel			= "models/weapons/c_stunstick.mdl"
SWEP.WorldModel			= "models/weapons/c_stunstick.mdl"
SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName		=	"Barrel Wand"
	SWEP.Slot			=	7
	SWEP.Icon 			=	"VGUI/ttt/icon_barrel_wand.jpg"
	SWEP.DrawAmmo		=	false 
	SWEP.DrawCrosshair	=	false -- ttt2 draws crosshair
	
	SWEP.ViewModelFlip       = false
	SWEP.ViewModelFOV        = 54
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "abra kadabison"
	};
end

SWEP.Spawnable		=	true

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "RPG_Round"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= "none"

SWEP.Kind                   = WEAPON_EQUIP2
SWEP.CanBuy                 = {ROLE_TRAITOR, ROLE_INNOCENT, ROLE_DETECTIVE}
SWEP.LimitedStock           = true
SWEP.WeaponID               = BARREL_WAND

SWEP.HoldType = "melee" -- https://wiki.facepunch.com/gmod/Hold_Types

local WAND_PROP_PREFIX = "WP"
local PREFIX_LEN = string.len(WAND_PROP_PREFIX)
local HOT_BARREL_STR = WAND_PROP_PREFIX.."hot_barrel"
local HOT_BARREL_COST = 5

local next_barrel_hot = false -- when true, next ThrowProp() call throws a "hot barrel" and sets false
function SWEP:Reload()
	if not next_barrel_hot then
		if self:GetOwner():GetAmmoCount(self.Primary.Ammo) >= HOT_BARREL_COST then
			self:EmitSound(self.ReloadSound)
			self:TakePrimaryAmmo(HOT_BARREL_COST)
			next_barrel_hot = true
		end
	end
end

function SWEP:PrimaryAttack()
	self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
	self:SetNextPrimaryFire(CurTime() + 0.75)
	self:SetNextSecondaryFire(CurTime() + 0.25)
	self:ThrowProp("models/props_c17/oildrum001.mdl", 175000, 5, next_barrel_hot)
end

function SWEP:SecondaryAttack()
	self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
	self:SetNextSecondaryFire(CurTime() + 0.75)
	self:SetNextPrimaryFire(CurTime() + 0.25)
	self:ThrowProp("models/props_c17/oildrum001.mdl", 32000, 5, next_barrel_hot)
end

function SWEP:ThrowProp(model_file, force_mult, prop_duration)
	local owner = self:GetOwner()
	if not owner:IsValid() then return end
	self:EmitSound(self.ShootSound)
	if CLIENT then return end

	-- prop declaration
	local magic_prop = ents.Create("prop_physics")
	if not IsValid(magic_prop) then return end

	-- name, model
	local MY_BARREL_STR = WAND_PROP_PREFIX..self:GetOwner():SteamID()
	magic_prop:SetModel(model_file)
	if next_barrel_hot then
		magic_prop:SetName(HOT_BARREL_STR)
		magic_prop:SetColor(Color(255,0,0))
	else
		magic_prop:SetName(MY_BARREL_STR)
		magic_prop:SetColor(Color(255,150,150))
	end

	-- aiming, positioning
	local aimvec = owner:GetAimVector()
	local spawn_pos = owner:EyePos()
	spawn_pos.z = spawn_pos.z -10-- lower below eye level
	spawn_pos:Add((aimvec * 32))
	magic_prop:SetPos(spawn_pos)
	magic_prop:SetAngles(owner:EyeAngles())
	
	-- physics
	magic_prop:SetPhysicsAttacker(owner, prop_duration) -- credits player for kill
	if magic_prop:GetName() == HOT_BARREL_STR then
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			_explosion(owner, data.HitPos, 150, 125) -- radius, damage
		end)
	else
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			-- if collide with prop produced by this player..
			if data.HitEntity:GetName() == MY_BARREL_STR || data.HitEntity:GetName() == HOT_BARREL_STR then
				_explosion(owner, data.HitPos, 150, 125) -- radius, damage
				if IsValid(magic_prop) then magic_prop:Remove() end
			else
				if data.OurOldVelocity:Length() >= 500 then -- minimum speed for sparks
					if string.sub(data.HitEntity:GetName(), 0, PREFIX_LEN) == WAND_PROP_PREFIX then
						_spark(data.HitPos)
					end
				end
			end
		end)
	end

	-- spawn
	magic_prop:Spawn()
	if next_barrel_hot then 
		magic_prop:Ignite(prop_duration, 100) 
		next_barrel_hot = false
	end
	local phys = magic_prop:GetPhysicsObject()
	if not IsValid(phys) then magic_prop:Remove() return end
 
	-- propulsion
	phys:SetMass(60)
	local impulse = aimvec * phys:GetMass() * force_mult
	--aimvec:Add( VectorRand( -10, 10 ) ) -- Add a random vector with elements [-10, 10)
	phys:ApplyForceCenter(impulse * engine.TickInterval()) 

	-- despawn
	timer.Simple(prop_duration, function() 
		if magic_prop and IsValid(magic_prop) then 
			magic_prop:Remove()
		end
	end)
end

function SWEP:PreDrop()
   return self.BaseClass.PreDrop(self)
end