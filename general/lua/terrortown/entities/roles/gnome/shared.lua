if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_shank.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(153, 210, 51, 255)

  self.abbr = "gnome" -- abbreviation
  self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
  self.scoreKillsMultiplier = 5 -- multiplier for kill of player of another team
  self.scoreTeamKillsMultiplier = -5 -- multiplier for teamkill
  --self.preventFindCredits         = true
  --self.preventKillCredits         = true
  --self.preventTraitorAloneCredits = true
  self.preventWin                 = false 
  self.unknownTeam                = true
  self.isOmniscientRole           = false 

  self.defaultTeam = TEAM_INNOCENT

  self.conVarData = {
    pct = 0.15, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 5, -- minimum amount of players until this role is able to get selected
    credits = 0, -- the starting credits of a specific role
    shopFallback = SHOP_DISABLED,
    togglable = false, -- option to toggle a role for a client if possible (F1 menu)
    random = 33,
    traitorButton = 0 -- can use traitor buttons
  }
end

function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_INNOCENT)
end


local gnome_model = "models/splinks/gnome_chompski/player_gnome.mdl"
local gnome_view_offset = Vector(0,0,19)
local gnome_view_offset_ducked = Vector(0,0,19)


local function gnomify(ply)
  ply:SetModel(gnome_model) 
  if SERVER then
    ply:SetMaxHealth(25) -- server only
    ply:SetHealth(25) -- server only
  end
  ply:SetNoCollideWithTeammates(true) -- server/client
  ply:SetViewOffset(gnome_view_offset) -- server/client
  ply:SetViewOffsetDucked(gnome_view_offset_ducked) -- server/client
  -- increase move speed
  ply:SetWalkSpeed(220) -- server/client

  --ply:SetJumpPower(300) -- server/client
  --ply:SetHull(Vector(-10,-10,0), Vector(10,10,28)) -- server/client
  --ply:SetHullDuck(Vector(-10,-10,0), Vector(10,10,28)) -- server/client
end


local function ungnomify(ply)
  --ply:SetModel("models/player/alyx.mdl")
  if SERVER then
    ply:SetMaxHealth(100)
    ply:SetHealth(100)
  end
  ply:SetNoCollideWithTeammates(false)
  ply:SetViewOffset(Vector(0,0,64))
  ply:SetViewOffsetDucked(Vector(0,0,28))
  -- increase move speed
  ply:SetWalkSpeed(250)

  -- ply:SetJumpPower(200)
  -- ply:ResetHull()
end

local gnome_weapon = "weapon_ttt_muddy_crowbar"

function ROLE:GiveRoleLoadout(ply, isRoleChange)
  ply:StripWeapons()
  ply:Give(gnome_weapon)
  ply:Give("weapon_zm_carry")
  ply:Give("weapon_ttt_unarmed")
  -- 1/5 chance to get smoke grenade
  if math.random(5) == 1 then
    ply:Give("weapon_ttt_smokegrenade")
    -- alert player that they have a smoke grenade
    ply:PrintMessage(HUD_PRINTTALK, "Smoke up, soldier! You have a smoke grenade!")
  end
  gnomify(ply)
end

function ROLE:RemoveRoleLoadout(ply, isRoleChange)
  ungnomify(ply)
  ply:StripWeapon(gnome_weapon)
end

