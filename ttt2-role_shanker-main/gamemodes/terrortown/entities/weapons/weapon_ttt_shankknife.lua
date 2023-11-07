-- original addon: https://steamcommunity.com/sharedfiles/filedetails/?id=2708179435
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
local AttackSound = Sound("Weapon_357.Single");
local Attack2Sound = Sound("shank/hyuking.wav");
local ReloadSound = Sound("shank/toldya.wav");

local DEFAULT_WALK_SPEED = 250


function SWEP:PrimaryAttack()

    if not (self.Weapon:GetNextPrimaryFire() < CurTime()) then 
		return
	end

    local tr = self.Owner:GetEyeTrace()
	
    if (tr.HitPos - self.Owner:GetShootPos()):Length() < 70 then

		local hitEnt = tr.Entity

		if IsValid(hitEnt) then
			local did_stab = false
			-- stab and kill
			local dmginfo = DamageInfo()
			dmginfo:SetDamageType(DMG_SLASH)
			dmginfo:SetAttacker(self.Owner)
			dmginfo:SetInflictor(self)
			Unvanish(self:GetOwner())
			self:SetNextPrimaryFire(CurTime() + 0.8)
			if hitEnt:GetClass() == "prop_ragdoll" then
				did_stab = true
				if SERVER then
					--timer.Simple(0.1, function() self:EmitSound("npc/combine_soldier/vo/slash.wav", 75, 100, 1, CHAN_AUTO) end)
					--hitEnt:Remove()
					_slash_effect(tr.Entity)
				end
			elseif hitEnt:IsPlayer() then
				did_stab = true
				if SERVER then
					dmginfo:SetDamage(100)
					dmginfo:SetDamageForce((self:GetOwner():GetAimVector()*10))
					tr.Entity:TakeDamageInfo(dmginfo)
					_slash_effect(tr.Entity)
				end
			elseif string.match(hitEnt:GetClass(), '.*door.*') then
				did_stab = true
				if SERVER then
					timer.Simple(0.1, function() self:EmitSound("plats/tram_hit4.wav", 75, 100, 0.5, CHAN_AUTO) end) 
					dmginfo:SetDamage(200)
					dmginfo:SetDamageForce((self:GetOwner():GetAimVector()*50))
					tr.Entity:TakeDamageInfo(dmginfo)
				end
			end
			if did_stab then
				self:GetOwner():DoAttackEvent()
				self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
				self:EmitSound("Weapon_Crowbar.Single", 50, 100, 0.3, CHAN_BODY)
			end
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
	local VANISH_TIME = 2 -- seconds
	ply:SetWalkSpeed(ply:GetWalkSpeed() * 1.8)
	ply:SetFOV(ply:GetFOV()*1.2, 0.3, ply)
	splash_effect(ply)
	ply:SetMaterial("effects/blood") -- make model invisible
	ply:GetActiveWeapon():SetMaterial("effects/blood")
	ply:DrawShadow(false)
	hook.Add("EntityTakeDamage", ply:SteamID().."vanish", function(vic, dmg)
		if vic:EntIndex() == ply:EntIndex() then
			dmg:ScaleDamage(5)
		end
	end)

	local timer_name = "vanish_timer_"..ply:EntIndex()
	timer.Remove(timer_name)
	timer.Create(timer_name, VANISH_TIME, 1, function()
		Unvanish(ply)
	end)
end

function Unvanish(ply)
	ply:SetWalkSpeed(DEFAULT_WALK_SPEED)
	hook.Remove("EntityTakeDamage", ply:SteamID().."vanish")
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

local shanker_weapons = {
	["weapon_ttt_shankknife"] = true,
	["weapon_ttt_smokegrenade"] = true,
	["weapon_ttt_confgrenade"] = true,
	["weapon_zm_molotov"] = true
}

hook.Remove("PlayerSwitchWeapon", "RestrictWeaponSwitch")

function SWEP:Deploy()
	if CLIENT and self:GetOwner() == LocalPlayer() then
		hook.Add("PreDrawHalos", "AddPlayerOutlines", function()
			local players = {}
			for _, ply in ipairs(player.GetAll()) do
				if !ply:Alive() then continue end
				if ply == LocalPlayer() then continue end
				if ply:GetVelocity():Length() > 150 then 
					table.insert(players, ply)
				end
			end
			halo.Add(players, Color(255, 0, 0, 255), 2, 2, 2, true, true)
		end)
	else
		-- hook.Add("PlayerSwitchWeapon", "RestrictWeaponSwitch", function(ply, oldWep, newWep)
		-- 	if ply == self:GetOwner() then
		-- 		if shanker_weapons[newWep:GetClass()] == nil then
		-- 			return true 
		-- 		end
		-- 	end
		-- end)
		--hook.Remove("PlayerSwitchWeapon", "RestrictWeaponSwitch")
	end
    return true  
end

function SWEP:Holster()
	if CLIENT then
    	hook.Remove("PreDrawHalos", "AddPlayerOutlines")
	end
    return true  -- Return true to allow the holstering
end

hook.Remove("PreDrawHalos", "AddPlayerOutlines")


