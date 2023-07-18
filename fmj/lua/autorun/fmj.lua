-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end

local log_debug = false
local line_debug = false

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
    -- Normalize the normal vector
    local normalized_normal = myNormalize(normal)

    -- Calculate the scalar projection of the line vector onto the normal vector
    local projection = myDot(line, normalized_normal)

    -- Calculate the reflection vector using the formula R = V - 2 * (V · N) * N
    local reflection = line - myScale(normalized_normal, 2 * projection)

    return reflection
end



if SERVER then
    util.AddNetworkString("fmj_trace_message")
end

local function send_points_se(vec_table)
	if SERVER then
		net.Start("fmj_trace_message")
			for i,vec in ipairs(vec_table) do
				net.WriteVector(vec)
			end
		net.Broadcast()
	end
end

-- visualize last bullet's path and penetrations
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
end

local function my_trace(startpos, endpos, my_filter)
	local tr = util.TraceLine({
		start = startpos,
		endpos = endpos,
		filter = my_filter
	})
	return tr
end

local function impact(tr)
	if !IsFirstTimePredicted() then return end
	if tr.Entity == NULL or tr.HitSky then return end
	local eff = EffectData()
	eff:SetEntity(tr.Entity)
	eff:SetOrigin(tr.HitPos)
	eff:SetStart(tr.StartPos)
	eff:SetSurfaceProp(tr.SurfaceProps)
	eff:SetDamageType(DMG_BULLET)
	eff:SetHitBox(tr.HitBox)
	eff:SetNormal(tr.Normal)
	util.Effect("Impact", eff, true, true)
end


local function fmj_sparks(origin, normal)
	if !IsFirstTimePredicted() then return end
	local eff = EffectData()
	eff:SetOrigin(origin) 
	eff:SetNormal(normal)
	util.Effect("MetalSpark", eff, true, true)
end


local function penetrate_world_solid(origin, dir, max_depth, contents_src)
	-- contents_src: util.PointContents at bullet's source pos. treat that value as empty space
	local depth = 0
	local next_pos = origin
	while true do
		next_pos = next_pos + dir
		depth = depth + 1
		local next_contents = util.PointContents(next_pos)
		if next_contents == CONTENTS_EMPTY 
		or next_contents == contents_src
		or depth > max_depth then
			return next_pos, depth
		end
	end
end


local function bullet_hit(ent, tr, bdata, percent_pierced) 
	
	-- apply damage
	if IsValid(ent) /*and ent:GetClass() != "prop_physics"*/ then -- note: world entity is not valid
		local dmg_amt = math.ceil((1-percent_pierced) * bdata.Damage * p2d[tr.HitGroup])
		local dinfo = DamageInfo()
		dinfo:SetDamage(dmg_amt)
		dinfo:SetAttacker(bdata.Attacker)
		dinfo:SetInflictor(bdata.Attacker:GetActiveWeapon())
		dinfo:SetDamageForce(tr.Normal*bdata.Force)
		dinfo:SetDamagePosition(tr.HitPos)
		dinfo:SetDamageType(DMG_BULLET)
		dinfo:SetAmmoType(game.GetAmmoID(bdata.AmmoType))
		dinfo:SetReportedPosition(tr.HitPos)

		if ent:IsPlayer() then
			ent:SetLastHitGroup(tr.HitGroup)
			if ent:Health() <= dmg_amt then
				print(bdata.Attacker:Nick().." killed "..ent:Nick().. " with FMJ or ricochet damage.")
			end
			if log_debug then print("\tPen damage", ent, dmg_amt) end
		end

		-- apply force to physics objects and log
		if IsValid(ent:GetPhysicsObject()) then
			if ent:IsRagdoll() then
				ent:GetPhysicsObject():SetVelocity(bdata.Force * (tr.Normal+Vector(0,0,0.5)) * 120)
			else
				ent:GetPhysicsObject():SetVelocity(bdata.Force * tr.Normal * 20)
			end
		end

		ent:TakeDamageInfo(dinfo)

	end
	
end

--
local MAX_TRACES = 7
local MAX_RICOCHETS = 2
local MAX_DEPTH = 48
local MAX_ANGLE = 20
local MIN_DAMAGE = 25

local hook_type = "EntityFireBullets"
local hook_name = "zz"..hook_type.."_dougie_fmj_2"
hook.Add(hook_type, hook_name, function( shooter, bdata )

	if CLIENT then return end

	if log_debug then print() end

	bdata.Callback = function(att, tr, dmg_info)
		fmj_callback(att, tr, dmg_info, bdata)
	end

	return true -- return true to apply bdata updates to bullet

end)
--hook.Remove(hook_type, hook_name)


