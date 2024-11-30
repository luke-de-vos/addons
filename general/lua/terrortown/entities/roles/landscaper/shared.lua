if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_shank.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(76, 153, 0, 255)

  self.abbr = "scaper" -- abbreviation
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
    traitorButton = 1 -- can use traitor buttons
  }
end

function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_INNOCENT)
end

if SERVER then

  local landscaper_weapon = "weapon_minigun"
  
  function ROLE:GiveRoleLoadout(ply, isRoleChange)
    ply:StripWeapons()
    ply:Give("weapon_zm_improvised")
    ply:Give("weapon_zm_carry")
    ply:Give("weapon_ttt_unarmed")
    ply:Give(landscaper_weapon)
    ply:SelectWeapon(landscaper_weapon)
    _give_current_ammo(ply, 2)
  end

  function ROLE:RemoveRoleLoadout(ply, isRoleChange)
    ply:StripWeapon("landscaper_weapon")
  end

end