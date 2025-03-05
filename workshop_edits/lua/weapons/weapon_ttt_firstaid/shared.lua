-- original addon: https://steamcommunity.com/sharedfiles/filedetails/?id=711166482
--Converted to TTT by Mka0207 and reworked by BocciardoLight
AddCSLuaFile()

if SERVER then
   resource.AddFile("materials/vgui/ttt/icon_firstaid.png")
   resource.AddWorkshop( "711166482" )
end

-- TTT Convertion Code begin
SWEP.EquipMenuData = {
          type = "Portable First Aid Kit",
          desc = [[
		  Left-Click: 
		  Heal someone for 20HP by clicking on his model
		  	
		  Right-Click: 
		  Heal yourself for 20HP]]
       };
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE,ROLE_TRAITOR }
SWEP.ViewModelFlip = false
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.Icon = "vgui/ttt/icon_firstaid.png"
-- TTT Convertion Code end

SWEP.Spawnable			= true
SWEP.UseHands			= true

SWEP.ViewModel			= "models/weapons/c_medkit.mdl"
SWEP.WorldModel			= "models/weapons/w_medkit.mdl"

SWEP.ViewModelFOV		= 54

SWEP.Primary.ClipSize		= 100
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.PrintName			= "First Aid Kit"
SWEP.Slot				= 7
SWEP.SlotPos			= 3

SWEP.HealAmount = 20

local HealSound = Sound( "vo/npc/male01/health04.wav" )
local DenySound = Sound( "items/medshotno1.wav" )

function SWEP:Initialize()

	self:SetWeaponHoldType( "slam" )

	local regen_time = 1 --Increased Recharge

	timer.Create( "medkit_ammo" .. self:EntIndex(), regen_time, 0, function() 
		if ( !IsValid( self.Owner ) ) then return end
		if ( self:Clip1() < 100 ) then self:TakePrimaryAmmo( -1 ) end
	end )

end

function SWEP:PrimaryAttack()

	if ( !SERVER ) then return end

	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 64,
		filter = self.Owner
	} )

	local ent = tr.Entity

	if ( IsValid( ent ) && self:Clip1() >= self.HealAmount && ( ent:IsPlayer() || ent:IsNPC() ) && ent:Health() < ent:GetMaxHealth() ) then

		self:TakePrimaryAmmo( self.HealAmount )

		ent:SetHealth( math.min( ent:GetMaxHealth(), ent:Health() + self.HealAmount ) )
		ent:EmitSound( "vo/npc/male01/health04.wav"  )
		

		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

		self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() + 0.2 )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )

		-- Even though the viewmodel has looping IDLE anim at all times, we need this ti make fire animation work in multiplayer
		timer.Simple( self:SequenceDuration(), function() if ( !IsValid( self ) ) then return end self:SendWeaponAnim( ACT_VM_IDLE ) end )

	else

		self.Owner:EmitSound( DenySound )
		--self.Weapon:EmitSound( TauntSound )
		self:SetNextPrimaryFire( CurTime() + 1 )

	end

end

function SWEP:SecondaryAttack()

	if ( !SERVER ) then return end

	local ent = self.Owner

	if ( IsValid( ent ) && self:Clip1() >= self.HealAmount && ent:Health() < ent:GetMaxHealth() ) then

		self:TakePrimaryAmmo( self.HealAmount )

		ent:SetHealth( math.min( ent:GetMaxHealth(), ent:Health() + self.HealAmount ) )
		local pitch = 
		ent:EmitSound( "vo/npc/female01/pain06.wav", 75, math.random( 60, 100 ), 0.5)

		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

		self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() + 1 )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )

		timer.Simple( self:SequenceDuration(), function() if ( !IsValid( self ) ) then return end self:SendWeaponAnim( ACT_VM_IDLE ) end )

	else

		ent:EmitSound( DenySound )
		self:SetNextSecondaryFire( CurTime() + 1 )

	end

end

function SWEP:OnRemove()

	timer.Stop( "medkit_ammo" .. self:EntIndex() )

end

function SWEP:CustomAmmoDisplay()

	self.AmmoDisplay = self.AmmoDisplay or {} 
	self.AmmoDisplay.Draw = true
	self.AmmoDisplay.PrimaryClip = self:Clip1()

	return self.AmmoDisplay

end

/*---------------------------------------------------------
	Reload Sound
---------------------------------------------------------*/
function SWEP:Reload()	

end

