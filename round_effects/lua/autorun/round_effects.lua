print("Executed lua: " .. debug.getinfo(1,'S').source)

local function count_pairs(my_table)
    local count = 0
    for x,y in pairs(my_table) do
        count = count + 1
    end
    return count
end

-- helpers
local function remove_hook_on_prepare(hook_type, hook_name)
    hook.Add("TTTPrepareRound", hook_name.."remove_hook_on_prepare", function()
        print("Removed "..hook_type..", "..hook_name)
        hook.Remove(hook_type, hook_name)
        hook.Remove("TTTPrepareRound", hook_name.."remove_hook_on_prepare")
    end)
end

local function remove_timer_on_prepare(timer_name)
    hook.Add("TTTPrepareRound", timer_name.."remove_timer_on_prepare", function()
        timer.Remove(timer_name)
        hook.Remove("TTTPrepareRound", timer_name.."remove_timer_on_prepare")
    end)
end

local function banish_to_crowbar_hell(ply)

    if CLIENT then return end

    ply:SelectWeapon("weapon_zm_improvised")

    hook_type = "EntityTakeDamage"
    hook_name = "crowbar_hell"..ply:SteamID()

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(vic, dinfo)
        if dinfo:GetAttacker():SteamID() == ply:SteamID() then
            if dinfo:GetInflictor():GetClass() != "weapon_zm_improvised" then
                dinfo:SetDamage(0)
            end
        end
    end)

end

-- effects

local function crowbar_zombies()

    if CLIENT then return end

    SendColouredChat("How many times do we have to teach you this lesson, old man?")

    local hook_type = "EntityTakeDamage"
    local hook_name = "crowbar_zombies"..hook_type

    -- traitors can only deal damage with crowbar
    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(vic, dinfo)
        if dinfo:GetInflictor():GetClass() != "weapon_zm_improvised" then
            if dinfo:GetAttacker():IsPlayer() and dinfo:GetAttacker():GetRole() == ROLE_TRAITOR then
                dinfo:SetDamage(0)
            end
        end
    end)

    -- swap non-traitors and traitors
    for i, iply in ipairs(player.GetAll()) do
        if iply:GetRole() != ROLE_TRAITOR then
            RunConsoleCommand("ulx", "force", iply:Nick(), "traitor")
            iply:SelectWeapon("weapon_zm_improvised")
            --RunConsoleCommand("ttt_traitor_shop_fallback","DISABLED")
            RunConsoleCommand("ttt_innocent_shop_fallback","DISABLED") -- just in case
        else
            RunConsoleCommand("ulx", "force", iply:Nick(), "innocent")
        end
    end

    -- re-enable t shop next prepareround
    hook.Add("TTTPrepareRound", "round_effects_reenable_tshop", function()
        RunConsoleCommand("ttt_traitor_shop_fallback","traitor")
        hook.Remove("TTTPrepareRound", "round_effects_reenable_tshop")
    end)

end

local function first_to_jump()

    if CLIENT then return end

    local hook_type = "KeyPress"
    local hook_name = "first_to_jump"..hook_type

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(ply, key)

        if key == IN_JUMP then
            hook.Remove(hook_type, hook_name)
            SendColouredChat(ply:Nick().." jumped first!")
            banish_to_crowbar_hell(ply)
        end

    end)

    SendColouredChat("JIUMP!")

end

local function high_grav()

    if CLIENT then return end

    RunConsoleCommand("sv_gravity", "4000")
    hook.Add("TTTPrepareRound", "low_grav_prepare_round", function()
        RunConsoleCommand("sv_gravity", "600")
        hook.Remove("TTTPrepareRound", "low_grav_prepare_round")
    end)

    SendColouredChat("Extreme gravity enabled!")

end

local function invert_damage()

    if CLIENT then return end

    local hook_type = "EntityTakeDamage"
    local hook_name = "invert_damage_"..hook_type

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(victim, dinfo)
        if dinfo:GetDamage() > 0 then
            dinfo:SetDamage(math.max(50 - dinfo:GetDamage(), 0))
        end
    end)

    SendColouredChat("Less is more...")

end

