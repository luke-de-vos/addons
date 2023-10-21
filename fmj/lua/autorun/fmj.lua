-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end


if CLIENT then

	local my_color1 = Color(150, 0, 0)
	local my_color2 = Color(0, 200, 0)
	local cl_points = {}
	local this_vec = nil

	net.Receive("fmj_trace_message", function(len)
		cl_points = {}
		while true do
			this_vec = net.ReadVector()
			if this_vec == Vector(0,0,0) then break end
			table.insert(cl_points, this_vec)
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "PostDraw_bullet_trace", function()
		if #cl_points < 2 then return end
		-- render.DrawLine(cl_points[1], cl_points[#cl_points], my_color1, false)
		-- render.DrawLine(cl_points[1], cl_points[#cl_points], my_color2, true)
		for i,vec in ipairs(cl_points) do
			if i != 1 then
				render.DrawLine(cl_points[i-1], cl_points[i], my_color1, false)
				render.DrawLine(cl_points[i-1], cl_points[i], my_color2, true)
			end
			render.DrawWireframeSphere(vec, 1, 20, 5, my_color1, false)
			render.DrawWireframeSphere(vec, 1, 20, 5, my_color2, true)
		end
	end)
	
	net.Receive("fmj_popup_message", function(len)
		local val = net.ReadInt(2)
		if val == 0 then
			notification.AddLegacy("RICOCHET KILL!", NOTIFY_UNDO, 4)
			--surface.PlaySound("buttons/button10.wav")
		elseif val == 1 then
			notification.AddLegacy("FMJ KILL!", NOTIFY_UNDO, 4)
			--surface.PlaySound("buttons/button10.wav")
		end
	end)

end

if SERVER then

	CreateConVar("max_traces", 4, FCVAR_NONE, "Maximum number of traces a bullet can make before exiting. Default 7", 0, 100)
	CreateConVar("fmj_delay", 0, FCVAR_NONE, "Delay in seconds before bullet penetration is applied. 0 = no delay. Default 0", 0, 10)
	CreateConVar("fmj_depth_limit", 24, FCVAR_NONE, "Maximum depth in inches a bullet can penetrate. Default 24", 0, 120000)
	CreateConVar("fmj_log", 0, FCVAR_NONE, "Print debug info to console. 0 = no log. Default 0", 0, 1)
	CreateConVar("ricochet_angle", 20, FCVAR_NONE, "Maximum angle in degrees between bullet and surface normal for a ricochet to occur. Default 20", 0, 360)
	CreateConVar("ricochet_min_damage", 24, FCVAR_NONE, "Minimum damage in inches a bullet must have to ricochet. Default 24")

	-- Initialization
	local max_traces = GetConVar("max_traces"):GetInt()
	local fmj_delay = GetConVar("fmj_delay"):GetInt()
	local fmj_depth_limit = GetConVar("fmj_depth_limit"):GetInt()
	local fmj_log = GetConVar("fmj_log"):GetBool()
	local ricochet_angle = GetConVar("ricochet_angle"):GetInt()
	local ricochet_min_damage = GetConVar("ricochet_min_damage"):GetInt()

	-- Callbacks
	cvars.RemoveChangeCallback("max_traces", "max_traces_callback")
	cvars.AddChangeCallback("max_traces", function(name, old, new)
		max_traces = tonumber(new)
		print("cvar update: ", name, old, max_traces)
	end, "max_traces_callback")

	cvars.RemoveChangeCallback("fmj_delay", "fmj_delay_callback")
	cvars.AddChangeCallback("fmj_delay", function(name, old, new)
		fmj_delay = tonumber(new)
		print("cvar update: ", name, old, fmj_delay)
	end, "fmj_delay_callback")

	cvars.RemoveChangeCallback("fmj_depth_limit", "fmj_depth_limit_callback")
	cvars.AddChangeCallback("fmj_depth_limit", function(name, old, new)
		fmj_depth_limit = tonumber(new)
		print("cvar update: ", name, old, fmj_depth_limit)
	end, "fmj_depth_limit_callback")

	cvars.RemoveChangeCallback("fmj_log", "fmj_log_callback")
	cvars.AddChangeCallback("fmj_log", function(name, old, new)
		fmj_log = tobool(new)
		print("cvar update: ", name, tobool(old), fmj_log)
	end, "fmj_log_callback")

	cvars.RemoveChangeCallback("ricochet_angle", "richochet_angle_callback")
	cvars.AddChangeCallback("ricochet_angle", function(name, old, new)
		ricochet_angle = tonumber(new)
		print("cvar update: ", name, old, ricochet_angle)
	end, "richochet_angle_callback")
	
	cvars.RemoveChangeCallback("ricochet_min_damage", "ricochet_min_damage_callback")
	cvars.AddChangeCallback("ricochet_min_damage", function(name, old, new)
		ricochet_min_damage = tonumber(new)
		print("cvar update: ", name, old, ricochet_min_damage)
	end, "ricochet_min_damage_callback")

	local p2d = {}
	p2d[HITGROUP_GENERIC] = 1
	p2d[HITGROUP_HEAD] = 3
	p2d[HITGROUP_CHEST] = 1
	p2d[HITGROUP_STOMACH] = 1
	p2d[HITGROUP_LEFTARM] = 1
	p2d[HITGROUP_RIGHTARM] = 1
	p2d[HITGROUP_LEFTLEG] = 0.54
	p2d[HITGROUP_RIGHTLEG] = 0.54

	-- math helpers
	local function myDot(a, b)
		return (a[1] * b[1]) + (a[2] * b[2]) + (a[3] * b[3])
	end

	local function myMag(a)
		return math.sqrt((a[1] * a[1]) + (a[2] * a[2]) + (a[3] * a[3]))
	end

	local function fmj_get_angle(vec1, vec2)
		return math.deg(math.acos(myDot(vec1, vec2) / (myMag(vec1) * myMag(vec2)))) - 90
	end

	local function myNormalize(vec)
		local mag = myMag(vec)
		return Vector(vec[1] / mag, vec[2] / mag, vec[3] / mag)
	end

	local function myScale(vec, scalar)
		return Vector(vec[1] * scalar, vec[2] * scalar, vec[3] * scalar)
	end

	local function get_reflection(line, normal)
		local normalized_normal = myNormalize(normal)
		local projection = myDot(line, normalized_normal)
		local reflection = line - myScale(normalized_normal, 2 * projection)
		return reflection
	end

	util.AddNetworkString("fmj_trace_message")
	local function send_points_se(vec_table)
		net.Start("fmj_trace_message")
			for i,vec in ipairs(vec_table) do
				net.WriteVector(vec)
			end
		net.Broadcast()
	end

	local function update_trace(tr, startpos, endpos, my_filter)
		util.TraceLine({
			start = startpos,
			endpos = endpos,
			filter = my_filter,
			output = tr
		})
	end

	local function fmj_tracer(f_tr)
		local eff = EffectData()
		eff:SetOrigin(f_tr.HitPos)
		eff:SetStart(f_tr.StartPos)
		eff:SetScale(4500)
		eff:SetFlags(0x0001)
		--eff:SetAttachment(1)
		util.Effect("Tracer", eff, false, true)
	end

	local function fmj_sparks(origin, normal)
		if !IsFirstTimePredicted() then return end
		local eff = EffectData()
		eff:SetOrigin(origin) 
		eff:SetNormal(normal)
		util.Effect("MetalSpark", eff, true, true)
	end

	local function penetrate_world_solid(origin, dir, fmj_depth_limit, contents_src)
		-- contents_src: util.PointContents at bullet's source pos. treat that value as empty space
		local depth = 0
		local next_pos = origin
		while true do
			next_pos = next_pos + dir
			depth = depth + 1
			local next_contents = util.PointContents(next_pos)
			if next_contents == CONTENTS_EMPTY 
			or next_contents == CONTENTS_TESTFOGVOLUME
			or next_contents == contents_src
			or depth > fmj_depth_limit then
				return next_pos, depth
			end
		end
	end

	local function fmj_impact(tr)
		if !IsFirstTimePredicted() then return end
		if tr.Entity == NULL or tr.HitSky then return end
		local eff = EffectData()
		if tr.Entity:IsPlayer() or tr.Entity:IsRagdoll() then 
			eff:SetOrigin(tr.HitPos)
			eff:SetNormal(tr.Normal)
			eff:SetScale(1)
			util.Effect("BloodImpact", eff, true, true)
		else
			eff:SetEntity(tr.Entity)
			eff:SetOrigin(tr.HitPos)
			eff:SetStart(tr.StartPos)
			eff:SetSurfaceProp(tr.SurfaceProps)
			eff:SetDamageType(DMG_BULLET)
			eff:SetHitBox(tr.HitBox)
			eff:SetNormal(tr.Normal)
			util.Effect("Impact", eff, true, true)
		end
	end

	util.AddNetworkString("fmj_popup_message")
	local function bullet_hit(ent, tr, bdata, percent_pierced, status) 

		-- apply damage. force, where necessary.
		
		if IsValid(ent) then -- note: world entity is not valid

			local dmg_amt = math.ceil((1-percent_pierced/2) * bdata.Damage * p2d[tr.HitGroup]) -- divide by two to make fmj damage from 100-50% bullet damage from 0-24 inch pen

			if ent:IsPlayer() then
				local dinfo = DamageInfo()
				dinfo:SetDamage(dmg_amt)
				dinfo:SetAttacker(bdata.Attacker)
				dinfo:SetInflictor(bdata.Attacker:GetActiveWeapon())
				dinfo:SetDamageForce(tr.Normal*bdata.Force)
				dinfo:SetDamagePosition(tr.HitPos)
				dinfo:SetDamageType(DMG_BULLET)
				dinfo:SetAmmoType(game.GetAmmoID(bdata.AmmoType))
				dinfo:SetReportedPosition(tr.HitPos)
				ent:SetLastHitGroup(tr.HitGroup)
				-- if player will be killed..
				if ent:Health() <= dmg_amt then
					print(bdata.Attacker:Nick().." killed "..ent:Nick().. " with FMJ or ricochet damage.")
					if SERVER then
						net.Start("fmj_popup_message")
						net.WriteInt(status,2)
						net.Send(bdata.Attacker)
					end
				end
				ent:TakeDamageInfo(dinfo)
				if fmj_log then print("\tPen damage", ent, dmg_amt) end
			elseif ent:GetClass() == "prop_physics" then
				ent:GetPhysicsObject():SetVelocity(bdata.Force * tr.Normal * 20)
				ent:TakeDamage(dmg_amt, bdata.Attacker, bdata.Attacker:GetActiveWeapon())
			elseif ent:IsRagdoll() then
				ent:GetPhysicsObject():SetVelocity(bdata.Force * tr.Normal * 20)
			end
		end
	end

	hook.Add("EntityFireBullets", "zzEntityFireBullets_dougie_fmj_2", function( shooter, bdata )

		if shooter:GetActiveWeapon():GetPrimaryAmmoType() < 0 then return end -- don't apply to melee weapons
		if fmj_log then print() end

		-- TODO: only return true if hit ent material is not glass. otherwise, return false and let glass act as normal
		
		bdata.Callback = function(att, tr, dmg_info)
			if fmj_delay > 0 then
				timer.Simple(fmj_delay, function() 
					fmj_callback(att, tr, dmg_info, bdata) 
				end)
			else
				fmj_callback(att, tr, dmg_info, bdata) 
			end
		end

		return true -- return true to apply bdata updates to bullet

	end)
	--hook.Remove("EntityFireBullets", "zzEntityFireBullets_dougie_fmj_2")


	function fmj_callback(shooter, f_tr, dmg_info, bdata)

		if f_tr.HitSky or f_tr.Entity == NULL then return end
		if f_tr.MatType == MAT_GLASS then return end

		-- prep
		local now_piercing = nil
		local my_filter = nil
		local this_depth = nil
		local start_pos = nil
		local final_pos = nil
		local hitting = nil

		local points_se = {}
		local pierced_depth = 0
		local traceno = 0
		local bullet_range = math.min(bdata.Distance, 10000)
		local hit_angle = 0
		local status = -1 -- -1 = normal, 0 = ricochet, 1 = fmj
		

		local fmj_dir = f_tr.Normal
		local b_tr = util.TraceLine({start = f_tr.HitPos, endpos = f_tr.HitPos}) -- dummy start and end. This line just initializes b_tr to be passed to update_trace

		while true do

			fmj_dir = f_tr.Normal
			start_pos = f_tr.HitPos
			hitting = f_tr.Entity
			if fmj_log then print("\tHit", hitting); table.insert(points_se, start_pos) end

			-- penetration or ricochet?
			hit_angle = fmj_get_angle(fmj_dir, f_tr.HitNormal)
			if fmj_log then print("\tHit angle", hit_angle) end
			if hit_angle < ricochet_angle and bdata.Damage >= ricochet_min_damage and !hitting:IsPlayer() and !hitting:IsRagdoll() then
				-- do ricochet
				status = 0
				fmj_dir = get_reflection(fmj_dir, f_tr.HitNormal)
				update_trace(f_tr, start_pos, start_pos+fmj_dir*bullet_range, f_tr.Entity)
				fmj_tracer(f_tr)
				fmj_sparks(f_tr.StartPos, f_tr.Normal)
				sound.Play("FX_RicochetSound.Ricochet", f_tr.StartPos)
			else
				-- don't do ricochet. check for penetration instead
				status = 1
				if not f_tr.HitWorld then
					-- for non-world solids, run a filtered trace through ent then an unfiltered trace back to get depth
					update_trace(f_tr, start_pos, start_pos+fmj_dir*bullet_range, {shooter, f_tr.Entity})
					update_trace(b_tr, f_tr.HitPos-fmj_dir, start_pos, shooter)
					final_pos = b_tr.HitPos
					this_depth = f_tr.StartPos:Distance(final_pos)
				else
					-- for world solids, step through world solid, then trace forward and back to set up effects
					final_pos, this_depth = penetrate_world_solid(start_pos, fmj_dir, fmj_depth_limit-pierced_depth+1, util.PointContents(bdata.Src))
					update_trace(f_tr, final_pos, final_pos+fmj_dir*bullet_range, shooter)
					update_trace(b_tr, final_pos+fmj_dir, final_pos-fmj_dir*2, shooter)
				end

				-- check depth limit
				if hitting:IsPlayer() or hitting:IsRagdoll() then
					this_depth = this_depth / 5
				end
				if pierced_depth + this_depth > fmj_depth_limit then 
					if fmj_log then print("\tPen exit", "Depth limit"); table.insert(points_se, final_pos) end
					break 
				end
				pierced_depth = pierced_depth + this_depth -- this should be here. not above.
				
				if fmj_log then print("\tPen depth ", this_depth); table.insert(points_se, final_pos) end

				-- post-penetration bullet exit effects
				fmj_impact(b_tr)
				fmj_tracer(f_tr)
				if !(hitting:IsPlayer() or hitting:IsRagdoll()) then
					--fmj_sparks(b_tr.HitPos + b_tr.Normal * 5, -b_tr.Normal) -- sparks originate slightly inside of surface; looks better
					fmj_sparks(b_tr.HitPos + b_tr.Normal * 5, fmj_dir) -- sparks originate slightly inside of surface. looks better
				end
			end

			-- final penetration/ricochet bullet contact. Effects, damage, force 
			if f_tr.Entity == NULL or f_tr.HitSky then
				if fmj_log then print("\tPen exit", "Bullet exited world"); table.insert(points_se, f_tr.HitPos) end
				break
			end
			fmj_impact(f_tr)
			bullet_hit(f_tr.Entity, f_tr, bdata, pierced_depth/fmj_depth_limit, status)
			-- if f_tr.Entity:GetClass() == "func_breakable_surf" then
			-- 	f_tr.Entity:Fire("Shatter")
			-- end

			-- count traces
			traceno = traceno + 1
			if traceno >= max_traces then 
				if fmj_log then print("\tPen exit", "Trace limit", max_traces) end
				break 
			end

		end

		if fmj_log then print("\tPierced depth: ", pierced_depth, fmj_depth_limit, '\n'); send_points_se(points_se) end

		return true

	end

end