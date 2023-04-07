-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end


/*
	on bullet fired
	get trace bdata.startpos - bdata.direction * 10000
	returns list of ents it passed through


*/

function myDot(a, b)
    return (a[1] * b[1]) + (a[2] * b[2]) + (a[3] * b[3])
end
function myMag(a)
    return math.sqrt((a[1] * a[1]) + (a[2] * a[2]) + (a[3] * a[3]))
end
function get_angle(vec1, vec2)
	return math.abs(math.deg(math.acos(myDot(vec1, vec2) / (myMag(vec1) * myMag(vec2)))) - 180)
end

local function see_table(t)
	for x,y in pairs(t) do
		print(x,y)
	end
	print()
end


local function penetrate(origin, dir, interval, max_intervals)
	local in_solid = true
	local checks = 0
	local next_pos = origin + (dir*interval)
	while in_solid and checks < max_intervals do
		next_pos = next_pos + (dir*interval)
		in_solid = (util.PointContents(next_pos)==CONTENTS_SOLID)
		checks = checks + 1
	end
	return next_pos -- returns position at which bullet exited the solid
end

local function impact(ent, origin, start, surface_props)
	local eff = EffectData()
	eff:SetEntity(ent)
	eff:SetOrigin(origin)
	eff:SetStart(start)
	eff:SetSurfaceProp(surface_props)
	eff:SetDamageType(DMG_BULLET)
	eff:SetHitBox(1)
	util.Effect("Impact", eff)
end

local function fmj_sparks(origin, normal)
	local eff = EffectData()
	eff:SetOrigin(origin)
	eff:SetNormal(normal)
	util.Effect("MetalSpark", eff)
end

local function exit_effects(tr, exit_loc, fmj_dir)

	impact(tr.Entity, tr.HitPos, tr.HitPos, tr.SurfaceProps)

	-- fmj reverse trace for exit decal
	local tr_reverse = util.TraceLine({
		start = exit_loc,
		endpos = exit_loc + (-fmj_dir*100)
	})

	fmj_sparks(tr_reverse.HitPos, -tr_reverse.Normal)
	util.Decal("Impact.Concrete", exit_loc, exit_loc - (fmj_dir*10))

end


if SERVER then

	local hook_type = "EntityFireBullets"
	local hook_name = hook_type.."fmj"

	hook.Add(hook_type, hook_name, function( shooter, bdata )

		if bdata.Num > 1 then return end

		local max_thickness = 50

		local exit_loc = nil
		local thickness = nil

		-- initial trace
		local spreadx = math.random(bdata.Spread.x*200)/100 - bdata.Spread.x
		local spready = math.random(bdata.Spread.y*200)/100 - bdata.Spread.y
		local fmj_dir = bdata.Dir + Vector(spreadx, spready, 0)
		local tr = util.TraceLine({
			start = bdata.Src,
			endpos = bdata.Src + (fmj_dir*10000),
			filter = shooter
		})

		if tr.HitSky then return end
		--if get_angle(tr.Normal, tr.HitNormal) > 60 then return end

		local exit_loc = penetrate(tr.HitPos, fmj_dir, 2, 20)
		thickness = math.sqrt(_get_euc_dist(tr.HitPos, exit_loc))
		if thickness > max_thickness then return end

		timer.Simple(2, function()

			exit_effects(tr, exit_loc, fmj_dir)

			-- fmj continued trace
			local fmj_filter = nil
			if tr.Entity:IsPlayer() then
				fmj_filter = tr.Entity
			end
			local tr2 = util.TraceLine({
				start = exit_loc,
				endpos = exit_loc + (fmj_dir*10000),
				filter = fmj_filter
			})
			if tr2.HitSky then return end

			-- apply damage and effects
			tr2.Entity:TakeDamage(bdata.Damage, shooter, shooter:GetActiveWeapon())
			impact(tr2.Entity, tr2.HitPos, tr2.HitPos, tr2.SurfaceProps)

			if tr2.Entity:IsPlayer() then
				local eff = EffectData()
				eff:SetOrigin(tr2.HitPos)
				util.Effect("BloodImpact", eff)
			else 
				-- final bullet impact
				util.Decal("Impact.Concrete", exit_loc, exit_loc + (fmj_dir*10000))
				if IsValid(tr2.Entity:GetPhysicsObject()) then
					tr2.Entity:GetPhysicsObject():SetVelocity(fmj_dir*bdata.Force*5)
				end
			end

		end)
		
	end)

	--hook.Remove(hook_type, hook_name)

end
