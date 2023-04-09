-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end


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

local function do_tracer(entity, tr)
	--if !IsFirstTimePredicted() then return end
	--if tr.Entity == NULL then return end
	local eff = EffectData()
	eff:SetEntity(entity)
	eff:SetAngles(tr.Normal:Angle())
	eff:SetOrigin(tr.StartPos)
	eff:SetStart(tr.StartPos)
	--eff:SetHitBox(tr.HitBox)
	util.Effect("Tracer", eff, true, true)
end


local function fmj_sparks(origin, normal)
	local eff = EffectData()
	eff:SetOrigin(origin)
	eff:SetNormal(normal)
	util.Effect("MetalSpark", eff)
end


local function get_next_empty_pos(origin, dir, max_depth, contents_src)
	-- contents_src: PointContents at bullet's source pos. treat that value as empty space
	local depth = 0
	local next_pos = origin
	while true do
		next_pos = next_pos + dir -- the +dir is very important
		depth = depth + 1
		print("\t"..util.PointContents(next_pos), contents_src)
		if util.PointContents(next_pos) == CONTENTS_EMPTY 
		or util.PointContents(next_pos) == contents_src 
		or depth > max_depth then
			return next_pos, depth
		end
	end
end


local function bullet_entry(tr, fmj_dir, bdata) 
	-- effect
	impact(tr)
	-- apply damage
	if IsValid(tr.Entity) /*and tr.Entity:GetClass() != "prop_physics"*/ then -- world entity is not valid
		tr.Entity:TakeDamage(bdata.Damage/2, bdata.Attacker, bdata.Attacker:GetActiveWeapon())
	end
	-- if body, do blood. else, do force
	if tr.Entity:IsPlayer() /*or tr.Entity:GetClass() == "prop_ragdoll"*/ then
		local eff = EffectData()
		eff:SetOrigin(tr.HitPos)
		util.Effect("BloodImpact", eff)
	else 
		if IsValid(tr.Entity) and IsValid(tr.Entity:GetPhysicsObject()) then
			tr.Entity:GetPhysicsObject():SetVelocity(fmj_dir*bdata.Force*30)
		end
	end
end


local function bullet_exit(tr, fmj_dir)

	-- fmj reverse trace for exit decal
	local tr_reverse = util.TraceLine({
		start = tr.HitPos,
		endpos = tr.StartPos
	})

	impact(tr_reverse)
	fmj_sparks(tr_reverse.HitPos, -tr_reverse.Normal)

end

local function should_end_tracing(tr)
	if tr.HitSky == true
	or tr.Entity == NULL then
		return true
	else
		return false
end


local hook_type = "EntityFireBullets"
local hook_name = hook_type.."fmj"

hook.Add(hook_type, hook_name, function( shooter, bdata )

	/*
	new approach:
		get intitial trace
		if tr1.Entity ok
			tr2 = trace tr1.hitpos to tr1.hitpos+fmj_dir*10000, filtering tr1.Entity
			tr2back = trace tr2.hitpos to tr2.StartPos
			local exit_pos = tr2back.HitPos
			local exit_normal = -tr2back.Normal


	*/

	-- clear spheres
	if CLIENT then fmj_spheres = {} return end
	
	-- no shotguns
	if bdata.Num > 1 then return end

	-- prep
	local spreadx = (math.random(0, bdata.Spread.x*100)/100 - (bdata.Spread.x/2)) * 0.5
	local spready = (math.random(0, bdata.Spread.y*100)/100 - (bdata.Spread.y/2)) * 0.5
	local fmj_dir = bdata.Dir + Vector(spreadx, spreadx, 0)
	local start = nil
	local filter = nil
	local this_depth = nil
	local exit_pos = nil
	local tr = nil

	-- measurement
	local traceno = 1
	local max_traces = 10
	local pierced_depth = 0
	local max_depth = math.min(bdata.Damage, 200)

	print()

	timer.Simple(2, function()

		--fmj_spheres = {}

		while true do

			if traceno == 1 then
				tr = util.TraceLine({
					start = bdata.Src,
					endpos = bdata.Src + (fmj_dir*10000),
					filter = shooter
				})
			else
				tr = util.TraceLine({
					start = exit_pos,
					endpos = exit_pos + (fmj_dir*10000),
					filter = filter
				})
				bullet_exit(tr, fmj_dir)
			end
					
			--draw_sphere(tr.StartPos) -- exit_pos becomes next tr.StartPos
			--draw_sphere(tr.HitPos)

			if should_end_tracing(tr) then
				print("\t", "Trace hit sky or NULL ent")
				break
			end

			-- damage, force, sounds, effects
			if traceno > 1 then
				bullet_entry(tr, fmj_dir, bdata)
			end

			exit_pos, this_depth = get_next_empty_pos(tr.HitPos, fmj_dir, max_depth-pierced_depth, util.PointContents(bdata.Src))
			if pierced_depth + this_depth > max_depth then 
				print("\tExit", "Depth limit") 
				--draw_sphere(exit_pos)
				break 
			end
			pierced_depth = pierced_depth + this_depth

			--if get_angle(tr.Normal, tr.HitNormal) > 60 then return end

			print("\tPenetrated ", tr.Entity, this_depth)

			traceno = traceno + 1
			if traceno > max_traces then 
				print("\tExit", "Trace limit", max_traces) 
				break 
			end

			-- prepare next nonsolid trace
			if tr.Entity:IsPlayer() 
			or tr.Entity:GetClass() == "prop_ragdoll" 
			or tr.Entity:GetClass() == "prop_physics"
			or tr.Entity:GetClass() == "prop_dynamic" then
				filter = tr.Entity 
			end
		end

		print("\tPierced depth: ", pierced_depth, max_depth)
		--draw_line(bdata.Src, exit_pos)
		print()
		return

	end)


	
end)

--hook.Remove(hook_type, hook_name)