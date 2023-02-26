-- https://steamcommunity.com/sharedfiles/filedetails/?id=590909626


if SERVER then

	AddCSLuaFile( "shared.lua" )
	
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_body.vmt")
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_body.vtf")
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_claw.vmt")
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_claw.vtf")
	resource.AddFile("models/katharsmodels/handcuffs/handcuffs-1.mdl")
	resource.AddFile("models/katharsmodels/handcuffs/handcuffs-3.mdl")
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_extras.vmt")
	resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_extras.vtf")
	resource.AddFile("materials/vgui/ttt/icon_handscuffs.png")

end


if CLIENT then
   SWEP.PrintName = "Handcuffs"
   SWEP.Slot = 7

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "To cuff someone ( Can disable Myatrophie )."
   };

   SWEP.Icon = "vgui/ttt/icon_handscuffs.png"

end

SWEP.Base = "weapon_tttbase"
SWEP.Author = "Converted by Porter, dougie"
SWEP.PrintName = "Handcuffs"
SWEP.Purpose = "Bake him away, toys!"
SWEP.Instructions = "Left click target to put cuffs on. Right click target to take cuffs off."
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.HoldType = "normal"   
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 90
SWEP.ViewModel = "models/katharsmodels/handcuffs/handcuffs-1.mdl"
SWEP.WorldModel = "models/katharsmodels/handcuffs/handcuffs-1.mdl"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = { ROLE_DETECTIVE }


SWEP.Primary.NumShots = 1	
SWEP.Primary.Delay = 0.9 	
SWEP.Primary.Recoil = 0	
SWEP.Primary.Ammo = "none"	
SWEP.Primary.Damage = 0	
SWEP.Primary.Cone = 0 	
SWEP.Primary.ClipSize = -1	
SWEP.Primary.DefaultClip = -1	
SWEP.Primary.Automatic = false	


SWEP.Secondary.Delay = 0.9
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots	= 1
SWEP.Secondary.Cone	= 0
SWEP.Secondary.ClipSize	= -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

if SERVER then
	util.AddNetworkString("cuffs_popup")
	function send_cuff_message(ply, message, notify_type)
		net.Start("cuffs_popup")
		net.WriteString(message)
		net.WriteUInt(notify_type, 8)
		net.Send(ply)
	end
end
if CLIENT then
	net.Receive("cuffs_popup", function()
		notification.AddLegacy(net.ReadString(), net.ReadUInt(8), 4)
	end)
end


function SWEP:Reload()
end


function SWEP:Think()
end


if CLIENT then
	function SWEP:GetViewModelPosition( pos, ang )
		ang:RotateAroundAxis( ang:Forward(), 90 ) 
		pos = pos + ang:Forward()*7
		pos:Add(Vector(0,0,-3))
		return pos, ang
	end 
end


function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	if SERVER then
    	self:SetWeaponHoldType(self.HoldType)
	end
end