local function last_to_jump()

    if CLIENT then return end

    local hook_type = "KeyPress"
    local hook_name = "last_to_jump"..hook_type
    local who_jumped = {}

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(ply, key)

        if key == IN_JUMP then

            who_jumped[ply:EntIndex()] = true

            if count_pairs(who_jumped) == #player.GetAll() - 1 then

                for i,iply in ipairs(player.GetAll()) do

                    if who_jumped[iply:EntIndex()] == nil then
                        hook.Remove(hook_type, hook_name) 
                        SendColouredChat(iply:Nick().." was the last to jump!")
                        banish_to_crowbar_hell(iply)
                    end

                end

            end

        end

    end)

    SendColouredChat("JUMP!")
    
end

local function last_to_take_damage()

    if CLIENT then return end

    local hook_type = "EntityTakeDamage"
    local hook_name = "last_to_take_damage"..hook_type
    local who_got_hurt = {}

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(vic, dinfo)

        if vic:IsPlayer() and dinfo:GetDamage() > 0 then

            who_got_hurt[vic:EntIndex()] = true

            if count_pairs(who_got_hurt) == #player.GetAll() - 1 then -- why is #who_got_hurt jumping from 0 to 4?
                
                for i,iply in ipairs(player.GetAll()) do
                    
                    if who_got_hurt[iply:EntIndex()] == nil then
                        hook.Remove(hook_type, hook_name)
                        SendColouredChat(iply:Nick().." took damage last!")
                        banish_to_crowbar_hell(iply)
                    end

                end

            end

        end

    end)

    SendColouredChat("PURPLE HEART SPEEDRUN")

end

local function low_grav()

    if CLIENT then return end

    RunConsoleCommand("sv_gravity", "10")
    hook.Add("TTTPrepareRound", "low_grav_prepare_round", function()
        RunConsoleCommand("sv_gravity", "600")
        hook.Remove("TTTPrepareRound", "low_grav_prepare_round")
    end)

    SendColouredChat("Low gravity enabled!")

end

local function shoot_boost()

    if CLIENT then return end

    local hook_type = "EntityFireBullets"
    local hook_name = "shoot_boost_"..hook_type

    remove_hook_on_prepare(hook_type, hook_name)
    hook.Add(hook_type, hook_name, function(entity, bdata)
        entity:SetVelocity(-entity:GetAimVector() * 300)
    end)

    SendColouredChat("What's in these bullets?")

end

local function slaps()

    if CLIENT then return end

    -- initial slap
    for i, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            RunConsoleCommand("ulx", "slap", ply:Nick(), 5)
        end
    end

    -- slap every player on an interval
    local timer_name = "slap_timer"

    remove_timer_on_prepare(timer_name)
    timer.Create(timer_name, 15, 999, function()
        local alive = {}
        for i, ply in ipairs(player.GetAll()) do
            if ply:Alive() then
                RunConsoleCommand("ulx", "slap", ply:Nick(), 5)
            end
        end
    end)

    SendColouredChat("SLAP CITY, SLAP SLAP SLAP CITY")

end

local function switcheroo()

    if CLIENT then return end

    local timer_name = "switch_timer"

    remove_timer_on_prepare(timer_name)
    timer.Create("switch_timer", 15, 999, function()

        local alive = {}

        for i, ply in ipairs(player.GetAll()) do
            if ply:Alive() then
                table.insert(alive, ply:EntIndex())
            end
        end

        if #alive > 1 then
            SendColouredChat("Switch!")
            local i1 = math.random(#alive)
            local i2 = i1
            while i1 == i2 do
                i2 = math.random(#alive)
            end
            local ply1 = Entity(alive[i1])
            local ply2 = Entity(alive[i2])
            local temp = ply1:GetPos()
            ply1:SetPos(ply2:GetPos())
            ply2:SetPos(temp)
            ply1:EmitSound("FuncTank.Fire")
            ply2:EmitSound("FuncTank.Fire")
        end

    end)

    SendColouredChat("SWITCHIN TIME")

end

-- prompt effects

local options = {
    crowbar_zombies, 
    first_to_jump, 
    high_grav, 
    invert_damage, 
    last_to_jump, 
    last_to_take_damage, 
    low_grav, 
    shoot_boost, 
    slaps, 
    switcheroo}

hook.Add("TTTBeginRound", "random_effects_begin_round", function()
    if CLIENT then return end
    --options[math.random(#options)]()
    crowbar_zombies()
end)
--hook.Remove("TTTBeginRound", "random_effects_begin_round")


