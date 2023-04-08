-- fmj. bullet penetration
if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end


/*

*/

if SERVER then
	util.AddNetworkString( "send_line_message" )
	function draw_line(a, b)
		net.Start( "send_line_message" )
			net.WriteVector( a )
			net.WriteVector( b )
		net.Broadcast()
	end
end
if CLIENT then
	local my_color1 = Color(150, 0, 0)
	local my_color2 = Color(0, 200, 0)
	local a = nil
	local b = nil
	net.Receive( "send_line_message", function(len)
		a = net.ReadVector()
		b = net.ReadVector()
	end )
	hook.Add( "PostDrawTranslucentRenderables", "MySuper3DRenderingHook", function()
		if a == nil then return end
		render.DrawLine( a, b, my_color1, false )
		render.DrawLine( a, b, my_color2, true )
	end )
end

if SERVER then
	util.AddNetworkString( "send_sphere_message" )
	function draw_sphere(pos)
		net.Start( "send_sphere_message" )
			net.WriteVector( pos)
		net.Broadcast()
	end
end
if CLIENT then
	local my_color1 = Color(150, 0, 0)
	local my_color2 = Color(0, 200, 0)
	fmj_spheres = {}
	net.Receive( "send_sphere_message", function(len)
		table.insert(fmj_spheres, net.ReadVector())
	end )
	hook.Add( "PostDrawTranslucentRenderables", "draw_sphere_debug", function()
		for i,vec in ipairs(fmj_spheres) do
			render.DrawWireframeSphere(vec, 5, 20, 5, my_color1, false)
			render.DrawWireframeSphere(vec, 5, 20, 5, my_color2, true)
			render.DrawWireframeSphere(vec, 0.5, 20, 5, my_color1, false)
			render.DrawWireframeSphere(vec, 0.5, 20, 5, my_color2, true)
		end
	end )
end

-- math helpers
if SERVER or CLIENT then
	function get_euc_dist(vec1, vec2)
		local dvec = vec2 - vec1
		dvec.x = dvec.x^2
		dvec.y = dvec.y^2
		dvec.z = dvec.z^2
		return math.sqrt(dvec.x + dvec.y + dvec.z)
	end

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
end


local function impact(tr)
	if !IsFirstTimePredicted() then return end
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
	local eff = EffectData()
	eff:SetOrigin(tr.StartPos)
	eff:SetNormal(-tr.Normal)
	util.Effect("MetalSpark", eff)
end


local function get_next_empty_pos(origin, dir, max_depth)
	local depth = 0
	local next_pos = origin
	while true do
		next_pos = next_pos + dir
		depth = depth + 1
		print('\t', util.PointContents(next_pos))
		if util.PointContents(next_pos) == CONTENTS_EMPTY then
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
	if IsValid(tr.Entity) then -- world entity is not valid
		tr.Entity:TakeDamage(bdata.Damage, bdata.Attacker, bdata.Attacker:GetActiveWeapon())
	end
	-- if body, do blood. else, do force
	if tr.Entity:IsPlayer() /*or tr.Entity:GetClass() == "prop_ragdoll"*/ then
		local eff = EffectData()
		eff:SetOrigin(tr.HitPos)
		util.Effect("BloodImpact", eff)
	else 
		if IsValid(tr.Entity) and IsValid(tr.Entity:GetPhysicsObject()) then
			tr.Entity:GetPhysicsObject():SetVelocity(fmj_dir*bdata.Force*10)
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
	local spreadx = math.random(0, bdata.Spread.x*100)/100 - (bdata.Spread.x/2)
	local spready = math.random(0, bdata.Spread.y*100)/100 - (bdata.Spread.y/2)
	local fmj_dir = bdata.Dir + Vector(spreadx, spready, 0)
	local start = nil
	local filter = nil
	local this_depth = nil
	local exit_pos = nil
	local tr = nil

	-- measurement
	local traceno = 1
	local pierced_depth = 0
	local max_depth = 100

	print()

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
	
		draw_sphere(tr.StartPos) -- exit_pos becomes next tr.StartPos
		draw_sphere(tr.HitPos)

		if tr.HitSky then 
			print("Exit: sky") 
			exit_pos = tr.HitPos
			break 
		end

		-- damage, force, sounds, effects
		if traceno > 1 then
			bullet_entry(tr, fmj_dir, bdata)
		end

		exit_pos, this_depth = get_next_empty_pos(tr.HitPos, fmj_dir, max_depth-pierced_depth)
		if pierced_depth + this_depth > max_depth then 
			print("HIT DEPTH LIMIT") 
			break 
		end
		pierced_depth = pierced_depth + this_depth

		--if get_angle(tr.Normal, tr.HitNormal) > 60 then return end

		print("Penetrated ", tr.Entity, this_depth)

		bullet_exit(exit_pos, fmj_dir)

		traceno = traceno + 1
		if traceno > 50 then print("HIT TRACE LIMIT") break end

		-- prepare next nonsolid trace
		if tr.Entity:IsPlayer() /*or tr.Entity:GetClass() == "prop_ragdoll"*/ then
			filter = tr.Entity 
		end

	end

	print("pierced depth: ", pierced_depth)
	draw_line(bdata.Src, exit_pos)
	print()
	return
	
end)

--hook.Remove(hook_type, hook_name)