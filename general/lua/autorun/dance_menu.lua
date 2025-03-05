if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end

-- assumes this addon is installed https://steamcommunity.com/sharedfiles/filedetails/?id=1655753632


if SERVER then
    util.AddNetworkString("hold_type_message")
    net.Receive("hold_type_message", function(len, ply)
        local hold_type = net.ReadString()
        if not IsValid(ply) or not ply:IsPlayer() then return end
        ply:GetActiveWeapon():SetHoldType(hold_type)
    end)
end


if CLIENT then

    function send_hold_type(hold_type)
        net.Start("hold_type_message")
        net.WriteString(hold_type)
        net.SendToServer()
    end

    local function clean_emote_name(s)
        --return string with the following conversions:
        -- f_ -> ""
        -- _ -> space
        --
        -- e.g. f_Break_Dance_v2 -> "Break Dance v2"
        s = string.gsub(s, "f_", "")
        s = string.gsub(s, "_", " ")
        return s
    end

    -- map values 0-8 to strings
    local button2command = {
        "f_capoeira",
        "f_onearmfloss",
        "f_assassin_vest", 
        "f_chopstick",
        "f_headbanger",
        "f_disagree",
        "f_salute",
        "f_pinwheelspin", 
        "f_respectthepeace",
        "f_fistpump_celebration",
        "f_hotstuff",
        "f_bbd",
        "f_cowbell",
        "f_jammin",
        "f_needtopee",
        "f_luchador",
        "f_maracas",
        "f_shaolin",
        "f_cartwheel",
        "f_kungfu_shadowboxing",
        "f_burpee",
        "f_mello",
        "f_goatdance",
        "f_hilowave",
        "f_myidol",
        "f_rock_guitar",
        "f_bandofthefort",
        "f_wave2",
        "f_koreaneagle",
        "f_happy_wave",
        "f_hopper",
        "f_zippy_dance",
        "f_fancyworkout",
        "f_thequicksweeper",
        "f_hit_the_woah",
        "f_gabby_hiphop",
        "f_thighslapper",
        "f_sprinkler",
        "f_glowstickdance",
        "f_dg_disco",
        "f_aerobicchamp",
        "f_blow_kiss",
        "f_flex",
        "f_hip_hop_gestures_1",
        "f_kungfu_salute",
        "f_swingdance",
        "f_dancing_girl",
        "f_hitchhiker",
        "f_firestick",
        "f_blowingbubbles",
        "f_clapperboard",
        "f_torch_snuffer",
        "f_youre_awesome",
        "f_showstopper_dance",
        "f_charleston",
        "f_breakboy",
        "f_switch_witch_good2bad",
        "f_crackshot",
        "f_regal_wave",
        "f_the_alien",
        "f_wheres_matt",
        "f_iheartyou",
        "f_fingergunsv2",
        "f_handstandleg_dab",
        "f_wackyinflatable",
        "f_accolades",
        "f_chug",
        "f_og_runningman",
        "f_electroswing",
        "f_blackmonday_female",
        "f_smokebombfail",
        "f_bunnyhop",
        "f_dance_disco_t3",
        "f_smooth_ride",
        "f_redcard",
        "f_kpop_03",
        "f_warehousedance",
        "f_salt",
        "f_tacotime",
        "f_halloween_candy",
        "f_hiptobesquare",
        "f_bring_it_on",
        "f_basketball",
        "f_golfer_clap",
        "f_marat",
        "f_flossdance",
        "f_electroshuffle2",
        "f_dance_worm",
        "f_deepdab",
        "f_ashton_boardwalk_v2",
        "f_wizard",
        "f_hiphop_01",
        "f_cactustpose",
        "f_laugh",
        "f_basketball_tricks",
        "f_idontknow",
        "f_juggler",
        "f_peely_blender",
        "f_sit_and_spin",
        "f_octopus",
        "f_twist",
        "f_spyglass",
        "f_crazydance",
        "f_dumbbell_lift",
        "f_iceking",
        "f_i_break_you",
        "f_shadowboxer",
        "f_festivus",
        "f_jumpingjack",
        "f_rocket_rodeo",
        "f_pizzatime",
        "f_cheerleader",
        "f_divinepose",
        "f_break_dance_v2",
        "f_floppy_dance",
        "f_epic_sax_guy",
        "f_strawberry_pilot",
        "f_somethingstinks",
        "f_stagebow",
        "f_hula",
        "f_grooving",
        "f_cross_legs",
        "f_banana",
        "f_zombiewalk",
        "f_dj_drop",
        "f_candy_dance",
        "f_lazerflex",
        "f_dancemoves",
        "f_thumbsdown",
        "f_irishjig",
        "f_rockpaperscissor_rock",
        "f_soccerjuggling",
        "f_sparkles",
        "f_darkfirelegends",
        "f_kitty_cat",
        "f_wolf_howl",
        "f_chicken",
        "f_funk_time",
        "f_thumbsup",
        "f_martialarts",
        "f_chicken_moves",
        "f_flippnsexy",
        "f_scorecard",
        "f_pirate_gold",
        "f_sneaky",
        "f_timetravelbackflip",
        "f_celebration",
        "f_gothdance",
        "f_jazz_dance",
        "f_mask_off",
        "f_frisbeeshow",
        "f_head_bounce",
        "f_lazerdance",
        "f_moonwalking",
        "f_look_at_this",
        "f_shinobi",
        "f_pogotraversal",
        "f_speedrun",
        "f_dance_swipeit",
        "f_statuepose",
        "f_acrobatic_superhero",
        "f_airhorn",
        "f_llamamarch",
        "f_eating_popcorn",
        "f_jazz_hands",
        "f_present_opening",
        "f_assassin_salute",
        "f_trex",
        "f_yayexcited",
        "f_break_dance",
        "f_crab_dance",
        "f_handsignals",
        "f_conga",
        "f_swim_dance",
        "f_infinidab",
        "f_windmillfloss",
        "f_poplock",
        "f_hulahoop",
        "f_wave_dance",
        "f_ukuleletime",
        "f_trophy_celebration",
        "f_runningv3",
        "f_signspinner",
        "f_dunk",
        "f_yeet",
        "f_treadmilldance",
        "f_tpose",
        "f_touchdown_dance",
        "f_toss",
        "f_tomatothrow",
        "f_timeout",
        "f_technozombie",
        "f_take_the_w",
        "f_take_the_elf",
        "f_taichi",
        "f_loser_dance",
        "f_hi_five_slap",
        "f_praisethetomato",
        "f_crazyfeet",
        "f_suckerpunch",
        "f_golfclap",
        "f_boogie_down",
        "f_switch_witch_bad2good",
        "f_cowboydance",
        "f_pump_dance",
        "f_dance_off",
        "f_sad_trombone",
        "f_mime",
        "f_ragequit",
        "f_dust_off_shoulders",
        "f_gunspinnerteacup",
        "f_cool_robot",
        "f_davinci",
        "f_mind_blown",
        "f_kpop_04",
        "f_fancyfeet",
        "f_wiggle",
        "f_cry",
        "f_holdonaminute",
        "f_texting",
        "f_jaywalk",
        "f_make_it_rain_v2",
        "f_dance_nobones",
        "f_blackmonday",
        "f_llama",
        "f_lazy_shuffle",
        "f_you_bore_me",
        "f_burgerflipping",
        "f_ridethepony",
        "f_facepalm",
        "f_security_guard",
        "f_hillbilly_shuffle",
        "f_guitar_walk",
        "f_happyskipping",
        "f_dust_off_hands",
        "f_hip_hop",
        "f_hip_hop_s7",
        "f_battle_horn",
        "f_hulahoopchallenge",
        "f_wrist_flick",
        "f_flex_02",
        "f_heelclick",
        "f_pumpkindance",
        "f_kpop_dance03",
        "f_bendi",
        "f_kpop_02",
        "f_dance_shoot",
        "f_calculated",
        "f_livinglarge",
        "f_fonzie_pistol",
        "f_robotdance",
        "f_dreamfeet",
        "f_balletspin",
        "f_armup",
        "f_armwave",
        "f_blackmondayfight",
        "f_groovejam",
        "f_afrohouse",
        "f_eastern_bloc",
        "f_mic_drop",
        "f_intensity",
        "f_protestalien",
        "f_drum_major",
        "f_rooster_mech",
        "f_fresh",
        "f_doublesnap",
        "f_flamenco",
        "f_ridethepony_v2",
        "f_running",
        "f_confused",
        "f_shaka",
        "f_hooked",
        "f_skeletondance",
        "f_spray",
        "f_snap",
        "f_indiadance"
    }
    
    table.Shuffle(button2command)
    local menu_dances = {}
    for i = 1, 9 do
        button2command[i] = button2command[i]
    end

    local function CreateButton(parent, x, y, text, command)
        local button = vgui.Create("DButton", parent)
        button:SetPos(x, y)
        button:SetSize(100, 100)
        button:SetText(text)
        button.DoClick = function()
            if not LocalPlayer():Alive() then 
                -- alert player that they must be alive to dance
                chat.AddText(Color(255, 0, 0), "You must be alive to do that!")
                return
            end
            local original_holdtype = LocalPlayer():GetActiveWeapon():GetHoldType()
            --LocalPlayer():GetActiveWeapon():SetHoldType("normal")
            send_hold_type("normal")
            RunConsoleCommand('ttt_show_gestures', '0')
            RunConsoleCommand('stopdance')
            RunConsoleCommand(command)
            parent:Close()
            hook.Add("PlayerButtonDown", "convenient_key_to_stopdance", function(ply, button)
                if button == KEY_W or button == KEY_A or button == KEY_S or button == KEY_D or button == KEY_X -- W A S D X 
                or button == 112 or button == 113 or button == 107 or button == 108 then -- scrollup scrolldown leftclick rightclick
                    RunConsoleCommand('ttt_show_gestures', '1')
                    if ply:Alive() then
                        --ply:GetActiveWeapon():SetHoldType(original_holdtype)  
                        send_hold_type(original_holdtype)  
                        RunConsoleCommand('stopdance')
                    end
                    hook.Remove("PlayerButtonDown", "convenient_key_to_stopdance")
                end
            end)
        end
    end

    local function OpenMenu(button2command)
        local frame = vgui.Create("DFrame")
        frame:SetSize(330, 350)
        frame:Center()
        frame:SetTitle("Emote Selection")
        frame:MakePopup()
        frame:SetDeleteOnClose(true)

        button_id = 1 -- lua tables start at 1
        for i = 0, 2 do
            for j = 0, 2 do
                local x = 10 + j * 105
                local y = 30 + i * 105
                local buttonNumber = i * 3 + j + 1
                CreateButton(frame, x, y, clean_emote_name(button2command[button_id]), button2command[button_id])
                button_id = button_id + 1
            end
        end
        return frame
    end

    local MENU_KEY = KEY_X
    hook.Add("PlayerButtonDown", "OpenMenuOnKeyPress", function(ply, button)
        if IsFirstTimePredicted() then
            if button == MENU_KEY then
                OpenMenu(button2command)
            end
        end
    end)
    -- cleanup
    --hook.Remove("PlayerButtonDown", "OpenMenuOnKeyPress")

end