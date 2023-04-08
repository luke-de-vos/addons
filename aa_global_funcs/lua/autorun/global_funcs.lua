print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then

    -- UTILITY
    function _get_roles()
        local role_counts = {0,0,0,0}
        local role_index = nil
        for i,ply in ipairs(player.GetAll()) do
            role_index = ply:GetRole() + 1
            if role_index > 4 then
                role_index = 4
            end
            role_counts[role_index] = role_counts[role_index] + 1
        end
        local role_names = {'inno','traitor','detective', 'misc'}
        for role_index, count in ipairs(role_counts) do
            print(role_names[role_index]..': '..count)
        end
    end

    _get_roles()

    function _normalize_vec(vec, new_hi)
        local new_vec = Vector(0,0,0)
        local max = math.max(unpack({math.abs(vec.x), math.abs(vec.y), math.abs(vec.z)}))
        new_vec.x = (vec.x/max)
        new_vec.y = (vec.y/max)
        new_vec.z = (vec.z/max)
        if new_hi != 1 then
            new_vec.x = new_vec.x * new_hi
            new_vec.y = new_vec.y * new_hi
            new_vec.z = new_vec.z * new_hi
        end
        return new_vec
    end

    function _get_euc_dist(vec1, vec2)
        -- note: does not take sqrt
        local dvec = vec2 - vec1
        dvec.x = dvec.x^2
        dvec.y = dvec.y^2
        dvec.z = dvec.z^2
        return dvec.x + dvec.y + dvec.z
    end

    function _my_split(s, delimiter)
        result = {};
        for match in (s..delimiter):gmatch("(.-)"..delimiter) do
            table.insert(result, match);
        end
        return result;
    end

    -- EFFECTS
    -- https://wiki.facepunch.com/gmod/Effects
    function _spark(pos)
        local effect = EffectData()
        effect:SetOrigin(pos)
        effect:SetMagnitude(1)
        effect:SetScale(1)
        effect:SetNormal(pos:GetNormal())
        effect:SetRadius(10)
        util.Effect("Sparks", effect, true, true)
    end

    function _effect(effect_name, origin, magnitude, radius, scale, start, flags)
        local effect = EffectData()
        effect:SetOrigin(origin)
        effect:SetNormal(origin:GetNormal())
        effect:SetMagnitude(magnitude)
        effect:SetRadius(radius)
        effect:SetScale(scale)
        if IsValid(start) then
            effect:SetStart(start)
            effect:SetFlags(flags)
        end
        util.Effect(effect_name, effect, true, true)
    end

    function _explosion(attacker, inflictor, pos, radius, damage)
        local effect = EffectData()
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetScale(1)
        effect:SetRadius(radius)
        effect:SetMagnitude(1)
        if IsValid(attacker) then
            util.Effect("Explosion", effect, true, true)
            util.BlastDamage(inflictor, attacker, pos, radius, damage) -- radius, damage
        end
    end

    function _headshot_effect(victim)
        local effect = EffectData()
        local pos = victim:GetPos()
        pos.z = pos.z + 65
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetScale(1)
        util.Effect("cball_explode", effect, true, true)
    end

    function _slash_effect(victim)
        local effect = EffectData()
        local pos = victim:GetPos()
        pos.z = pos.z + 10
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetFlags(3)
        effect:SetColor(0)
        effect:SetScale(6)
        util.Effect("bloodspray", effect, true, true)
    end

    function _print_kill(victim, attacker)
        if (attacker:IsPlayer()) then
            if victim:LastHitGroup() == 1 then
                PrintMessage(HUD_PRINTTALK, attacker:GetName().." killed (X) "..victim:GetName())
            else
                PrintMessage(HUD_PRINTTALK, attacker:GetName().." killed "..victim:GetName())
            end
        else
            PrintMessage(HUD_PRINTTALK, victim:GetName() .. " died.")
        end
    end

    function _highlight_kill(victim, attacker, slo_scale, duration)
        -- make camera ent and put in place
        local cam_ent = ents.Create("prop_dynamic")
        cam_ent:SetModel("models/error.mdl")
        cam_ent:Spawn()
        cam_ent:SetMoveType(MOVETYPE_NONE)
        cam_ent:SetRenderMode(RENDERMODE_NONE)
        cam_ent:SetSolid(SOLID_NONE)
        local vp = victim:GetPos()
        local ap = attacker:GetPos()
        local dvec = vp - ap --x-y, offset pushes vector from y through x
        local offset = _normalize_vec(dvec, 100)
        local cp = vp
        cp = vp + offset
        cp.z = cp.z + 10
        cam_ent:SetPos(cp)
        local cam_angle = (ap - cp)
        cam_angle.z = cam_angle.z + 65
        cam_ent:SetAngles((cam_angle):Angle()) -- x-y, gives angle from y to x
        -- update player povs
        for i,ply in ipairs(player.GetAll()) do
            ply:SetViewEntity(cam_ent)
            ply:CrosshairDisable()
        end
        timer.Simple(0.05, function() -- sliiight delay. Looks better
            game.SetTimeScale(slo_scale)
            -- revert after duration
            timer.Simple(duration * slo_scale, function()
                game.SetTimeScale(1.0)
                for i,ply in ipairs(player.GetAll()) do
                    ply:SetViewEntity(ply)
                    ply:CrosshairEnable()
                end
                cam_ent:Remove()
            end)
        end)
    end

    -- GAMEPLAY
    function _respawn(ply, delay)
        if IsValid(ply) then
            timer.Simple(delay, function() 
                if IsValid(ply) then
                    RunConsoleCommand("ulx", "respawn", ply:Name()) 
                    timer.Simple(0.2, function() ply:SetHealth(ply:GetMaxHealth()) end)
                end
            end)
        end
    end

    function _give_current_ammo(ply, num_mags)
        local wep = ply:GetActiveWeapon()
        if (!IsValid(wep)) then return end
        local ammo_type = wep:GetPrimaryAmmoType()
        local mag_size = wep:GetMaxClip1()
        ply:GiveAmmo(mag_size*num_mags, ammo_type, false)
    end

    -- HOOK MANAGEMENT
    local mode_hooks = {}

    function _parse_command(sender, text, accept_command)
        if sender:GetUserGroup() == "user" then return end
        if text:sub(1,1) != "!" then return end
        local args = _my_split(text, " ")
        if args[1] == accept_command then
            return args
        else
            return
        end
    end 

    function _change_mode(mode_hooks)
        _drop_hooks()
        for func in mode_hooks do
            _add_hook(func)
        end
    end
    
    function _add_hook(hook_type, hook_name, hook_func)
        table.insert(mode_hooks, {hook_type, hook_name})
        hook.Add(hook_type, hook_name, hook_func)
        print("Added hook (" .. hook_type .. " " .. hook_name .. ")")
    end

    function _drop_hooks()
        print("Removing "..#mode_hooks.." hooks.")
        for index, entry in ipairs(mode_hooks) do
            print("Removed hook ("..entry[1]..", "..entry[2]..").")
            hook.Remove(entry[1], entry[2])
        end
        mode_hooks = {}
    end
end

-- colored chat
if SERVER then 
    util.AddNetworkString( "SendColouredChat" )
    function SendColouredChat( text )
        net.Start( "SendColouredChat" )
            net.WriteTable( Color( 255, 255, 0, 255 ) )
            net.WriteString(text )
        net.Broadcast()
    end
end

if CLIENT then 
    function ReceiveColouredChat()
        local color = net.ReadTable()
        local str = net.ReadString()
        chat.AddText( color, str )
    end
    net.Receive( "SendColouredChat", ReceiveColouredChat )
end




-- line and ball debugging
if SERVER then
	util.AddNetworkString( "send_line_message" )
	function draw_line(a, b)
		net.Start( "send_line_message" )
			net.WriteVector( a )
			net.WriteVector( b )
		net.Broadcast()
	end
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