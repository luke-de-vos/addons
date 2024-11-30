-- original addon: https://steamcommunity.com/sharedfiles/filedetails/?id=1174728266
AddCSLuaFile()

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("1174728266")
else
end

if CLIENT then
   SWEP.PrintName = "AK-47 Gaddafi"
   SWEP.Slot = 2
   SWEP.Icon = "vgui/ttt/ak_47_swag.vtf"
   SWEP.IconLetter = "b"
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "ar2"

SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.Delay = 0.095
SWEP.Primary.Recoil = 1.7
SWEP.Primary.Cone = 0.00025
SWEP.Primary.Damage = 26
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 40
SWEP.Primary.ClipMax = 80
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Sound = Sound( "weapons/ak47/ak47-1-golden.wav" )

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_rif_ak47_gold.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_rif_akau.mdl" )

SWEP.IronSightsPos = Vector( -6.518, -4.646, 2.134 )
SWEP.IronSightsAng = Vector( 2.737, 0.158, 0 )

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

SWEP.HeadshotMultiplier = 4

if CLIENT then
	SWEP.EquipMenuData = {
		name = "AK-47 Gold",
		type = "item_weapon",
		desc = "AK-47 made out of gold. \nHigher damage, more ammo, more killing."
	};
end

SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true