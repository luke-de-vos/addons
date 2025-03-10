print("Executed lua: " .. debug.getinfo(1,'S').source)

if SERVER then

    -- GAMEPLAY
    function _respawn(ply, delay)
        if IsValid(ply) then
            timer.Simple(delay, function() 
                if IsValid(ply) then
                    RunConsoleCommand("ulx", "respawn", ply:Name()) 
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
        util.Effect("Explosion", effect, true, true)
        util.BlastDamage(inflictor, attacker, pos, radius, damage) -- radius, damage
    end

    function _headshot_effect(victim)
        local effect = EffectData()
        local pos = victim:GetPos()
        pos.z = pos.z + 65
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetScale(1)
        util.Effect("ccamera_explode", effect, true, true)
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

-- colored chat to one player
if SERVER then 
    util.AddNetworkString( "SendColouredChat1" )
    -- send colored chat to all players
    function SendColouredChat1( ply, text, color ) -- color e.g. Color(255,0,0,255)
        net.Start( "SendColouredChat1" )
            net.WriteTable( color )
            net.WriteString( text )
        net.Send(ply)
    end
end

if CLIENT then 
    function ReceiveColouredChat()
        local color = net.ReadTable()
        local str = net.ReadString()
        chat.AddText( color, str )
    end
    net.Receive( "SendColouredChat1", ReceiveColouredChat )
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




-- -- loading bar
-- if CLIENT then
--     local isDrawing, startTime, duration

--     -- Function to start the loading bar
--     function StartLoadingBar(duration)
--         duration = duration
--         startTime = CurTime()
--         isDrawing = true
--     end

--     hook.Add("HUDPaint", "DrawSimpleLoadingBar", function()
--         if not isDrawing then return end

--         local scrW = ScrW()
--         local scrH = ScrH() + 120
--         local barWidth = 150
--         local barHeight = 15
--         local progress = math.Clamp((CurTime() - startTime) / duration, 0, 1)

--         -- Stop drawing when the loading is complete
--         if progress >= 1 then
--             isDrawing = false
--         end

--         -- Drawing the background of the loading bar
--         draw.RoundedBox(4, (scrW / 2) - (barWidth / 2), (scrH / 2) - (barHeight / 2), barWidth, barHeight, Color(50, 50, 50, 200))

--         -- Drawing the filled part of the loading bar
--         draw.RoundedBox(4, (scrW / 2) - (barWidth / 2), (scrH / 2) - (barHeight / 2), barWidth * progress, barHeight, Color(100, 200, 100, 200))
--     end)

--     -- Example usage: Start the loading bar for 5 seconds
--     StartLoadingBar(duration)
-- end

-- if SERVER then
--     -- code to send loading bar to client from server
--     util.AddNetworkString("StartLoadingBar")

--     function StartLoadingBar(ply, duration)
--         net.Start("StartLoadingBar")
--         net.WriteFloat(duration)
--         net.Send(ply)
--     end

-- end



if CLIENT then
    -- Function to draw halos around all other players
    local function DrawPlayerHalos()
        hook.Add("PreDrawHalos", "DrawPlayerHalos", function()
            local players = player.GetAll()
            local localPlayer = LocalPlayer()
            local otherPlayers = {}
            
            for _, ply in ipairs(players) do
                if ply ~= localPlayer and ply:Alive() then
                    table.insert(otherPlayers, ply)
                end
            end
            
            halo.Add(otherPlayers, Color(255, 0, 0), 2, 2, 1, true, true)
        end)
    end
--hook.Remove("PreDrawHalos", "DrawPlayerHalos")

    -- add above hook to a console command. 1 for on, 0 for off
    concommand.Add("halos", function(ply, cmd, args)
        if not LocalPlayer():IsAdmin() then return end -- check permission
        if args[1] == "1" then
            DrawPlayerHalos()
        elseif args[1] == "0" then
            hook.Remove("PreDrawHalos", "DrawPlayerHalos")
        end
    end)
end



-- -- Forcefully prevent GrabEarAnimation in all cases
-- hook.Add("GrabEarAnimation", "ForcePreventGrabEarAnimation", function()
--     -- Always return true to prevent the animation from playing
--     return true
-- end)
-- hook.Remove("GrabEarAnimation", "ForcePreventGrabEarAnimation")

