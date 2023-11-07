print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then

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









    


    local function place_cam_ent()
        local cam_ent = ents.Create("prop_dynamic")
        cam_ent:SetModel("models/error.mdl")
        cam_ent:Spawn()
        cam_ent:SetMoveType(MOVETYPE_FLY) --MOVETYPE_NONE
        cam_ent:SetRenderMode(RENDERMODE_NONE)
        cam_ent:SetSolid(SOLID_NONE)
        return cam_ent
    end

    local function watch_cam(cam_ent, focus_ent, slo_scale, duration)
        -- update player povs
        for i,ply in ipairs(player.GetAll()) do
            if ply:Nick() == focus_ent:Nick() then continue end
            ply:SetViewEntity(cam_ent)
            ply:Spectate(OBS_MODE_ROAMING)
		    ply:SpectateEntity(focus_ent)
            ply:CrosshairDisable()
        end
        timer.Simple(0.05, function() -- sliiight delay. Looks better
            game.SetTimeScale(slo_scale)
            -- revert after duration
            timer.Simple(duration * slo_scale, function()
                game.SetTimeScale(1.0)
                for i,ply in ipairs(player.GetAll()) do
                    ply:SetViewEntity(ply)
                    ply:UnSpectate()
                    ply:DrawViewModel(true)
                    ply:DrawWorldModel(true)
                    ply:CrosshairEnable()
                end
                cam_ent:Remove()
            end)
        end)
    end

    function _highlight_kill(victim, attacker, slo_scale, duration)
        -- make camera ent and put in place
        local cam_ent = place_cam_ent()
        local vp = victim:GetPos()
        local ap = attacker:GetPos()
        local offset = _normalize_vec((vp - ap), 100)
        local cp = vp + offset + Vector(0,0,10)
        --cam_ent:SetPos(cp)
        --cam_ent:SetAngles(((ap - cp + Vector(0,0,65))):Angle()) -- x-y, gives angle from y to x
        watch_cam(cam_ent, attacker, slo_scale, duration)
    end





    function _new_highlight(victim, attacker, slo_scale, duration)
        game.SetTimeScale(slo_scale)
        --victim:SpectateEntity(attacker)
        --victim:SetObserverMode(OBS_MODE_DEATHCAM)

        for i,ply in ipairs(player.GetAll()) do
            ply:SetViewEntity(victim)
        end

        -- revert
        timer.Simple(duration * slo_scale, function()
            game.SetTimeScale(1.0)
            for i,ply in ipairs(player.GetAll()) do
                ply:SetViewEntity(ply)
                ply:UnSpectate()
                --ply:Spawn()
            end
        end)

    end

    hook.Add("PlayerDeath","do_slow_mo", function(vic, inflictor, attacker)
        --_highlight_kill(vic, attacker, 0.25, 4)
        timer.Simple(0.1, function()
            _new_highlight(vic, attacker, 0.5, 3)
        end)
    end)
    hook.Remove("PlayerDeath","do_slow_mo")

    hook.Add("EntityFireBullets", "follow_bullet", function(shooter, bdata)
        local slo_scale = 0.1
        local duration = 3
        game.SetTimeScale(slo_scale)
        cam_ent = place_cam_ent()
        cam_ent:SetAngles(shooter:GetAimVector():Angle())
        cam_ent:SetPos(shooter:GetShootPos())
        shooter:SetViewEntity(cam_ent)
        shooter:SetObserverMode(OBS_MODE_FIXED)
        --cam_ent:ApplyForceCenter(Vector(0,0,100))
        cam_ent:SetVelocity(shooter:GetAimVector()*1000)
        print('shot')
        timer.Simple(duration * slo_scale, function()
            print('x')
            game.SetTimeScale(1.0)
            if IsValid(cam_ent) then
                cam_ent:Remove()
                shooter:SetObserverMode(OBS_MODE_NONE)
                shooter:SetViewEntity(shooter)
                shooter:UnSpectate()
            end
        end)
    end)
    hook.Remove("EntityFireBullets","follow_bullet")

    --Entity(1):SetObserverMode(OBS_MODE_NONE)
    --Entity(1):SetObserverMode(OBS_MODE_NONE)
    --Entity(1):SpectateEntity(Entity(1))
    --Entity(1):SetObserverMode(OBS_MODE_FIXED)

    --Entity(1):SetViewEntity(Entity(1))
    --Entity(1):SetObserverMode(OBS_MODE_DEATHCAM)

    --Entity(1):UnSpectate()
    --Entity(1):SetViewEntity(Entity(1))




    --Entity(2):SetViewEntity(Entity(1))




end

-- colored chat
if SERVER then 
    util.AddNetworkString( "SendColouredChat" )
    -- send colored chat to all players
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