function SWEP:PrimaryAttack(ply)
	self:SetNextPrimaryFire(CurTime()+0.1)
	local owner = self.Owner
	local trace = { }
	trace.start = self.Owner:EyePos();
	trace.endpos = trace.start + self.Owner:GetAimVector() * 95;
	trace.filter = self.Owner;

	local tr = util.TraceLine( trace );
	local ply = tr.Entity
	local result = ""
	local stripped = {}

	if ply:GetNWBool("DoNotPickUpWeps") == true then
		self.Owner:PrintMessage( HUD_PRINTCENTER, "You can't cuff a Vampire!." );
		return
	end

	-- if SERVER then
	-- 	for k, ply in pairs( player.GetAll() ) do
	-- 		if ply:IsValid() and (ply:IsPlayer() or ply:IsNPC()) then
	-- 			if ply:GetNWBool( "FrozenYay" ) == true then
	-- 				ply:SetNWBool( "FrozenYay", false )
	-- 				ply:SetNWBool( "GotCuffed", true )
	-- 				ply:Give("weapon_zm_improvised")
	-- 				ply:Give("weapon_zm_carry")
	-- 				ply:Give("weapon_ttt_unarmed")
	-- 			end
	-- 		end
	-- 	end
	-- end

	if ( ply:IsValid() and (ply:IsPlayer() or ply:IsNPC()) ) then
		if CLIENT then return end
		if ply:GetNWBool( "GotCuffed" ) == true or ply:GetNWBool( "FrozenYay" ) == true then
			send_cuff_message(self:GetOwner(), ply:Nick().." was already cuffed this round.", 1)
			return
		end
		self:GetOwner():EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)
		timer.Create("cuff_sounds_timer", 0.05, 3, function()
			ply:EmitSound("Weapon_Shotgun.Empty", 100, 100)
		end)
		send_cuff_message(self:GetOwner(), "You cuffed "..ply:Nick()..".", 0)
		send_cuff_message(ply, "You was cuffed.", 0) 

		if not IsValid(self.Owner) then return end
        self.IsWeaponChecking = false

		timer.Create("EndCuffed"..ply:EntIndex(), 30, 1, function()
			if SERVER then
				if ply:IsValid() and (ply:IsPlayer() or ply:IsNPC()) then
					if ply:GetNWBool( "FrozenYay" ) == true then
						timer.Stop("CantPickUp")
						ply:SetNWBool( "FrozenYay", false )
						ply:SetNWBool( "GotCuffed", true )
						ply:Give("weapon_zm_improvised")
						ply:Give("weapon_zm_carry")
						ply:Give("weapon_ttt_unarmed")
						send_cuff_message(ply, "You are released.", 2)
						send_cuff_message(self:GetOwner(), ply:Nick().." served their time.", 2)
					end
				end
			end
		end)

		timer.Create("CantPickUp", 0.01, 0, function()
			ply:SetNWBool( "FrozenYay", true )
			if not IsValid(ply) or not ply:IsPlayer() then return end
			for k, v in pairs( ply:GetWeapons() ) do
				ply:DropWeapon( v )
				local class = v:GetClass()
				if SERVER then
					ply:StripWeapon(class)
					result = result..", "..class
					table.insert(stripped, {class, ply:GetAmmoCount(v:GetPrimaryAmmoType()),
					v:GetPrimaryAmmoType(), ply:GetAmmoCount(v:GetSecondaryAmmoType()), v:GetSecondaryAmmoType(),
					v:Clip1(), v:Clip2()})
				end
			end
		end)
		hook.Add( "PlayerCanPickupWeapon", "noDoublePickup", function( ply, wep )
			if ply:IsValid() and ply:GetNWBool( "FrozenYay" ) == true and ply:GetNWBool( "GotCuffed" ) == false then
				return false
			end
		end )
	end
end
	   

function SWEP:SecondaryAttack(ply)
	if SERVER then
		local owner = self.Owner
		local trace = { }
		trace.start = self.Owner:EyePos();
		trace.endpos = trace.start + self.Owner:GetAimVector() * 95;
		trace.filter = self.Owner;
				
		local tr = util.TraceLine( trace );
		local ply = tr.Entity
		local result = ""
		local stripped = {}

		if ply:IsValid() and ply:IsPlayer() and ply:Alive() then
			if ply:GetNWBool( "FrozenYay" ) == true then
				timer.Stop("CantPickUp")
				ply:SetNWBool( "FrozenYay", false )
				ply:SetNWBool( "GotCuffed", true )
				ply:Give("weapon_zm_improvised")
				ply:Give("weapon_zm_carry")
				ply:Give("weapon_ttt_unarmed")
				self:GetOwner():EmitSound("npc/metropolice/vo/getoutofhere.wav", 50, 100)
				send_cuff_message(ply, "You are released.", 2)
				send_cuff_message(self:GetOwner(), "You released "..ply:Nick()..".", 2)
			elseif ply:GetNWBool( "GotCuffed" ) == false then
				send_cuff_message(self:GetOwner(), ply:Nick().." is not cuffed.", 1)
				return;
			elseif ply:GetNWBool( "GotCuffed" ) == true or ply:GetNWBool( "FrozenYay" ) == false then
				send_cuff_message(self:GetOwner(), ply:Nick().." is not cuffed.", 1)
				return;
			end
		end
	end
end


local function StopCantPickUp1()
	local Players = player.GetAll()
	for i = 1, table.Count(Players) do
    		local ply = Players[i]
    		timer.Stop("EndCuffed")
		timer.Stop("CantPickUp")
		ply:SetNWBool( "GotCuffed", false )
		ply:SetNWBool( "FrozenYay", false )
	end
end
hook.Add("TTTEndRound", "CantPickUpEnd", StopCantPickUp1)


local function StopCantPickUp2()
	local Players = player.GetAll()
	for i = 1, table.Count(Players) do
    		local ply = Players[i]
    		timer.Stop("EndCuffed")
		timer.Stop("CantPickUp")
		ply:SetNWBool( "GotCuffed", false )
		ply:SetNWBool( "FrozenYay", false )
	end
end
hook.Add( "PlayerDisconnected", "playerDisconnected", StopCantPickUp2 )


local function StopCantPickUp3()
	local Players = player.GetAll()
	for i = 1, table.Count(Players) do
    		local ply = Players[i]
    		timer.Stop("EndCuffed")
		timer.Stop("CantPickUp")
		ply:SetNWBool( "GotCuffed", false )
		ply:SetNWBool( "FrozenYay", false )
	end
end
hook.Add( "TTTBeginRound", "CantPickUpEnd2", StopCantPickUp3 )