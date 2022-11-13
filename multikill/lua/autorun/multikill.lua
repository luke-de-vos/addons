print("Executed lua: " .. debug.getinfo(1,'S').source)

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

	local lastKill = {} -- maps player steam IDs to time of last kill
	local multi = {} -- maps player steam IDs to multikill count
	local streak = {} -- maps player steam IDs to num kills since last death

	-- on spawn, reset kill trackers, gain and equip weapons
	hook.Add("PlayerSpawn", "multi_PlayerSpawn", function(ply, transition) 
		lastKill[ply:GetSteamID()] = 0
		multi[ply:GetSteamID()] = 0
		streak[ply:GetSteamID()] = 0
	end)
	
	-- Kill tracking. Streaks, multis
	hook.Add("PlayerDeath", "multi_PlayerDeath", function(victim, inflictor, attacker) -- (Player, Entity, Entity)
	
		streak[victim:GetSteamID()] = 0

		if (attacker:IsPlayer()) then 
			local att = attacker:GetSteamID()
			local vic = victim:GetSteamID()
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