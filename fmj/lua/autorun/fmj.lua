-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end


local function my_trace(origin, dir, len, my_filter)
	local tr = util.TraceLine({
		start = origin,
		endpos = origin + (dir*len),
		filter = my_filter
	})
	return tr
end

local function impact(tr)
	if !IsFirstTimePredicted() then return end
	if tr.Entity == NULL then return end
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


local function fmj_sparks(tr)
	if !IsFirstTimePredicted() then return end
	local eff = EffectData()
	eff:SetOrigin(tr.HitPos+tr.Normal*5)
	eff:SetNormal(-tr.Normal)
	util.Effect("MetalSpark", eff, true, true)
end


local function get_next_empty_pos(origin, dir, max_depth, contents_src)
	-- contents_src: PointContents at bullet's source pos. treat that value as empty space
	local depth = 0
	local next_pos = origin
	while true do
		next_pos = next_pos + dir -- the +dir is very important
		depth = depth + 1
		local next_contents = util.PointContents(next_pos)
		if next_contents == CONTENTS_EMPTY 
		or next_contents == contents_src 
		or depth > max_depth then
			return next_pos, depth
		end
	end
end


local function bullet_hit(ent, tr, fmj_dir, bdata) 
	-- apply damage
	if IsValid(ent) /*and ent:GetClass() != "prop_physics"*/ then -- note: world entity is not valid
		local dinfo = DamageInfo()
		if ent:IsPlayer() then
			ent:SetLastHitGroup(tr.HitGroup)
		end
		dinfo:SetDamage(bdata.Damage)
		dinfo:SetAttacker(bdata.Attacker)
		dinfo:SetInflictor(bdata.Attacker:GetActiveWeapon())
		dinfo:SetDamageForce(fmj_dir*bdata.Force)
		dinfo:SetDamagePosition(tr.HitPos)
		dinfo:SetDamageType(DMG_BULLET)
		dinfo:SetAmmoType(game.GetAmmoID(bdata.AmmoType))
		dinfo:SetReportedPosition(tr.HitPos)
		ent:TakeDamageInfo(dinfo)
	end
	-- apply force to physics objects
	if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
		ent:GetPhysicsObject():SetVelocity(bdata.Force*fmj_dir*10)
	end
end


local hook_type = "EntityFireBullets"
local hook_name = hook_type.."fmj"

hook.Add(hook_type, hook_name, function( shooter, bdata )

	if CLIENT then return end

	print()
	
	if bdata.Num > 1 then return end -- no shotguns

	-- prep
	local spreadx = (math.random(0, bdata.Spread.x*100)/100 - (bdata.Spread.x/2)) * 0.5
	local spready = (math.random(0, bdata.Spread.y*100)/100 - (bdata.Spread.y/2)) * 0.5
	local fmj_dir = bdata.Dir + Vector(spreadx, spreadx, 0)
	local my_filter = nil
	local this_depth = nil
	local final_pos = nil
	local now_piercing = nil

	local start_pos = nil

	-- measurement
	local traceno = 1
	local max_traces = 10
	local pierced_depth = 0
	local max_depth = math.min(bdata.Damage, 200)

	-- first trace
	local f_tr = my_trace(bdata.Src, fmj_dir, 10000, shooter)
	if f_tr.Entity == NULL or f_tr.HitSky == true then 
		print("\tExit","Initial trace exited map") 
		return 
	end	
	local b_tr = nil

	timer.Simple(4, function()

		while true do

			-- ADD CHECKS FOR NULL HIT ENT

			now_piercing = f_tr.Entity
			print("\tNow piercing", f_tr.Entity)
			start_pos = f_tr.HitPos
			if not f_tr.HitWorld then
				-- trace through prop and back to get depth
				f_tr = my_trace(start_pos, fmj_dir, 10000, f_tr.Entity)
				b_tr = my_trace(f_tr.HitPos - fmj_dir, -fmj_dir, 10000, nil)
				-- depth
				this_depth = get_euc_dist(f_tr.StartPos, b_tr.HitPos)
			else
				-- step through world solid, trace forward and back to get depth
				final_pos, this_depth = get_next_empty_pos(start_pos, fmj_dir, max_depth+1, util.PointContents(bdata.Src))
				f_tr = my_trace(final_pos, fmj_dir, 10000, f_tr.Entity)
				b_tr = my_trace(final_pos + fmj_dir, -fmj_dir, 100, nil)
			end

			if this_depth + pierced_depth > max_depth then 
				print("\tExit", "Depth limit") 
				break 
			end
			pierced_depth = pierced_depth + this_depth
			print("\tPenetrated ", now_piercing, this_depth)

			-- exit effects
			impact(b_tr)
			fmj_sparks(b_tr)

			-- entry effects and damage, force
			impact(f_tr)
			bullet_hit(f_tr.Entity, f_tr, fmj_dir, bdata)

			-- count traces
			traceno = traceno + 1
			if traceno > max_traces then 
				print("\tExit", "Trace limit", max_traces) 
				break 
			end

		end

		print("\tPierced depth: ", pierced_depth, max_depth)
		--draw_line(bdata.Src, final_pos)
		print()
		return

	end)
	
end)

--hook.Remove(hook_type, hook_name)