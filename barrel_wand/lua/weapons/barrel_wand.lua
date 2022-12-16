AddCSLuaFile()
print("Executed lua: " .. debug.getinfo(1,'S').source)

resource.AddFile("sound/body_medium_impact_hard6.wav")
resource.AddFile("sound/body_medium_impact_hard4.wav")
resource.AddFile("sound/body_medium_impact_hard5.wav")


if SERVER then
	resource.AddFile("materials/VGUI/ttt/icon_barrel_wand.jpg")
end

SWEP.Base = "weapon_tttbase"

SWEP.ShootSound = 	Sound("Weapon_Crossbow.BoltFly")
SWEP.ReloadSound = 	Sound("Weapon_StunStick.Activate")
SWEP.ParrySound = Sound("")

SWEP.ViewModel			= "models/weapons/c_stunstick.mdl"
SWEP.WorldModel			= "models/weapons/c_stunstick.mdl"
SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName		=	"Barrel Wand"
	SWEP.Slot			=	7
	SWEP.Icon 			=	"VGUI/ttt/icon_barrel_wand.jpg"
	SWEP.DrawAmmo		=	true 
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

SWEP.Secondary.ClipSize		= 2
SWEP.Secondary.DefaultClip	= 2
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= "RPG_Round"

SWEP.Kind                   = WEAPON_EQUIP2
SWEP.CanBuy                 = {ROLE_TRAITOR, ROLE_INNOCENT, ROLE_DETECTIVE}
SWEP.LimitedStock           = true
SWEP.WeaponID               = BARREL_WAND

SWEP.HoldType = "melee" -- https://wiki.facepunch.com/gmod/Hold_Types

SWEP.IsHot = false
SWEP.LastJumpTime = 0
local PARRY_WINDOW = 0.2

local WAND_PROP_PREFIX = "WP"
local PREFIX_LEN = string.len(WAND_PROP_PREFIX)
local HOT_BARREL_NAME = WAND_PROP_PREFIX.."hot_barrel"
local HOT_BARREL_COST = 5

local SMACK_SOUNDS = {
	"body_medium_impact_hard5.wav",
	"body_medium_impact_hard4.wav",
	"body_medium_impact_hard6.wav"
	}
local HOT_PROPS = {
	--"models/props_interiors/Furniture_Couch01a.mdl",
	--"models/props_c17/FurnitureChair001a.mdl",
	--"models/props_c17/FurnitureWashingmachine001a.mdl",
	--"models/props_c17/chair02a.mdl",
	--"models/props_lab/filecabinet02.mdl",
	--"models/props_junk/watermelon01.mdl",
	"models/props_lab/huladoll.mdl",
	--"models/props_junk/Wheebarrow01a.mdl"
	}


function SWEP:Reload()
	
end

function SWEP:PrimaryAttack()
	if self:GetOwner():GetAmmoCount(self.Primary.Ammo) >= HOT_BARREL_COST then
		self.IsHot = true
		self:EmitSound("Weapon_PhysCannon.Launch", 100, 100)
		self:TakePrimaryAmmo(HOT_BARREL_COST)
	end
	self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
	self:SetNextPrimaryFire(math.max((CurTime() + 0.75), self:GetNextPrimaryFire()))
	self:SetNextSecondaryFire(math.max((CurTime() + 0.2 ), self:GetNextSecondaryFire()))
	self:EmitSound(self.ShootSound)
	self:ThrowProp("models/props_c17/oildrum001.mdl", 175000, 5, 1.0)
	self.IsHot = false
end

function SWEP:GetLastJumpTime()
	return self.LastJumpTime
end