local function tracer(f_tr)
	local eff = EffectData()
	eff:SetOrigin(f_tr.HitPos)
	eff:SetStart(f_tr.StartPos)
	eff:SetScale(4500)
	eff:SetFlags(0x0001)
	--eff:SetAttachment(1)
	util.Effect("Tracer", eff, false, true)

end

function fmj_callback(shooter, f_tr, dmg_info, bdata)

	if f_tr.HitSky or f_tr.Entity == NULL then return end

	-- prep
	local now_piercing = nil
	local my_filter = nil
	local this_depth = nil
	local start_pos = nil
	local final_pos = nil

	local points_se = {}
	local pierced_depth = 0
	local num_ricochets = 0
	local traceno = 0
	local bullet_range = math.min(bdata.Distance, 10000)
	local hit_angle = 0

	local fmj_dir = f_tr.Normal

	--if log_debug then print("\tHit angle:", fmj_get_angle(fmj_dir, f_tr.HitNormal)) end

	while true do

		-- count traces
		traceno = traceno + 1
		if traceno > MAX_TRACES then 
			if log_debug then print("\tPen exit", "Trace limit", MAX_TRACES) end
			break 
		end

		start_pos = f_tr.HitPos
		if line_debug then table.insert(points_se, start_pos) end
		hitting = f_tr.Entity
		if log_debug then print("\tHit", hitting) end

		fmj_dir = f_tr.Normal

		-- check angle
		hit_angle = fmj_get_angle(fmj_dir, f_tr.HitNormal)
		if log_debug then print("\tHit angle", hit_angle) end
		if hit_angle < MAX_ANGLE and bdata.Damage >= MIN_DAMAGE and !hitting:IsPlayer() and !hitting:IsRagdoll() then
			-- do ricochet
			num_ricochets = num_ricochets + 1
			if num_ricochets > MAX_RICOCHETS then
				if log_debug then print("\tExit", "Ricochet limit reached.") end
				if line_debug then table.insert(points_se, f_tr.HitPos) end
				break
			end
			fmj_dir = get_reflection(fmj_dir, f_tr.HitNormal)
			f_tr = my_trace(start_pos, start_pos+fmj_dir*bullet_range, {shooter, f_tr.Entity})
			tracer(f_tr)
			fmj_sparks(f_tr.StartPos, f_tr.Normal)
			sound.Play("FX_RicochetSound.Ricochet", f_tr.StartPos)
		else
			-- don't do ricochet. check for penetration instead
			if not f_tr.HitWorld then
				-- for non-world solids, run a filtered trace through ent then an unfiltered trace back to get depth
				f_tr = my_trace(start_pos, start_pos+fmj_dir*bullet_range, {shooter, f_tr.Entity})
				b_tr = my_trace(f_tr.HitPos-fmj_dir, start_pos, shooter)
				final_pos = b_tr.HitPos
				this_depth = f_tr.StartPos:Distance(final_pos)
			else
				-- for world solids, step through world solid, then trace forward and back to set up effects
				final_pos, this_depth = penetrate_world_solid(start_pos, fmj_dir, MAX_DEPTH-pierced_depth+1, util.PointContents(bdata.Src))
				f_tr = my_trace(final_pos, final_pos+fmj_dir*bullet_range, shooter)
				b_tr = my_trace(final_pos+fmj_dir, final_pos-fmj_dir*2, shooter)
			end

			-- check depth limit
			if hitting:IsPlayer() or hitting:IsRagdoll() then
				this_depth = this_depth / 5
			end
			if this_depth + pierced_depth > MAX_DEPTH then 
				if log_debug then print("\tPen exit", "Depth limit") end
				if line_debug then table.insert(points_se, final_pos) end
				break 
			end
			pierced_depth = pierced_depth + this_depth
			if log_debug then print("\tPen depth ", this_depth) end
			if line_debug then table.insert(points_se, final_pos) end

			-- post-penetration bullet exit effects
			impact(b_tr)
			fmj_sparks(b_tr.HitPos+b_tr.Normal*5, -b_tr.Normal) -- sparks originate slightly inside of surface; looks better

		end

		-- final penetration/ricochet bullet contact. Effects, damage, force 
		if f_tr.Entity == NULL or f_tr.HitSky then
			if log_debug then print("\tPen exit", "Bullet exited world") end
			if line_debug then table.insert(points_se, f_tr.HitPos) end
			break
		end
		impact(f_tr)
		bullet_hit(f_tr.Entity, f_tr, bdata, pierced_depth/MAX_DEPTH)
		if f_tr.Entity:GetClass() == "func_breakable_surf" then
			f_tr.Entity:Fire("Shatter")
		end

	end

	if log_debug then print("\tPierced depth: ", pierced_depth, MAX_DEPTH, '\n') end
	if line_debug then send_points_se(points_se) end

	return true
end

