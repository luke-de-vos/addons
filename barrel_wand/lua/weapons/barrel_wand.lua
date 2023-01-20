print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then
	resource.AddFile("sound/body_medium_impact_hard6.wav")
	resource.AddFile("sound/body_medium_impact_hard4.wav")
	resource.AddFile("sound/body_medium_impact_hard5.wav")
	resource.AddFile("sound/parry_44.wav")
	resource.AddFile("sound/hit.wav")
	resource.AddFile("materials/VGUI/ttt/icon_barrel_wand.jpg")
	util.AddNetworkString("hitmarker_msg")
end

SWEP.Base = "weapon_tttbase"

SWEP.ShootSound = 	Sound("Weapon_Crossbow.BoltFly")
--SWEP.ReloadSound = 	Sound("Weapon_Crossbow.BoltElectrify")
SWEP.ReloadSound = 	Sound("Weapon_StunStick.Melee_Hit") -- Weapon_Crowbar.Single
SWEP.HotSound = "Weapon_PhysCannon.Launch"
SWEP.ParrySound = "parry_44.wav"
SWEP.GotParriedSound = Sound("Weapon_StunStick.Activate")
SWEP.HitSound = Sound("Hit")

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

SWEP.PropDuration = 5
SWEP.ThrowForce = 175000

SWEP.IsHot = false
SWEP.LastParryTime = 0
SWEP.LastJumpTime = 0

SWEP.PrimaryRof = 0.75
SWEP.SecondaryRof = 1.0
SWEP.InterRof = 0.2
SWEP.ReloadRof = 0.75
SWEP.NextReloadTime = 0

SWEP.MeleeReach = 60
SWEP.MeleeRadius = 55
SWEP.MeleeDamage = 150

SWEP.LastDamageTime = CurTime()

local PARRY_WINDOW = 0.2
local PARRY_THROW_WINDOW = SWEP.PrimaryRof - 0.01

local WAND_PROP_PREFIX = "WP"
local PREFIX_LEN = string.len(WAND_PROP_PREFIX)
local HOT_BARREL_NAME = WAND_PROP_PREFIX.."hot_barrel"
local HOT_BARREL_COST = 5

local SMACK_SOUNDS = {
	"body_medium_impact_hard5.wav",
	"body_medium_impact_hard4.wav",
	"body_medium_impact_hard6.wav"
	}
local CLANK_SOUNDS = {
	"physics/metal/metal_barrel_impact_soft1.wav",
	"physics/metal/metal_barrel_impact_soft2.wav",
	"physics/metal/metal_barrel_impact_soft3.wav",
	"physics/metal/metal_barrel_impact_soft4.wav"
}
local HOT_PROPS = {
	"models/props_c17/oildrum001.mdl",
	--"models/props_interiors/Furniture_Couch01a.mdl",
	--"models/props_c17/FurnitureChair001a.mdl",
	--"models/props_c17/FurnitureWashingmachine001a.mdl",
	--"models/props_c17/chair02a.mdl",
	--"models/props_lab/filecabinet02.mdl",
	--"models/props_junk/watermelon01.mdl",
	--"models/props_lab/huladoll.mdl",
	--"models/props_junk/Wheebarrow01a.mdl"
	}



function SWEP:PrimaryAttack()
	if self:GetNextPrimaryFire() <= CurTime() then
		self:SetNextPrimaryFire(math.max((CurTime() + self.PrimaryRof), self:GetNextPrimaryFire()))
		self:SetNextSecondaryFire(math.max((CurTime() + self.InterRof), self:GetNextSecondaryFire()))
		self:SetNextReload(math.max((CurTime() + self.InterRof), self.NextReloadTime))

		-- animations
		self:SendWeaponAnim( ACT_VM_MISSCENTER )
		self:GetOwner():DoAttackEvent()

		-- sounds, barrel type
		if self:GetOwner():GetAmmoCount(self.Primary.Ammo) >= HOT_BARREL_COST then
			self.IsHot = true
			self:EmitSound(self.HotSound, 100, 100, 1, CHAN_WEAPON)
			self:TakePrimaryAmmo(HOT_BARREL_COST)
		elseif (CurTime() - self:GetLastParryTime()) <= PARRY_THROW_WINDOW then
			self.IsHot = true
			--self:GetOwner():EmitSound(self.HotSound, 100, 100, 1, CHAN_WEAPON)
		else 
			self:EmitSound(self.ShootSound, 100, 100, 1, CHAN_WEAPON)
		end
		if IsValid(self) then
			self:ThrowProp("models/props_c17/oildrum001.mdl", self.ThrowForce, self.PropDuration, 1.0)
			self.IsHot = false
		end
	end
