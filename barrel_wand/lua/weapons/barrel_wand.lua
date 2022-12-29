AddCSLuaFile()
print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then
	resource.AddFile("sound/body_medium_impact_hard6.wav")
	resource.AddFile("sound/body_medium_impact_hard4.wav")
	resource.AddFile("sound/body_medium_impact_hard5.wav")
	resource.AddFile("sound/parry_44.wav")
end

if SERVER then
	resource.AddFile("materials/VGUI/ttt/icon_barrel_wand.jpg")
end

SWEP.Base = "weapon_tttbase"

SWEP.ShootSound = 	Sound("Weapon_Crossbow.BoltFly")
SWEP.ReloadSound = 	Sound("Weapon_StunStick.Activate")
SWEP.HotSound = "Weapon_PhysCannon.Launch"
SWEP.ParrySound = "parry_44.wav"

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

local PARRY_WINDOW = 0.2
local PARRY_THROW_WINDOW = 0.7

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
		--self:SetNextSecondaryFire(math.max((CurTime() + self.InterRof), self:GetNextSecondaryFire()))

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
			self:GetOwner():EmitSound("self.HotSound", 100, 100, 1, CHAN_WEAPON)
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
	--self:SetNextPrimaryFire(math.max((CurTime() + self.InterRof), self:GetNextPrimaryFire()))
	if self:GetNextSecondaryFire() <= CurTime() then
		self:SetNextSecondaryFire(math.max((CurTime() + self.SecondaryRof), self:GetNextSecondaryFire()))
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
		magic_prop:SetColor(Color(0,255,0))
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

