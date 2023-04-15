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
    add_hook_til_prep("PlayerSwitchWeapon", ply:SteamID()..'_restrict', function(hookply, oldwep, newwep)
        if hookply:SteamID() != ply:SteamID() then return end
        if newwep:GetClass() != weapon_class and newwep:GetClass() != "weapon_ttt_unarmed" then
            --newwep:Remove()
            timer.Simple(0.3, function()
                if IsValid(hookply) and hookply:Alive() then
                    hookply:SelectWeapon(weapon_class)
                    hookply:ChatPrint("You are restricted to "..weapon_class..".")
                end
            end)
            
            -- timer.Simple(0.1, function() 
            --     if ply:HasWeapon(weapon_class) then 
            --         ply:SelectWeapon(weapon_class)
            --     else
            --         ply:SelectWeapon("weapon_ttt_unarmed")
            --     end 
            -- end)
        end
    end)
end

-- effects

local function butter_fingers()

    if CLIENT then return end

    timer_name = "butter_fingers_timer"
    remove_timer_on_prepare(timer_name)
    timer.Create(timer_name, 10, 999, function()

        local ind = nil
        local done = false
        
        while not done do
            ply = Entity(math.random(#player.GetAll()))
            if ply:Alive() then
                done = true
                if not IsValid(ply:GetActiveWeapon()) then return end
                if ply:GetActiveWeapon():GetClass() == 'weapon_ttt_unarmed' then return end
                if ply:GetActiveWeapon():GetClass() == 'weapon_zm_carry' then return end
                if ply:GetActiveWeapon():GetClass() == 'weapon_zm_improvised' then return end
                ply:DropWeapon()
                ply:SelectWeapon("weapon_ttt_unarmed")
                ply:EmitSound("WeaponFrag.Roll")
            end
        end

    end)

    SendColouredChat("Butter fingers")

end

local function crowbar_zombies()

    if CLIENT then return end

    RunConsoleCommand("ttt_innocent_shop_fallback","DISABLED") -- just in case

    -- swap non-traitors and traitors
    for i, iply in ipairs(player.GetAll()) do
        if iply:GetRole() != ROLE_TRAITOR then
            RunConsoleCommand("ulx", "force", iply:Nick(), "traitor")
        else
            RunConsoleCommand("ulx", "force", iply:Nick(), "innocent")
        end
    end
    timer.Simple(1.0, function()
        for i, iply in ipairs(player.GetAll()) do
            if iply:GetRole() == ROLE_TRAITOR then
                restrict(iply, "weapon_zm_improvised")
            end
        end
    end)

    SendColouredChat("Zombies")

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
    SendColouredChat("Traitors are blind for 5 seconds.")
    timer.Simple(fade_time + duration, function()
        SendColouredChat("The darkness passes.")
    end)

end

local function fire_sale()
    if CLIENT then return end
    RunConsoleCommand("ttt_inno_shop_fallback","traitor")
    hook.Add("TTTPrepareRound", "fire_sale_remove_on_prep", function()
        RunConsoleCommand("ttt_inno_shop_fallback","DISABLED")
        hook.Remove("TTTPrepareRound", "fire_sale_remove_on_prep")
    end)
    for i,ply in ipairs(player.GetAll()) do
        RunConsoleCommand("ulx","credits",ply:Nick(),3)
    end
    SendColouredChat("Fire sale")
end

local function first_to_jump()

    if CLIENT then return end

    local hook_type = "KeyPress"
    local hook_name = "first_to_jump"..hook_type

    
    add_hook_til_prep(hook_type, hook_name, function(ply, key)

        if key == IN_JUMP then
            hook.Remove(hook_type, hook_name)
            SendColouredChat(ply:Nick().." jumped first")
            restrict(ply, "weapon_zm_improvised")
        end

    end)

    SendColouredChat("JIUMP")

end

local function high_grav()

    if CLIENT then return end

    RunConsoleCommand("sv_gravity", "4000")
    hook.Add("TTTPrepareRound", "hi_grav_prepare_round", function()
        RunConsoleCommand("sv_gravity", "600")
        hook.Remove("TTTPrepareRound", "hi_grav_prepare_round")
    end)

    SendColouredChat("Super gravity")

end

local function huges()

    if CLIENT then return end

    for i,ply in ipairs(player.GetAll()) do
        restrict(ply, "weapon_zm_sledge")
        _give_current_ammo(ply, 4)
    end

    SendColouredChat("LET'S GET HUGE")

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
                        SendColouredChat(iply:Nick().." was the last to jump")
                        restrict(iply, "weapon_zm_improvised")
                    end

                end

            end

        end

    end)

    SendColouredChat("JUMP")
    
end

local function last_to_take_damage()

    if CLIENT then return end

    local hook_type = "EntityTakeDamage"
    local hook_name = "last_to_take_damage"..hook_type
    local who_got_hurt = {}

    add_hook_til_prep(hook_type, hook_name, function(vic, dinfo)

        if vic:IsPlayer() and dinfo:GetDamage() > 0 then

            who_got_hurt[vic:EntIndex()] = true

            if count_pairs(who_got_hurt) == #player.GetAll() - 1 then -- why is #who_got_hurt jumping from 0 to 4?
                
                for i,iply in ipairs(player.GetAll()) do
                    if who_got_hurt[iply:EntIndex()] == nil then
                        hook.Remove(hook_type, hook_name)
                        SendColouredChat(iply:Nick().." took damage last")
                        restrict(iply, "weapon_zm_improvised")
                    end
                end

            end

        end

    end)

    SendColouredChat("Last to take damage loses")

end

local function low_grav()

    if CLIENT then return end

    RunConsoleCommand("sv_gravity", "60")
    hook.Add("TTTPrepareRound", "low_grav_prepare_round", function()
        RunConsoleCommand("sv_gravity", "600")
        hook.Remove("TTTPrepareRound", "low_grav_prepare_round")
    end)

    SendColouredChat("Low gravity")

end

local function shoot_boost()

    if CLIENT then return end

    local hook_type = "EntityFireBullets"
    local hook_name = "shoot_boost_"..hook_type

    add_hook_til_prep(hook_type, hook_name, function(entity, bdata)
        entity:SetVelocity(-entity:GetAimVector() * bdata.Damage*20 * math.max(1, bdata.Num))
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

    SendColouredChat("Slaps")

end

local function super_speed()
    if CLIENT then return end
    speed_boost = 1.50
    for i,ply in ipairs(player.GetAll()) do
        ply:SetWalkSpeed(ply:GetWalkSpeed() * speed_boost)
    end
    hook.Add("TTTPrepareRound","fix_speed_change", function()
        for i,ply in ipairs(player.GetAll()) do
            ply:SetWalkSpeed(ply:GetWalkSpeed() * 1/speed_boost)
        end 
        hook.Remove("TTTPrepareRound","fix_speed_change")
    end)
    SendColouredChat("Speed boost")
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
            _effect("sparks", ply1:GetPos(), 5, 1, 1)
            _effect("sparks", ply2:GetPos(), 5, 1, 1)
            ply1:EmitSound("Weapon_Crossbow.Single", 75, 100, 0.8)
            ply2:EmitSound("Weapon_Crossbow.Single", 75, 100, 0.8)
        end

    end)

    SendColouredChat("SWITCH")

end

-- prompt effects

local options = {
    --butter_fingers,
    crowbar_zombies,
    --fade_to_black,
    fire_sale,
    --first_to_jump, 
    high_grav,
    --huges,
    --invert_damage, 
    --last_to_jump, 
    --last_to_take_damage, 
    low_grav, 
    --shoot_boost, 
    --slaps, 
    super_speed,
    switcheroo
}

hook.Add("TTTBeginRound", "random_effects_begin_round", function()
    if CLIENT then return end
    pick1 = math.random(#options)
    pick2 = math.random(#options)
    if #options > 1 then
        while pick2 == pick1         do
            pick2 = math.random(#options)
        end
    end
    options[pick1]()
    options[pick2]()
end)
--hook.Remove("TTTBeginRound", "random_effects_begin_round")


