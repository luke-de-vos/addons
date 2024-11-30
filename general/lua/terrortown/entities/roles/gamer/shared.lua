if SERVER then
  AddCSLuaFile()
  --resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_shank.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(200, 200, 150, 255)

  self.abbr = "gamer" -- abbreviation
  self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
  self.scoreKillsMultiplier = 0 -- multiplier for kill of player of another team
  self.scoreTeamKillsMultiplier = 0 -- multiplier for teamkill
  --self.preventFindCredits         = true
  --self.preventKillCredits         = true
  --self.preventTraitorAloneCredits = true
  self.preventWin                 = false
  self.unknownTeam                = true
  self.isOmniscientRole           = false

  self.defaultTeam = TEAM_INNOCENT

  self.conVarData = {
    pct = 0.00, -- necessary: percentage of getting this role selected (per player)
    maximum = 32, -- maximum amount of roles in a round
    minPlayers = 1, -- minimum amount of players until this role is able to get selected
    credits = 10, -- the starting credits of a specific role
    shopFallback = SHOP_DISABLED,
    togglable = false, -- option to toggle a role for a client if possible (F1 menu)
    random = 0,
    traitorButton = 0 -- can use traitor buttons
  }
end

function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_INNOCENT)
end

if SERVER then
  
  function ROLE:GiveRoleLoadout(ply, isRoleChange)
    
  end

  function ROLE:RemoveRoleLoadout(ply, isRoleChange)
  
  end

end