if SERVER then
	-- Check for parry and hot barrel
	hook.Add("EntityTakeDamage", "bw_takedamage", function(target_ent, dmg)
		if target_ent:IsPlayer() and dmg:GetAttacker():IsPlayer() then
			local wep = target_ent:GetActiveWeapon()
			if IsValid(wep) and wep:GetPrintName() == 'barrel_wand' then
				local diff = CurTime() - wep:GetLastJumpTime() 
				if diff <= PARRY_WINDOW then -- parried
					wep:SetLastParryTime(CurTime())
					wep:SendWeaponAnim( ACT_VM_HITCENTER )
					freeze(target_ent, target_ent:GetPos())
					freeze(dmg:GetAttacker(), dmg:GetAttacker():GetPos())
					dmg:SetDamage(0)
					wep:EmitSound(wep.ParrySound)
					dmg:GetAttacker():EmitSound(wep.ReloadSound)
					if IsValid(dmg:GetInflictor()) and dmg:IsDamageType(DMG_CRUSH) then
						_effect("Sparks", dmg:GetInflictor():GetPos()+Vector(0,0,20),2,2,2)
						dmg:GetInflictor():Remove()
					end
					-- refresh cooldowns
					wep:SetNextSecondaryFire(CurTime()+0.2)
					wep:SetNextPrimaryFire(CurTime()+0.1)
				else -- got hit	
					sound.Play(SMACK_SOUNDS[math.random(#SMACK_SOUNDS)], dmg:GetInflictor():GetPos())
					if dmg:GetInflictor():GetName() == HOT_BARREL_NAME then
						dmg:SetDamage(600)
					end
				end
			end
		end
	end)
end

function SWEP:AddPhysicsCallback(magic_prop, owner, MY_BARREL_NAME)
	if magic_prop:GetName() == HOT_BARREL_NAME then
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			local hit_ent = data.HitEntity
			if string.sub(hit_ent:GetName(), 0, PREFIX_LEN) == WAND_PROP_PREFIX then
				hit_ent:Remove()
			end
			-- if data.DeltaTime > 0.5 then
			-- 	_explosion(owner, data.HitPos, 150, 125) -- radius, damage
			-- end
		end)
	else
		magic_prop:AddCallback("PhysicsCollide", function(ent, data)
			local hit_ent = data.HitEntity
			if hit_ent:GetName() == MY_BARREL_NAME || hit_ent:GetName() == HOT_BARREL_NAME then
				_explosion(owner, data.HitPos, 150, 125) -- radius, damage
				if IsValid(magic_prop) then magic_prop:Remove() end
			else
				if data.OurOldVelocity:Length() >= 700 then -- minimum speed for barrel collision effects
					if string.sub(hit_ent:GetName(), 0, PREFIX_LEN) == WAND_PROP_PREFIX then
						sound.Play(CLANK_SOUNDS[math.random(#CLANK_SOUNDS)], data.HitPos, 75, 100, 1)
						_spark(data.HitPos)
					end
				end
			end
		end)
	end
end

function SWEP:Reload()
	
end
function SWEP:PreDrop()
   return self.BaseClass.PreDrop(self)
end

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

function get_closest_player(source)
	if !IsValid(source) then return end
	local prop_pos = source:GetPos()
	local best_ply = nil
	local this_distance = 0
	local lowest_distance = 9999999
	for i, ply in ipairs(player.GetAll()) do
		if source:Nick() == ply:Nick() then continue end
		if not ply:Alive() then continue end
		--if ply:GetRole() != ROLE_INNOCENT then continue end
		local ply_pos = ply:GetPos()
		ply_pos.z = ply_pos.z + 30 -- center mass
		this_distance = _get_euc_dist(prop_pos, ply_pos)
		if this_distance < lowest_distance then
			lowest_distance = this_distance
			best_ply = ply
		end
	end
	return best_ply
end

-- if SERVER then
-- Entity(1):SetObserverMode(6)
-- end

function attempt_attack(ply, attack_type)
	-- attack_type (int) 1 or 2 for primary and secondary attack respectively
	if IsValid(ply) and IsValid(ply:GetActiveWeapon()) then
		if attack_type == 1 then
			ply:GetActiveWeapon():PrimaryAttack()
		elseif attack_type == 2 then
			ply:GetActiveWeapon():SecondaryAttack()
		end			
	end
end	

if SERVER then
	-- bot behavior
	hook.Add("Think", "BW_bot_behavior", function()
		for i,ply in ipairs(player.GetAll()) do
			if ply:SteamID() != "BOT" then continue end
			local target = get_closest_player(ply)
			if target != nil then
				if IsValid(ply) then
					local r = math.random()
					if r <= 0.01 then -- do leap
						ply:SetEyeAngles((target:GetPos() + Vector(0,0,500) - ply:GetPos()):Angle())
						attempt_attack(ply, 2)
					elseif r <= 0.15 then -- attack
						local posdiff = target:GetPos() - ply:GetPos() + VectorRand(-20,20)
						ply:SetEyeAngles(posdiff:Angle())
						local tr = ply:GetEyeTrace()
						if tr.Entity:IsPlayer() then
							attempt_attack(ply, 1)
							if math.random() < 0.5 then -- 50% chance for bot target to attempt parry
								if target:SteamID() == "BOT" then attempt_attack(target, 2) end
							end
						elseif _get_euc_dist(tr.HitPos, ply:GetPos()) < 10 then -- likely face against wall
							ply:GetActiveWeapon():SecondaryAttack()
						end
					end
				end
			end
		end
		

		-- if IsValid(Entity(3)) and Entity(3):IsPlayer() and IsValid(Entity(3):GetActiveWeapon()) then
		-- 	local r = math.random()
		-- 	if r <= 0.01 then
		-- 		if CurTime() > Entity(3):GetActiveWeapon():GetNextSecondaryFire() then
		-- 			Entity(3):SetEyeAngles((Entity(2):GetPos() + Vector(0,0,500) - Entity(3):GetPos()):Angle())
		-- 			Entity(3):GetActiveWeapon():SecondaryAttack()
		-- 		end
		-- 	elseif r <= 0.15 then
		-- 		if CurTime() > Entity(3):GetActiveWeapon():GetNextPrimaryFire() then
		-- 			local posdiff = Entity(2):GetPos() - Entity(3):GetPos() + VectorRand(-30,30)
		-- 			Entity(3):SetEyeAngles(posdiff:Angle())
		-- 			if Entity(3):GetEyeTrace().Entity:IsPlayer() then
		-- 				Entity(3):GetActiveWeapon():PrimaryAttack()
		-- 				if math.random() < 0.5 then 
		-- 					Entity(2):GetActiveWeapon():SecondaryAttack()
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- end
	end)
	--hook.Remove("Think", "BW_bot_behavior")
end