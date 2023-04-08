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


local function fmj_sparks(tr)
	local eff = EffectData()
	eff:SetOrigin(tr.StartPos)
	eff:SetNormal(-tr.Normal)
	util.Effect("MetalSpark", eff)
end


local function get_next_empty_pos(origin, dir, max_depth, contents_src)
	local depth = 0
	local next_pos = origin
	while true do
		--print(util.PointContents(next_pos), contents_src)
		next_pos = next_pos + dir
		depth = depth + 1
		if util.PointContents(next_pos) == CONTENTS_EMPTY or util.PointContents(next_pos) == contents_src then
			return next_pos, depth
		end
		if depth > max_depth then
			return next_pos, depth
		end
	end
end


local function bullet_entry(tr, fmj_dir, bdata) 
	-- effect
	impact(tr)
	-- apply damage
	if IsValid(tr.Entity) and tr.Entity:GetClass() != "prop_physics" then -- world entity is not valid
		tr.Entity:TakeDamage(bdata.Damage, bdata.Attacker, bdata.Attacker:GetActiveWeapon())
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


local function bullet_exit(exit_pos, fmj_dir)

	-- fmj reverse trace for exit decal
	local tr_reverse = util.TraceLine({
		start = exit_pos,
		endpos = exit_pos + (-fmj_dir*10)
	})

	impact(tr_reverse)
	fmj_sparks(tr_reverse)

end


local hook_type = "EntityFireBullets"
local hook_name = hook_type.."fmj"

hook.Add(hook_type, hook_name, function( shooter, bdata )

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

	--timer.Simple(4, function()

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
			end

				-- tracer
			do_tracer(shooter:GetActiveWeapon(), tr)
		
			--draw_sphere(tr.StartPos) -- exit_pos becomes next tr.StartPos
			--draw_sphere(tr.HitPos)

			if tr.HitSky then 
				print("\tExit: hit sky") 
				exit_pos = tr.HitPos
				break 
			end
			if tr.Entity == NULL then
				print("\tExit: hit NULL") 
				exit_pos = tr.HitPos
				break 
			end

			-- damage, force, sounds, effects
			if traceno > 1 then
				bullet_entry(tr, fmj_dir, bdata)
			end

			exit_pos, this_depth = get_next_empty_pos(tr.HitPos, fmj_dir, max_depth-pierced_depth, util.PointContents(bdata.Src))
			if pierced_depth + this_depth > max_depth then 
				print("\tHIT DEPTH LIMIT") 
				break 
			end
			pierced_depth = pierced_depth + this_depth

			--if get_angle(tr.Normal, tr.HitNormal) > 60 then return end

			print("\tPenetrated ", tr.Entity, this_depth)

			bullet_exit(exit_pos, fmj_dir)

			traceno = traceno + 1
			if traceno > max_traces then 
				print("\tHIT TRACE LIMIT") 
				break 
			end

			-- prepare next nonsolid trace
			if tr.Entity:IsPlayer() /*or tr.Entity:GetClass() == "prop_ragdoll"*/ then
				filter = tr.Entity 
			elseif tr.Entity:IsValid() and tr.Entity:GetClass() == "prop_physics" then
				filter = tr.Entity 
			-- elseif tr.Entity == NULL then
			-- 	filter = tr.Entity 
			end

		end

		print("\tpierced depth: ", pierced_depth, max_depth)
		--draw_line(bdata.Src, exit_pos)
		print()
		return

	--end)


	
end)

--hook.Remove(hook_type, hook_name)