if SERVER then 
	_add_hook("EntityTakeDamage", "bw_takedamage", function(target_ent, dmg) 
		if target_ent:IsPlayer() and dmg:IsDamageType(DMG_CRUSH) then
			local wep = target_ent:GetActiveWeapon()
			if IsValid(wep) and wep:GetPrintName() == 'barrel_wand' then
				if CurTime() - wep:GetLastJumpTime() <= PARRY_WINDOW then
					print("parried!")
					dmg:SetDamage(0)
					wep:GetOwner():Lock()
					timer.Simple(0.2, function() wep:GetOwner():UnLock() end)
				end
			end
		end
	end)
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(math.max((CurTime() + 0.2), self:GetNextPrimaryFire()))
	local next_secondary = math.max((CurTime() + 1.0 ), self:GetNextSecondaryFire())
	self:SetNextSecondaryFire(next_secondary)
	self.LastJumpTime = CurTime()
	self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )	
	if self:GetOwner():KeyDown(4) then -- crouch binding
		self:GetOwner():SetVelocity(Vector(0,0,500))
	else
		self:GetOwner():SetVelocity((self:GetOwner():GetAimVector() + Vector(0,0,0.4)) * 500)
	end
	-- sound and visual
	if SERVER then 
		local effect = EffectData()
		local origin = self:GetOwner():GetPos()+Vector(0,0,30)
		_effect("Sparks", origin, 1, 1, 1)
	end
	self:EmitSound("Grenade.Blip", 50, 100)
end

function SWEP:ThrowProp(model_file, force_mult, prop_duration, weight_mult)
	local owner = self:GetOwner()
	if not owner:IsValid() then return end
	if CLIENT then return end

	-- prop declaration
	local magic_prop = ents.Create("prop_physics")
	if not IsValid(magic_prop) then return end

	-- name, model
	MY_BARREL_NAME = WAND_PROP_PREFIX..self:GetOwner():SteamID()
	if self.IsHot then
		magic_prop:SetModel(HOT_PROPS[math.random(#HOT_PROPS)])
		magic_prop:SetName(HOT_BARREL_NAME)
		magic_prop:SetColor(Color(255,0,0))
	else
		magic_prop:SetModel(model_file)
		magic_prop:SetName(MY_BARREL_NAME)
		magic_prop:SetColor(Color(255,150,150))
	end

	-- aiming, positioning
	local aimvec = owner:GetAimVector()
	local spawn_pos = owner:EyePos()
	spawn_pos.z = spawn_pos.z - 10 -- lower below eye level
	spawn_pos:Add((aimvec * 32))
	magic_prop:SetPos(spawn_pos)
	magic_prop:SetAngles(owner:EyeAngles())
	
	-- physics
	magic_prop:SetPhysicsAttacker(owner, prop_duration) -- credits player for kill -- temp
	self:AddPhysicsCallback(magic_prop, owner, MY_BARREL_NAME)

	-- spawn
	magic_prop:Spawn()
	if self.IsHot then 
		magic_prop:Ignite(prop_duration, 100) 
	end
	local phys = magic_prop:GetPhysicsObject()
	if not IsValid(phys) then magic_prop:Remove() return end
 
	-- propulsion
	phys:SetMass(60*weight_mult)
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

function SWEP:AddPhysicsCallback(magic_prop, owner, MY_BARREL_NAME)
	if magic_prop:GetName() == HOT_BARREL_NAME then
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			_explosion(owner, data.HitPos, 150, 125) -- radius, damage
		end)
	else
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			-- if collide with prop produced by this player..
			local hit_ent = data.HitEntity
			if hit_ent:IsPlayer() then
				local wep = hit_ent:GetActiveWeapon()
				if wep:GetPrintName() == self:GetPrintName() then
					local plus = CurTime() - wep:GetLastJumpTime()
					--print(plus)
					if plus <= PARRY_WINDOW then
						wep:SetNextSecondaryFire(CurTime()+0.1)
						wep:SetNextPrimaryFire(CurTime()+0.1)
						wep:EmitSound(self.ReloadSound)
						if IsValid(magic_prop) then
							_spark(magic_prop:GetPos())
							magic_prop:Remove()
						end
					end
				end
			elseif hit_ent:GetName() == MY_BARREL_NAME || hit_ent:GetName() == HOT_BARREL_NAME then
				_explosion(owner, data.HitPos, 150, 125) -- radius, damage
				if IsValid(magic_prop) then magic_prop:Remove() end
			else
				if data.OurOldVelocity:Length() >= 700 then -- minimum speed for sparks
					if hit_ent:IsPlayer() then
						magic_prop:EmitSound(SMACK_SOUNDS[math.random(#SMACK_SOUNDS)])						
					elseif string.sub(hit_ent:GetName(), 0, PREFIX_LEN) == WAND_PROP_PREFIX then
						_spark(data.HitPos)
					end
				end
			end
		end)
	end
end