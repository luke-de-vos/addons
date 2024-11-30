-- https://steamcommunity.com/sharedfiles/filedetails/?id=356664308

AddCSLuaFile()
SWEP.Base = "weapon_tttbase"

if SERVER then
	resource.AddFile("materials/melon/ttt_derchecker07_melonlauncher_icon.png")
	resource.AddFile("sound/weapons/melon_launcher/launch.wav")
end

SWEP.ViewModel = "models/weapons/v_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands = true

SWEP.PrintName = "Melon Launcher"
SWEP.Author = "derchecker07 + dev douglas"


SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 6
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.HoldType = "rpg"
SWEP.Primary.Sound = Sound("weapons/melon_launcher/launch.wav")


SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "RPG_Rocket"
SWEP.Primary.Recoil = 5 
SWEP.Primary.Damage = 78
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipMax = 1


--------------------TTT Stuff--------------------
SWEP.EquipMenuData = {
	type = "Weapon",
	desc = "Shoots an explosive melon\n to kill many innocents\n at the same place."
};

SWEP.Icon = "melon/ttt_derchecker07_melonlauncher_icon.png"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = { ROLE_TRAITOR, ROLE_GAMER}
SWEP.LimitedStock = true
SWEP.AllowDrop = true

function SWEP:IsEquipment() return true end
--------------------END TTT Stuff--------------------


--------------------Methods--------------------
function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
end


function SWEP:PrimaryAttack()

	if self:CanPrimaryAttack() then
		self:TakePrimaryAmmo(1)
		self.Weapon:SetNextPrimaryFire( CurTime() + 1)	
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		
		if (SERVER) then
			-- sound only plays if slighlty delayed for some reason
			timer.Simple(0.01, function() 
				if IsValid(self) then 
					self:EmitSound(self.Primary.Sound) 
				end
			end)
			local ang = self.Owner:EyeAngles() 
			local ent = ents.Create( "ent_explosive_melon" )
			if ( IsValid( ent ) ) then
				ent:SetPos( self.Owner:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1 )
				ent:SetAngles( ang )
				ent:SetOwner( self.Owner )
				ent:Spawn()
				ent:Activate()
			end  
		end
	else
		self:EmitSound("weapons/clipempty_pistol.wav")
	end
		
 end
 
 
function SWEP:SecondaryAttack()
end



function SWEP:ShouldDropOnDie()
   return false
end
--------------------END Methods--------------------