end

function SWEP:SecondaryAttack()
	if self:GetNextSecondaryFire() <= CurTime() then
		self:SetNextPrimaryFire(math.max((CurTime() + self.InterRof), self:GetNextPrimaryFire()))
		self:SetNextSecondaryFire(math.max((CurTime() + self.SecondaryRof), self:GetNextSecondaryFire()))
		self:SetNextReload(math.max((CurTime() + self.InterRof), self.NextReloadTime))

		self.LastJumpTime = CurTime()
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
		self:GetOwner():DoCustomAnimEvent(PLAYERANIMEVENT_JUMP, 0)
		self:EmitSound("Grenade.Blip", 50, 100, 1, CHAN_WEAPON)
	end
end

function SWEP:Reload()
	if self.NextReloadTime <= CurTime() then
		self:SetNextPrimaryFire(math.max((CurTime() + self.InterRof), self:GetNextPrimaryFire()))
		self:SetNextSecondaryFire(math.max((CurTime() + self.InterRof), self:GetNextSecondaryFire()))
		self:SetNextReload(math.max((CurTime() + self.ReloadRof), self.NextReloadTime))

		self:EmitSound(self.ReloadSound)
		self:GetOwner():DoAttackEvent()

		if SERVER then
			self:SendWeaponAnim(ACT_VM_MISSCENTER)
		end

		local owner = self:GetOwner()
		local pos = owner:GetAimVector()*self.MeleeReach + owner:GetShootPos()
		if IsValid(owner) then
			if SERVER then
				local eff = EffectData()
				eff:SetOrigin(pos)
				eff:SetScale(1)
				eff:SetMagnitude(1)
				eff:SetRadius(1)
				util.Effect("GunshipImpact", eff, true, true)
				util.BlastDamage(self, owner, pos, self.MeleeRadius, self.MeleeDamage) -- radius, damage
			end
		end
	end
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
		magic_prop:SetColor(Color(255,255,255))
	end

	-- aiming, positioning
	local aimvec = owner:GetAimVector()
	local spawn_pos = owner:EyePos()
	spawn_pos.z = spawn_pos.z - 10 -- lower below eye level
	spawn_pos:Add((aimvec * 32))
	magic_prop:SetPos(spawn_pos)
	magic_prop:SetAngles(owner:EyeAngles())
	
	-- physics
	magic_prop:SetPhysicsAttacker(owner, prop_duration) -- credits player for kill
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

function freeze(func_ply, pos)
	-- parry freeze frames
	local hook_name = "BW_freeze_"..func_ply:SteamID()
	func_ply:SetMoveType(0)
	hook.Add("Move", hook_name, function(hook_ply, move_info)
		if hook_ply:Nick() == func_ply:Nick() then
			move_info:SetVelocity(Vector(0,0,0))
			move_info:SetOrigin(pos)
		end
	end)
	timer.Simple(0.2, function()
		hook.Remove("Move", hook_name)
		func_ply:SetMoveType(2)
	end)
end

