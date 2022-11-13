AddCSLuaFile()
SWEP.PrintName = "Swamp Knife"
SWEP.Category = "dougie's SWEPs"
SWEP.Author = "dev douglas"
SWEP.Contact = ""
SWEP.Purpose = "Shanking."
SWEP.Instructions = "Primary: shank, Secondary: vanish"

SWEP.Spawnable = true
SWEP.AdminSpawnable = false
SWEP.AdminOnly = false

SWEP.ViewModelFOV = 60
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.ViewModelFlip = false
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {}
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.EquipMenuData = {
    type = "shank",
    desc = "Shank them in the back for an instant kill."
}

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR, ROLE_INNOCENT} -- only traitors can buy
SWEP.LimitedStock = true -- only buyable once
SWEP.IsSilent = true
SWEP.DeploySpeed = 2
SWEP.NoSights = true
SWEP.AutoSpawnable = false
SWEP.Icon = "vgui/ttt/icon_knife"
SWEP.IconLetter = "c"
SWEP.InLoadoutFor = nil

if SERVER then
    resource.AddFile("materials/vgui/ttt/icon_knife.vmt")
end

SWEP.Slot = 8
SWEP.SlotPos = 1

SWEP.UseHands = true
SWEP.HoldType = "knife" -- https://wiki.facepunch.com/gmod/Hold_Types

SWEP.FiresUnderwater = true
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.ReloadSound = ""
SWEP.Base = "weapon_tttbase"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "None"

SWEP.Secondary.ClipSize = 0
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Ammo = "None"

local AnnounceSound = Sound("shank/dontgetshanked.wav");
local AttackSound = Sound("shank/attack1.wav");
local Attack2Sound = Sound("shank/hyuking.wav");
local ReloadSound = Sound("shank/toldya.wav");

local DEFAULT_WALK_SPEED = 250


-- function SWEP:Deploy()
	-- if CLIENT then
		-- surface.PlaySound("shank/dontgetshanked.wav")
	-- end
-- end

function SWEP:PrimaryAttack()

    if not (self.Weapon:GetNextPrimaryFire() < CurTime()) then 
		return
	end

    local vm = self.Owner:GetViewModel()
    local tr = self.Owner:GetEyeTrace()
	local hitEnt = nil
	
    if (tr.HitPos - self.Owner:GetShootPos()):Length() < 80 then

		hitEnt = tr.Entity

		if IsValid(hitEnt) then
			-- destroy body
			if SERVER then
				--self:EmitSound("Weapon_FlareGun.Single")
				if hitEnt:GetClass() == "prop_ragdoll" then
					self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
					self:SetNextPrimaryFire(CurTime() + 0.8)
					hitEnt:Remove()
				end
				-- stab and kill
				if hitEnt:IsPlayer() then 
					
					self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
					self:SetNextPrimaryFire(CurTime() + 0.8)

					-- get hit angle on victim
					local angle = self.Owner:GetAngles().y - tr.Entity:GetAngles().y
					if angle < -180 then
						angle = angle + 360
					end
					
					local dmginfo = DamageInfo()
					if angle <= 90 and angle >= -90 then -- if backstab then
						dmginfo:SetDamage(200)
						vm = self.Owner:GetViewModel() -- edit: pointless?
					else
						dmginfo:SetDamage(100)
					end
					dmginfo:SetDamageType(DMG_SLASH)
					dmginfo:SetAttacker(self.Owner)
					dmginfo:SetInflictor(self)
					tr.Entity:TakeDamageInfo(dmginfo)
					_slash_effect(tr.Entity)
				end
			end
		end
        
		if SERVER then
			self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
		end
	end
end

function SWEP:SecondaryAttack()
	local VANISH_COOLDOWN = 5
	if CurTime() > self.Weapon:GetNextSecondaryFire() then 
		Vanish(self.Owner)
		self:SetNextSecondaryFire(CurTime() + VANISH_COOLDOWN)
	end
end

function splash_effect(ply)
	local edata = EffectData()
	edata:SetOrigin(ply:GetPos())
	edata:SetScale(10)
	util.Effect("watersplash", edata)
end

function Vanish(ply)
	print(ply:GetActiveWeapon():GetPrintName())
	VANISH_TIME = 2 -- seconds
	ply:SetWalkSpeed(ply:GetWalkSpeed() * 1.8)
	ply:SetFOV(ply:GetFOV()*1.2, 0.3, ply)
	splash_effect(ply)
	ply:SetMaterial("effects/blood") -- make model invisible
	ply:GetActiveWeapon():SetMaterial("effects/blood")
	--ply:DrawShadow(false)

	local timer_name = "vanish_timer_"..ply:SteamID()
	timer.Remove(timer_name)
	timer.Create(timer_name, VANISH_TIME, 1, function()
		Unvanish(ply)
	end)
end

function Unvanish(ply)
	ply:SetWalkSpeed(DEFAULT_WALK_SPEED)
	if ply:GetMaterial() == "effects/blood" then
		ply:SetMaterial("") -- make model visible
		ply:GetActiveWeapon():SetMaterial("")
		ply:DrawShadow(true)
		splash_effect(ply)
		ply:SetFOV(0, 0.3, ply)
	end
end

function SWEP:Reload()
	
end

function SWEP:PreDrop()
    -- for consistency, dropped knife should not have DNA/prints
    self.fingerprints = {}
	Unvanish(self.Owner)
end

function SWEP:OnRemove()
	
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
	end
end