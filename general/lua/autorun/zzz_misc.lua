print("Executed lua: " .. debug.getinfo(1,'S').source)

-- arm damage
if SERVER then
	hook.Add("ScalePlayerDamage", "arm_damage3", function(ply, hitgroup, dmginfo) 
		if (hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM) then
			dmginfo:ScaleDamage(1.845) -- set arm damage equal to body damage
		 end
	end)
end

-- spawn geagle(s). alert player when picked up
if SERVER then
	function spawn_geag() 
		local options = {}
		-- delay spawn by 120 seconds
		timer.Simple(120, function()
			for i, ent in ipairs(ents.GetAll()) do
				if ent:IsWeapon() then
					table.insert(options, ent:GetPos())
				end
			end
			if #options >= 1 then
				local geagle = ents.Create("weapon_ttt_powerdeagle")
				geagle:SetPos(options[math.random(#options)] + Vector(0,0,30))
				geagle:Spawn()
			end
		end)
	end
	function geag_alert(wep, owner)
		if wep:GetClass() == "weapon_ttt_powerdeagle" then
			owner:ChatPrint("GOLDEN DEAG EQUIPPED")
			owner:ChatPrint("Handle with care, soldier.")
		end
	end
	--hook.Add("TTTBeginRound", "spawn_1_geagle", spawn_geag)
	--hook.Add("WeaponEquip","geag_alert", geag_alert)
	--hook.Remove("TTTBeginRound", "spawn_1_geagle")
	--hook.Remove("WeaponEquip","geag_alert")
end


-- hitmarker sound
if SERVER then
    resource.AddFile("sound/hit.wav")
    util.AddNetworkString("zz_hitmarker_sound_msg")
    hook.Add("EntityTakeDamage", "zz_hitmarker_sound", function(vic, dmg)
        if vic:IsPlayer() and dmg:GetAttacker():IsPlayer() then
            if dmg:GetDamage() >= 1 then -- this doesn't work
                net.Start("zz_hitmarker_sound_msg")
                net.Send(dmg:GetAttacker())
            end
        end
    end)
end
if CLIENT then
    net.Receive("zz_hitmarker_sound_msg", function()
		surface.PlaySound("hit.wav")
	end)
end


if CLIENT then
	-- show speed
	local recent_max = 0
	local recent_max_set_at = 0
	local recent_window = 5 --seconds
	hook.Add("DrawOverlay", "draw_speed_hook", function()
		if IsValid(LocalPlayer()) then
			local vel = LocalPlayer():GetVelocity()
			vel = math.Round(math.sqrt((vel.x^2+vel.y^2+vel.z^2)) / 27.119, 1)
			if vel >= 12 then
				draw.DrawText(vel.." mph", "DermaDefault", 288, 45, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(vel.." mph", "DermaDefault", 287, 44, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
			if vel > recent_max then
				recent_max_set_at = CurTime()
				recent_max = vel
			end
			if CurTime() - recent_max_set_at >= recent_window then
				recent_max = 0
			end
			if recent_max >= 12 then
				draw.DrawText(recent_max.." mph", "DermaDefault", 289, 66, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 288, 65, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 287, 64, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
		end
	end)

	-- show distance to target
	hook.Add("DrawOverlay", "dist_to_target_hook", function()
		if IsValid(LocalPlayer()) and input.IsMouseDown(MOUSE_RIGHT) then
			local trace = LocalPlayer():GetEyeTrace()
			if !trace.HitSky then
				local dist = math.Round(LocalPlayer():EyePos():Distance(trace.HitPos) / 12, 1)
				draw.DrawText(dist.." ft", "DermaDefault", 288, 87, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(dist.." ft", "DermaDefault", 287, 86, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			else
				draw.DrawText("-- ft", "DermaDefault", 288, 87, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText("-- ft", "DermaDefault", 287, 86, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
		end
	end)
end

-- cleanup command
hook.Add("PlayerSay", "custom_command_remove_ents", function(sender, text, teamChat)
	if sender:GetUserGroup() ~= "user" then
		if text == "!cleanup" then
			for i,ent in ipairs(ents.GetAll()) do
				local cla = ent:GetClass()
				if cla == "prop_physics" or cla == "prop_dynamic" then
					ent:Remove()
				elseif ent:IsWeapon() and !ent:GetOwner():IsValid() then
					ent:Remove()
				end
			end
		end
	end
end)


-- MAKE EXPLOSION
if SERVER then
	function CreateExplosionAtPosition(pos)
		-- Check if the provided position is valid
		if not pos or not isvector(pos) then
			print("Invalid position.")
			return
		end

		-- Create an explosion entity
		local explosion = ents.Create("env_explosion") 
		if not IsValid(explosion) then 
			print("Failed to create explosion.")
			return
		end

		-- Set explosion attributes
		explosion:SetPos(pos)  
		explosion:Spawn()

		-- Configure the explosion
		explosion:SetKeyValue("iMagnitude","200") 

		-- Trigger the explosion
		explosion:Fire("Explode", "", 0)
		explosion:EmitSound("weapon_AWP.Single", 400, 400 ) 
	end

	-- Example usage:
	-- Replace Vector(0, 0, 0) with your desired position
end


-- SFX FOR KNIFE KILLS
if SERVER then
	local knife_stab_sound = Sound("physics/flesh/flesh_strider_impact_bullet1.wav")
    hook.Add("DoPlayerDeath", "SoundForKnifeKill", function(victim, attacker, dmginfo)
		local inflictor = dmginfo:GetInflictor()
		if IsValid(inflictor) then
			if inflictor.ClassName == "weapon_ttt_knife" or inflictor.ClassName == "ttt_knife_proj" then
				victim:EmitSound(knife_stab_sound, 62, 120, 1)
			end
		end
    end)
end


-- on DoPlayerDeath, remove magneto stick and crowbar from player
if SERVER then
	hook.Add("DoPlayerDeath", "RemoveMagnetoStickAndCrowbar", function(victim, attacker, dmginfo)
		victim:StripWeapon("weapon_zm_improvised")
		victim:StripWeapon("weapon_zm_carry")
	end)
end




/*
trail texture options:
list.Set( "trail_materials", "#trail.plasma", "trails/plasma" )
list.Set( "trail_materials", "#trail.tube", "trails/tube" )
list.Set( "trail_materials", "#trail.electric", "trails/electric" )
list.Set( "trail_materials", "#trail.smoke", "trails/smoke" )
list.Set( "trail_materials", "#trail.laser", "trails/laser" )
list.Set( "trail_materials", "#trail.physbeam", "trails/physbeam" )
list.Set( "trail_materials", "#trail.love", "trails/love" )
list.Set( "trail_materials", "#trail.lol", "trails/lol" )
		["ttt_firegrenade_proj"] = true,
		["ttt_smokegrenade_proj"] = true,
		["ttt_confgrenade_proj"] = true,
*/

-- GRENADE TRACERS AND SOUNDS
if SERVER then
	local grenadeTypes = {
		["ttt_frag_proj"] = true,
		["ttt_firegrenade_proj"] = true,
		["ttt_smokegrenade_proj"] = true,
		["ttt_confgrenade_proj"] = true,
	}
	hook.Add("OnEntityCreated", "TrackGrenadeThrows", function(ent)
		if ent:GetClass() == "ttt_frag_proj" then
			util.SpriteTrail(
				ent, 0, Color(255, 0, 0), false, 10, 1, 0.3, 1/(10+1)*0.5, "trails/laser"
			)
			-- make the grenade beep
			timer.Create("beep_timer_"..ent:EntIndex(), 0.25, 20, function()
				if !IsValid(ent) then return end
				ent:EmitSound("buttons/blip1.wav", 70, 200, 0.8, CHAN_AUTO)
			end)
		end
		if grenadeTypes[ent:GetClass()] then
			-- play throw sound effect
			ent:EmitSound("WeaponFrag.Throw", 50, 100, 0.3, CHAN_BODY)
		end
	end)
end


-- DROP WEAPON SOUND EFFECT
if SERVER then
	hook.Add("PlayerDroppedWeapon", "sfx_drop_hook", function(owner, wep)
		owner:EmitSound("WeaponFrag.Roll", 20, 120, 0.7, CHAN_AUTO)
	end)
end


-- print the number of players with each role at the start of each round
if SERVER then
	hook.Add("TTTBeginRound", "PrintPlayerRoles", function()

		print("======")
		print("ROLES")
		local roleCounts = {}  -- Table to hold the count of each role

		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) then
				local role = ply:GetRoleString()  -- Assuming GetRoleString gets the role name as a string
				roleCounts[role] = (roleCounts[role] or 0) + 1  -- Increment the count for this role
			end
		end

		-- Print the count of each role
		for role, count in pairs(roleCounts) do
			print(count.." "..role)
		end
		print("======")
	end)
end


-- GIVE ME COMMAND
if SERVER then
	concommand.Add("giveme", function(ply, cmd, args)
		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end 
		local weapon_class = args[1]
		local success = ply:Give(weapon_class)
		print("giveme "..ply:GetName().." "..weapon_class)
	end)
	-- add command to spawn Entity(2) at Entity(1)'s aimvector hitpos
	concommand.Add("spawnat", function(ply, cmd, args)
		if not IsValid(ply) then return end
		if not ply:IsAdmin() then return end 
		local ent_id = args[1]
		local ent = Entity(ent_id)
		ent:EmitSound("WeaponFrag.Roll", 50, 120, 0.7, CHAN_AUTO)
		ent:SetPos(ply:GetEyeTrace().HitPos)
		ent:EmitSound("WeaponFrag.Roll", 50, 120, 0.7, CHAN_AUTO)
		-- play spark effect at original pos and hit pos
		local effectdata = EffectData()
		effectdata:SetOrigin(ent:GetPos())
		effectdata:SetStart(ent:GetPos())
		util.Effect("ElectricSparks", effectdata)
		effectdata:SetOrigin(ent:GetEyeTrace().HitPos)
		effectdata:SetStart(ent:GetEyeTrace().HitPos)
		util.Effect("ElectricSparks", effectdata)
	end)
	
end




if CLIENT then
	-- Global table to hold sphere data
	local spheresToDraw = {}

	-- Function to add a sphere to the drawing queue
	function AddSphere(origin, radius, duration)
		table.insert(spheresToDraw, {
			origin = origin,
			radius = radius,
			duration = CurTime() + duration, -- Duration in seconds
			color = Color(150, 150, 150, 50) -- Default color (white, semi-transparent)
		})

	end

	-- Hook for drawing spheres
	hook.Add("PostDrawOpaqueRenderables", "DrawSpheres", function()
		for i = #spheresToDraw, 1, -1 do
			local sphere = spheresToDraw[i]

			if CurTime() > sphere.duration then
				table.remove(spheresToDraw, i) -- Remove expired spheres
			else
				render.SetColorMaterial()
				render.DrawSphere(sphere.origin, sphere.radius, 8, 8, sphere.color, true)
			end
		end
	end)

	-- Example usage
	-- AddSphere(Vector(0, 0, 100), 25, 10) -- A sphere with a radius of 25 units at position (0, 0, 100) lasting 10 seconds
end


-- -- print weapon stats to screen
-- if CLIENT then

-- 	local stats_keys = {"Damage", "Headshot", "Spread", "Recoil", "ROF", "Ammo Type"}
-- 	local stats = {}

-- 	local border = 5
-- 	local shift = 15
-- 	local box_height = #stats_keys * shift

-- 	local box_title_color = Color(100,100,200,180)
-- 	local box_body_color = Color(20, 20, 20,135)

-- 	local box_x = nil
-- 	local box_y = nil

-- 	local yOffset = nil

-- 	-- when local player equips any weapon
-- 	hook.Add("HUDPaint", "DrawWeaponStats", function()
-- 		local ply = LocalPlayer()
-- 		if not IsValid(ply) then return end

-- 		local weapon = ply:GetActiveWeapon()
-- 		if IsValid(weapon) then
-- 			stats = {
-- 				tostring(weapon.Primary.Damage),
-- 				tostring(weapon.HeadshotMultiplier).."x",
-- 				tostring(math.Round(math.pow(weapon.Primary.Cone*100, 2) * 3.14, 2)),
-- 				weapon.Primary.Recoil,
-- 				tostring(math.Round(1/weapon.Primary.Delay, 2)).." rps",
-- 				weapon.Primary.Ammo,
-- 			}

-- 			box_x = ScrW() * 0.8
-- 			box_y = ScrH() * 0.95 - box_height
			
-- 			-- draw boxes
-- 			surface.SetDrawColor(box_title_color)
-- 			surface.DrawRect(box_x - border, box_y, 230, shift)
-- 			surface.SetDrawColor(box_body_color)
-- 			surface.DrawRect(box_x - border, box_y + shift, 230, box_height + border)

-- 			-- draw text
-- 			yOffset = shift
-- 			draw.SimpleText(weapon.ClassName, "TargetID", box_x, box_y + yOffset, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
-- 			for i, key in ipairs(stats_keys) do
-- 				yOffset = yOffset + shift
-- 				draw.SimpleText(key, "TargetID", box_x, box_y + yOffset, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
-- 				draw.SimpleText(tostring(stats[i]), "TargetID", box_x + 105, box_y + yOffset, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
-- 			end

-- 		else
-- 			stats = {}
-- 		end


-- 	end)

-- end



-- head size changer
if SERVER then
	concommand.Add("scale_head", function( ply, cmd, args )
		if !IsValid(ply) then return end
		-- player can only increase head size
		if tonumber(args[1]) < 1 then return end
		
		local boneID = ply:LookupBone("ValveBiped.Bip01_Head1")
		local scale = tonumber(args[1])
		ply:ManipulateBoneScale(boneID, Vector(1,1,1) * scale)
	end)
end



-- -- play sound effect with G
-- local gobble_message_name = "gobble_message"
-- if CLIENT then
-- 	local next_sound_time = 0
-- 	local sound_cooldown = 0.5 --seconds
-- 	hook.Add("Think" , "sound_think", function()
-- 		if input.IsButtonDown(KEY_G) then
-- 			if CurTime() > next_sound_time and LocalPlayer():Alive() then
-- 				net.Start(gobble_message_name)
-- 				net.WriteInt(LocalPlayer():EntIndex(), 16)
-- 				net.SendToServer()
-- 				next_sound_time = CurTime() + sound_cooldown
-- 			end
-- 		end
-- 	end)
-- 	--hook.Remove("Think" , "sound_think")
-- end
-- if SERVER then
-- 	resource.AddFile("sound/hohoho.mp3")
-- 	util.AddNetworkString(gobble_message_name)
-- 	net.Receive(gobble_message_name, function()
-- 		Entity(net.ReadInt(16)):EmitSound(Sound("hohoho.mp3"), 80, 100, 1)
-- 	end)
-- end






-- -- HUP
-- resource.AddFile("sound/h1.mp3")
-- resource.AddFile("sound/h2.mp3")
-- local hup_table = {"h1.mp3", "h2.mp3"}
-- local hup_message_name = "hup_message"
-- if CLIENT then
-- 	local hook_type= "Think"
-- 	local hook_name = "hup_think"
-- 	local next_hup_time = 0
-- 	local hup_cooldown = 1 --seconds
-- 	hook.Add(hook_type, hook_name, function()
-- 		if input.IsButtonDown(KEY_H) then
-- 			if CurTime() > next_hup_time then
-- 				net.Start(hup_message_name)
-- 					net.WriteInt(LocalPlayer():EntIndex(), 16)
-- 					net.SendToServer()
-- 				next_hup_time = CurTime() + hup_cooldown
-- 			end
-- 		end
-- 	end)
-- 	--hook.Remove(hook_type, hook_name)
-- end
-- if SERVER then
-- 	util.AddNetworkString(hup_message_name)
-- 	net.Receive(hup_message_name, function()
-- 		Entity(net.ReadInt(16)):EmitSound(hup_table[math.random(#hup_table)], 60, 100, 1)
-- 	end)
-- end



-- if SERVER then
-- 	-- Global table to hold references to trail entities
-- 	local trailEntities = {}

-- 	concommand.Add("givetrail", function(ply, cmd, args)
-- 		local ent = ply:GetActiveWeapon()
-- 		if not IsValid(ent) then return end  -- Check if entity(1) is valid

-- 		local sw = 10
-- 		local ew = 1
-- 		local lifetime = 1.5
-- 		local attachment_id = 0
-- 		local trail_name = "trails/laser"

-- 		-- Create and store the trail entity
-- 		local trail = util.SpriteTrail()
-- 			ent, attachment_id, Color(255, 0, 0), false, sw, ew, lifetime, 1/(sw+ew)*0.5, trail_name
-- 		)
-- 		table.insert(trailEntities, trail)
-- 	end)

-- 	concommand.Add("cleantrails", function()
-- 		-- Iterate through and remove all trail entities
-- 		for _, trail in ipairs(trailEntities) do
-- 			trail:Remove()
-- 		end
-- 		-- Clear the table
-- 		trailEntities = {}
-- 	end)
-- end



-- -- when a player kills another player with a headshot, play a sound
-- if SERVER then
-- 	-- create server message for headshot sound
-- 	util.AddNetworkString("headshot_sound")

-- 	local headshot_sound = Sound("Weapon_Crossbow.BoltHitWorld")
-- 	hook.Add("DoPlayerDeath", "SoundForHeadshot", function(victim, attacker, dmginfo)
-- 		if dmginfo:IsBulletDamage() and victim:LastHitGroup() == HITGROUP_HEAD then
-- 			-- send message to client to play sound
-- 			net.Start("headshot_sound")
-- 			net.Send(attacker)
-- 		end
-- 	end)
-- else
-- 	local headshot_sound = Sound("Weapon_Crossbow.BoltHitWorld")
-- 	net.Receive("headshot_sound", function()
-- 		timer.Simple(0.2, function()
-- 			-- play client sound for headshot. a ping sound
-- 			sound.Play(headshot_sound, LocalPlayer():GetPos(), 75, 100, 1)
-- 		end)
-- 	end)
-- end




if SERVER then
	-- set entity(1) playermodel to gnome
	local gnome_model = "models/splinks/gnome_chompski/player_gnome.mdl"
	concommand.Add("set_gnome", function(ply, cmd, args)
		local ent = ply
		if not IsValid(ent) then return end
		ent:SetModel(gnome_model)
	end)
	-- remove this concommand
	--concommand.Remove("set_gnome")
	
end

/*




-- CHANGE WEAPON PICKUP DISTANCE
if SERVER then
	hook.Add("PlayerCanPickupWeapon", "custom_pickup_dist", function(ply, wep)
		-- if player is pressing e to pickup weapon, allow pickup if within 100 units
		local wep_dist = wep:GetPos():Distance(ply:GetPos())
		if ply:KeyDown(IN_USE) then
			if wep_dist > 100 then
				return false
			end
		else
			if wep_dist > 20 then
				return false
			end
		end
	end)
end


-- if CLIENT then
-- 	local loc = Vector(0,0,0)
-- 	hook.Add("PostDrawTranslucentRenderables", "show_pos", function()
-- 		render.DrawWireframeSphere(loc, 20, 20, 5, Color(200, 200, 200), false)
-- 	end)
-- end


-- if SERVER then
-- 	util.AddNetworkString("dougies_pickup_sound")
-- 	hook.Add("WeaponEquip", "send_dougies_pickup_sound", function(weapon, ply)
-- 		net.Start("dougies_pickup_sound")
-- 		net.Send(ply)
-- 		--return true -- Allow the weapon pickup to proceed
-- 	end)
-- 	--hook.Remove("WeaponEqiup", "send_dougies_pickup_sound")
-- else
-- 	net.Receive("dougies_pickup_sound", function(len)
-- 		surface.PlaySound("items/ammo_pickup.wav")
-- 	end)
-- end

-- when any entity is created, print it to console
/*
if SERVER then
	hook.Add("OnEntityCreated", "print_created_ent", function(ent)
		print(ent)
	end)
end
*/

-- DASH
local DASH_COOLDOWN = 0.75	--seconds
local JUMP_LOCKOUT = 0.2--seconds
if SERVER then
	-- toggle dashing with chat command
	util.AddNetworkString("dougie_dash_hook")
	hook.Add("PlayerSay", "custom_command_dash", function(sender, text, teamChat)
		if sender:GetUserGroup() ~= "user" then
			if text == "!dash" then
				net.Start("dougie_dash_hook")
				net.WriteBool(true)
				net.Broadcast()
			elseif text == "!dash_off" then
				net.Start("dougie_dash_hook")
				net.WriteBool(false)
				net.Broadcast()
				-- disable nosights for all weapons. if it causes problems just restart round
				for i,ent in ipairs(ents.GetAll()) do
					if ent:IsWeapon() then
						ent.NoSights = false
					end
				end
			end
		end
	end)
	-- trigger dash serverside
	util.AddNetworkString("dougie_trigger_dash")
	net.Receive("dougie_trigger_dash", function(len)
		local ply = Entity(net.ReadUInt(32))
		local v = net.ReadVector()
		local orig = ply:GetJumpPower()
		ply:SetJumpPower(-100)
		timer.Simple(JUMP_LOCKOUT, function()
			ply:SetJumpPower(orig)
		end)
		ply:SetVelocity(v)
		ply:EmitSound("Weapon_Crowbar.Single", 50, 100, 0.3, CHAN_BODY) -- "Weapon_Crowbar.Single"
		if ply:GetActiveWeapon():IsValid() then
			ply:GetActiveWeapon().NoSights = true
		end
	end)
end
if CLIENT then
	-- add clientside dash hook
	net.Receive("dougie_dash_hook", function()
		if !net.ReadBool() then
			hook.Remove("KeyPress", "dash_key")
		else
			local next_dash_time = CurTime()
			hook.Add("KeyPress", "dash_key", function(ply, key)
				if LocalPlayer():IsValid() and key == IN_ATTACK2 then -- IN_ATTACK2 : right click by default
					if CurTime() >= next_dash_time and LocalPlayer():OnGround() then
						next_dash_time = CurTime() + DASH_COOLDOWN
						LocalPlayer():GetActiveWeapon().NoSights = true
						-- local orig = LocalPlayer():GetJumpPower()
						-- LocalPlayer():SetJumpPower(-100)
						-- timer.Simple(JUMP_LOCKOUT, function()
						-- 	LocalPlayer():SetJumpPower(orig)
						-- end)
						local dashvec = LocalPlayer():GetAimVector()
						dashvec.z = 0.1
						-- determine dash direction
						local keys = {LocalPlayer():KeyDown(IN_FORWARD), LocalPlayer():KeyDown(IN_MOVERIGHT), LocalPlayer():KeyDown(IN_BACK), LocalPlayer():KeyDown(IN_MOVELEFT)}
						if keys[1] and keys[2] then dashvec:Rotate(Angle(0,-45,0))
						elseif keys[1] and keys[4] then dashvec:Rotate(Angle(0,45,0))
						elseif keys[3] and keys[2] then dashvec:Rotate(Angle(0,-135,0))
						elseif keys[3] and keys[4] then dashvec:Rotate(Angle(0,135,0))
						elseif keys[1] then dashvec:Rotate(Angle(0,0,0))
						elseif keys[2] then dashvec:Rotate(Angle(0,-90,0))
						elseif keys[3] then dashvec:Rotate(Angle(0,180,0))
						elseif keys[4] then dashvec:Rotate(Angle(0,90,0))
						else
							dashvec = Vector(0,0,1)
							dashvec:Mul(0.2)
						end
						dashvec:Mul(1500)
						net.Start("dougie_trigger_dash")
						net.WriteUInt(LocalPlayer():EntIndex(), 32)
						net.WriteVector(dashvec)
						net.SendToServer()
					end
				end
			end)
		end
	end)
end






if SERVER then
	-- prevent players with zombie role from speaking to other roles
	hook.Add("PlayerCanHearPlayersVoice", "zombie_voice_chat", function(listener, talker)
		if talker:GetRole() == ROLE_ZOMBIE then
			if listener:GetRole() != ROLE_ZOMBIE then
				return false
			end
		end
	end)
	-- prevent zombie role from chatting
	hook.Add("PlayerSay", "zombie_chat", function(sender, text, teamChat)
		if sender:GetRole() == ROLE_ZOMBIE then
			return ""
		end
	end)
	hook.Remove("PlayerSay", "zombie_chat")
	hook.Remove("PlayerCanHearPlayersVoice", "zombie_voice_chat")
end




if CLIENT then
    concommand.Add("list_resources", function(ply, cmd, args, argStr)
        local searchTerm = argStr:lower()
        
        -- List models
        local materials = file.Find("models/*.mdl", "GAME")
        for _, mat in pairs(materials) do
            if mat:lower():find(searchTerm) then
                print("models: models/" .. mat)
            end
        end
    end)
end


-- -- 2024 christmas code
-- -- adds command to spawn a present
-- if SERVER then
-- 	present_duration = 10
-- 	local model_options = {
-- 		--"models/props_modest_christmas/present03.mdl",
-- 		--"models/zombiexmas/gift1_static.mdl",
-- 		"models/present/launcher_present.mdl",
-- 	}

-- 	concommand.Add("give_present", function(ply, cmd, args, argStr)
-- 		local spawnpos = ply:GetPos() + Vector(0,0,50) + ply:GetAimVector() * 50
-- 		local box = ents.Create("prop_physics")
-- 		box:SetModel(model_options[math.random(#model_options)])
-- 		box:SetPos(spawnpos)
-- 		--box:SetModelScale(0.3)
-- 		box:Spawn()
-- 		box:PhysicsInit(SOLID_VPHYSICS, nil)
-- 		box:PhysWake()
-- 		box:Activate()
-- 		box:GetPhysicsObject():SetVelocity(ply:GetVelocity())
-- 		box:GetPhysicsObject():SetMass(20)
-- 		box:SetPhysicsAttacker(ply, present_duration)

-- 		-- color options, red and green
-- 		local options = {Color(255,0,0), Color(0,255,0)}
-- 		box:SetColor(options[math.random(#options)])

-- 		-- play beep sound ata random pitch
-- 		box:EmitSound("buttons/blip1.wav", 65, math.random(80, 120), 0.8, CHAN_AUTO)

-- 		-- add callback function to box so that when it collides with something, it explodes
-- 		box:AddCallback("PhysicsCollide", function(ent, data)
-- 			if data.DeltaTime < 0.3 then -- ignore when many collision are quickly reported
-- 				return
-- 			end
-- 			if data.OurOldVelocity:Length() < 500 then -- minimum speed for explosion
-- 				return
-- 			end
-- 			if IsFirstTimePredicted() then
-- 				_explosion(ply, box, data.HitPos, 200, 40) -- radius, damage
-- 				if IsValid(box) then 
-- 					box:Remove()
-- 				end
-- 			end
-- 		end)

-- 		timer.Simple(present_duration, function()
-- 			if IsValid(box) then
-- 				box:Remove()
-- 			end
-- 		end)

-- 	end)
-- end

-- -- list the names of the grenades in TTT
-- -- 

-- -- Fast Grenade Switch for TTT
-- if SERVER then

-- 	-- Hook into weapon switch events
-- 	hook.Add("PlayerSwitchWeapon", "InstantGrenadeSwitch", function(ply, oldWeapon, newWeapon)
-- 		-- Check if the new weapon exists and is a grenade
-- 		if IsValid(newWeapon) and string.find(string.lower(newWeapon:GetClass()), "grenade") then
-- 			-- Force instant weapon hold
-- 			ply:SetNextWeaponSwitch(0)
-- 			newWeapon:SetNextPrimaryFire(0)
-- 			newWeapon:SetNextSecondaryFire(0)
			
-- 			-- Skip default deploy animation
-- 			if newWeapon.SetDeploySpeed then
-- 				newWeapon:SetDeploySpeed(100) -- Very fast deploy speed
-- 			end
			
-- 			return true -- Allow the switch
-- 		end
-- 	end)

-- 	--remove ths
-- 	hook.Remove("PlayerSwitchWeapon", "InstantGrenadeSwitch")
-- end


-- -- add command that, when player types "snowball" in console, gives them the item named "schneeball"
-- if SERVER then
-- 	concommand.Add("snowball", function(ply, cmd, args)
-- 		ply:Give("weapon_ttt_schneeball")
-- 		print("gave "..ply:GetName().." a snowball")
-- 	end)
-- end



-- grenade quick throw
if SERVER then

	local function throw_grenade(ply, grenade)
		-- Execute attack commands with slight delay
		ply:SetActiveWeapon(grenade)
		timer.Simple(0.1, function()
			if IsValid(ply) and ply:Alive() then
				ply:ConCommand("+attack")
				timer.Simple(0.05, function()
					if IsValid(ply) and ply:Alive() then
						ply:ConCommand("-attack")
					end
				end)
			end
		end)
	end	

	local nade_names = {
		["weapon_ttt_smokegrenade"] = true,
		["weapon_zm_molotov"] = true,
		["weapon_ttt_frag"] = true,
		["weapon_ttt_confgrenade"] = true
	}

    util.AddNetworkString("QuickNadeAttack")

    -- Handle the quick nade attack
    net.Receive("QuickNadeAttack", function(len, ply)
        if not IsValid(ply) or not ply:Alive() or not ply:IsPlayer() then return end
		local grenade = nil
		for _, wep in ipairs(ply:GetWeapons()) do
			if nade_names[wep:GetClass()] != nil then
				throw_grenade(ply, wep)
				break
			end
		end


    end)
end

if CLIENT then
    -- Bind key 4 to quick nade
    hook.Add("PlayerButtonDown", "QuickNadeKey", function(ply, button)
        if button == KEY_4 and IsValid(ply) and ply:Alive() then
            net.Start("QuickNadeAttack")
            net.SendToServer()
            return true
        end
    end)
end