-- handle parry and damage
SWEP.dtrack = {} -- should probably track this in the barrel instead. make SENT
if SERVER then
	hook.Add("EntityTakeDamage", "bw_takedamage", function(vic, dmg) 
		if vic:IsPlayer() then 
			local wep = vic:GetActiveWeapon()
			if IsValid(wep) and wep:GetPrintName() == 'barrel_wand' then
				local cl = dmg:GetInflictor():GetClass()
				local id = dmg:GetInflictor():GetCreationID()
				if cl == 'prop_physics' then
					if wep.dtrack[id] != nil then
						dmg:SetDamage(0)
					end
				end
				if dmg:IsExplosionDamage() and cl == "barrel_wand" then
					dmg:SetDamage(wep.MeleeDamage)
				end
				if dmg:GetDamage() > 0 then
					local att = dmg:GetAttacker()
					if att:IsPlayer() and CurTime() - wep:GetLastJumpTime() <= PARRY_WINDOW then
						parry_updates(wep, att, vic, dmg)
					else
						wep.LastDamageTime = CurTime()
						if dmg:GetInflictor():GetName() == HOT_BARREL_NAME then
							_explosion(att, att, vic:GetPos(), 150, 600)
						elseif cl == "prop_physics" then
							wep.dtrack[id] = true
							dmg:SetDamage(400) -- divided by 4 for some reason? does 100 damage
							sound.Play(SMACK_SOUNDS[math.random(#SMACK_SOUNDS)], dmg:GetInflictor():GetPos())
						end
					end
				end
			end
		end
	end)

	function parry_updates(wep, att, vic, dmg)
		wep:SetLastParryTime(CurTime())
		wep:SendWeaponAnim( ACT_VM_HITCENTER )
		wep:EmitSound(wep.ParrySound)
		att:EmitSound(wep.GotParriedSound)
		freeze(vic, vic:GetPos())
		freeze(att, att:GetPos())
		dmg:SetDamage(0)
		if IsValid(dmg:GetInflictor()) and dmg:IsDamageType(DMG_CRUSH) then
			_effect("ElectricSpark", dmg:GetInflictor():GetPos(),2,2,10)
			dmg:GetInflictor():Remove()
		else
			_effect("ElectricSpark", vic:GetShootPos() + vic:GetAimVector()*20,2,2,10)
		end
		-- update cooldowns
		att:GetActiveWeapon():SetNextPrimaryFire(CurTime() + wep.PrimaryRof)
		wep:SetNextSecondaryFire(CurTime()+0.2)
		wep:SetNextPrimaryFire(CurTime()+0.05)
		wep:SetNextReload(CurTime()+0.1)
	end
end

function SWEP:AddPhysicsCallback(magic_prop, owner, MY_BARREL_NAME)
	magic_prop:AddCallback("PhysicsCollide", function(ent, data)
		local hit_ent = data.HitEntity
		if hit_ent:GetName() == MY_BARREL_NAME || hit_ent:GetName() == HOT_BARREL_NAME then
			if data.DeltaTime > 0.1 then -- ignore when many collision are quickly reported
				if IsValid(magic_prop) then magic_prop:Remove() end
				if IsFirstTimePredicted() then
					_explosion(owner, owner, data.HitPos, 150, 300) -- radius, damage
				end
			end
		else
			if data.OurOldVelocity:Length() >= 700 then -- minimum speed for barrel collision effects
				if string.sub(hit_ent:GetName(), 0, PREFIX_LEN) == WAND_PROP_PREFIX then
					if IsFirstTimePredicted() then
						sound.Play(CLANK_SOUNDS[math.random(#CLANK_SOUNDS)], data.HitPos, 75, 100, 1)
						--_spark(data.HitPos)
						_effect("MetalSpark", data.HitPos, 1, 1, 1)
					end
				end
			end
		end
	end)
end

-- HEALTH REGEN
function SWEP:Think() 
	if CurTime() - self.LastDamageTime >= 4 then
		local owner = self:GetOwner()
		if owner:Health() < owner:GetMaxHealth() then
			owner:SetHealth(math.min(owner:Health()+2, owner:GetMaxHealth()))
		end
	end
end

function SWEP:Equip()
	if IsValid(self:GetOwner()) then
		self:GetOwner():SetMaxHealth(200)
		self.LastDamageTime = CurTime()
	end
end

function SWEP:Holster()
	if SERVER then
		if IsValid(self:GetOwner()) then
			self:GetOwner():SetMaxHealth(100)
			self:GetOwner():SetHealth(100)
		end
	end
end

-- function SWEP:OnRemove()
-- 	-- self:Holster()
-- end

function SWEP:GetLastJumpTime()
	return self.LastJumpTime
end
function SWEP:SetLastJumpTime(val)
	self.LastJumpTime = val
end
function SWEP:GetLastParryTime()
	return self.LastParryTime
end
function SWEP:SetLastParryTime(val)
	self.LastParryTime = val
end
function SWEP:SetNextReload(val)
	self.NextReloadTime = val
end
function SWEP:PreDrop()
	return self.BaseClass.PreDrop(self)
end

if CLIENT then
	net.Receive("hitmarker_msg", function()
		surface.PlaySound("hit.wav")
	end)
end