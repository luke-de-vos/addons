print("Executed lua: " .. debug.getinfo(1,'S').source)
local addon_hooks = {} -- populated with tuples containing type and name of hooks. These are referenced to remove appropriate hooks when addon is disabled

-- config
local MULTI_WINDOW = 4 -- max seconds between kills to get multikill
local MULTI_NAMES = {"Double Kill!", "Triple Kill!", "Overkill!", "Killtacular!", "Killtrocity!", "Killamanjaro!", "Killtastrophe!", "Killpocalypse!", "Killionaire!"}
local MULTI_SOUNDS = {"double_kill.wav", "triple_kill.wav", "overkill.wav", "killtacular.wav", "killtrocity.wav", "killimanjaro.wav", "killtastrophe.wav", "killpocalypse.wav", "killionaire.wav"}

for i, entry in ipairs(MULTI_SOUNDS) do
	resource.AddFile("sound/"..entry)
	print("Added "..entry)
end

if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("multi_popup")
	addon_hooks = {} -- reset

	local lastKill = {} -- maps player names to time of last kill
	local multi = {} -- maps player names to multikill count
	local streak = {} -- maps player names to num kills since last death

	-- on spawn, reset kill trackers, gain and equip weapons
	table.insert(addon_hooks, {"PlayerSpawn", "multi_PlayerSpawn"})
	hook.Add("PlayerSpawn", "multi_PlayerSpawn", function(ply, transition) 
	
		lastKill[ply:GetName()] = 0
		multi[ply:GetName()] = 0
		streak[ply:GetName()] = 0
		
	end)
	
	-- Kill tracking. Streaks, multis
	table.insert(addon_hooks, {"PlayerDeath", "multi_PlayerDeath"})
	hook.Add("PlayerDeath", "multi_PlayerDeath", function(victim, inflictor, attacker) -- (Player, Entity, Entity)
	
		streak[victim:GetName()] = 0
	
		if (attacker:IsPlayer()) then 
				
			local att = attacker:GetName()
			local vic = victim:GetName()
			
			if att ~= vic then
		
				--streak
				streak[att] = streak[att] + 1
				if (streak[att] % 5 == 0) then
					Entity(attacker:EntIndex()):ChatPrint("Streak:" .. streak[att])
				end
			
				--multikill
				if (CurTime() - lastKill[att] < MULTI_WINDOW) then
					if (multi[att] < #MULTI_NAMES) then
						multi[att] = multi[att] + 1
					end
					net.Start("multi_popup")
					net.WriteInt(multi[att], 32) -- second arg is number of bits to repesent int with
					net.Send(attacker)
				else
					multi[att] = 0
				end
				lastKill[att] = CurTime()
				
			end
			
		end
	
	end)
end


if CLIENT then
	net.Receive("multi_popup", function()
		local multi_no = net.ReadInt(32)
		notification.AddLegacy(MULTI_NAMES[multi_no], NOTIFY_UNDO, MULTI_WINDOW)
		surface.PlaySound(MULTI_SOUNDS[multi_no])
	end)
	-- net.Receive("headshot_sound", function()
		-- surface.PlaySound()
	-- end)
end