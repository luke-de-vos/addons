print("Executed lua: " .. debug.getinfo(1,'S').source)

-- helpers

local function add_hook_til_prep(hook_type, hook_name, hook_function)

    hook.Add(hook_type, hook_name, hook_function)

    hook.Add("TTTPrepareRound", hook_name.."remove_on_prep", function()
        hook.Remove(hook_type, hook_name)
        hook.Remove("TTTPrepareRound", hook_name.."remove_on_prep")
    end)

end

local function remove_timer_on_prepare(timer_name)
    hook.Add("TTTPrepareRound", timer_name.."remove_timer_on_prepare", function()
        timer.Remove(timer_name)
        hook.Remove("TTTPrepareRound", timer_name.."remove_timer_on_prepare")
    end)
end

local function count_pairs(my_table)
    local count = 0
    for x,y in pairs(my_table) do
        count = count + 1
    end
    return count
end

local function restrict(ply, weapon_class)
    if not ply:HasWeapon(weapon_class) then
        ply:Give(weapon_class)
    end
    ply:SelectWeapon(weapon_class)
    add_hook_til_prep("PlayerSwitchWeapon", ply:SteamID..'_restricted', function(ply, oldwep, newwep)
        ply:SetActiveWeapon(weapon_class)
    end)
end

-- effects

local function butter_fingers()

    if CLIENT then return end

    timer_name = "butter_fingers_timer"
    remove_timer_on_prepare(timer_name)
    timer.Create(timer_name, 5, 999, function()

        local ind = nil
        local done = false
        
        while not done do
            ply = Entity(math.random(#player.GetAll()))
            if ply:Alive() then
                done = true
                if ply:GetActiveWeapon():GetClass() == 'weapon_ttt_unarmed' then return end
                if ply:GetActiveWeapon():GetClass() == 'weapon_zm_carry' then return end
                ply:DropWeapon()
                ply:SelectWeapon("weapon_ttt_unarmed")
                ply:EmitSound("WeaponFrag.Roll")
            end
        end

    end)

    SendColouredChat("Butter fingers!")

end

local function crowbar_zombies()

    if CLIENT then return end

    RunConsoleCommand("ttt_innocent_shop_fallback","DISABLED") -- just in case

    -- swap non-traitors and traitors
    for i, iply in ipairs(player.GetAll()) do
        if iply:GetRole() != ROLE_TRAITOR then
            RunConsoleCommand("ulx", "force", iply:Nick(), "traitor")
            restrict(iply, "weapon_zm_improvised")
        else
            RunConsoleCommand("ulx", "force", iply:Nick(), "innocent")
        end
    end

    SendColouredChat("How many times do we have to teach you this lesson, old man?")

end

local function fade_to_black()

    if CLIENT then return end

    local fade_time = 1
    local duration = 5
    for i,ply in ipairs(player.GetAll()) do
        if ply:GetRole() == ROLE_TRAITOR then 
            ply:ScreenFade(2, color_black, fade_time, duration)
        end
    end
    SendColouredChat("See no evil...")
    timer.Simple(fade_time + duration, function()
        SendColouredChat("The darkness passes.")
    end)

end

local function first_to_jump()

    if CLIENT then return end

    local hook_type = "KeyPress"
    local hook_name = "first_to_jump"..hook_type

    add_hook_til_prep(hook_type, hook_name, function(ply, key)

        if key == IN_JUMP then
            hook.Remove(hook_type, hook_name)
            SendColouredChat(ply:Nick().." jumped first!")
            restrict(ply, "weapon_zm_improvised")
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

local function huges()

end

local function invert_damage()

    if CLIENT then return end

    local hook_type = "EntityTakeDamage"
    local hook_name = "invert_damage_"..hook_type

    add_hook_til_prep(hook_type, hook_name, function(victim, dinfo)
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

    add_hook_til_prep(hook_type, hook_name, function(ply, key)

        if key == IN_JUMP then

            who_jumped[ply:EntIndex()] = true

            if count_pairs(who_jumped) == #player.GetAll() - 1 then
                for i,iply in ipairs(player.GetAll()) do
                    if who_jumped[iply:EntIndex()] == nil then
                        hook.Remove(hook_type, hook_name) 
                        SendColouredChat(iply:Nick().." was the last to jump!")
                        restrict(iply, "weapon_zm_improvised")
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

    add_hook_til_prep(hook_type, hook_name, function(vic, dinfo)

        if vic:IsPlayer() and dinfo:GetDamage() > 0 then

            who_got_hurt[vic:EntIndex()] = true

            if count_pairs(who_got_hurt) == #player.GetAll() - 1 then -- why is #who_got_hurt jumping from 0 to numplayers?
                for i,iply in ipairs(player.GetAll()) do
                    if who_got_hurt[iply:EntIndex()] == nil then
                        hook.Remove(hook_type, hook_name)
                        SendColouredChat(iply:Nick().." took damage last!")
                        restrict(iply, "weapon_zm_improvised")
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

    add_hook_til_prep(hook_type, hook_name, function(entity, bdata)
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
            ply1:EmitSound("Weapon_Crossbow.Single")
            ply2:EmitSound("Weapon_Crossbow.Single")
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
    butter_fingers()
end)
--hook.Remove("TTTBeginRound", "random_effects_begin_round")


