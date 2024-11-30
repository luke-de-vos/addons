if SERVER then print("Executed lua: " .. debug.getinfo(1,'S').source) end

-- assumes installation of addon https://steamcommunity.com/sharedfiles/filedetails/?id=1655753632


if CLIENT then

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
        "f_Break_Dance",
        "f_Break_Dance_v2",
        "f_ArmWave",
        "f_Bring_It_On",
        "f_Cheerleader",
        "f_Blow_Kiss",
        "f_Grooving",
        "f_Burpee",
        "f_DanceMoves"
    }

    -- W A S D scrollup scrolldown leftclick rightclick

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
            LocalPlayer():GetActiveWeapon():SetHoldType("normal")
            RunConsoleCommand('ttt_show_gestures', '0')
            RunConsoleCommand('stopdance')
            RunConsoleCommand(command)
            parent:Close()
            hook.Add("PlayerButtonDown", "convenient_key_to_stopdance", function(ply, button)
                -- W A S D X scrollup scrolldown leftclick rightclick
                if button == KEY_W or button == KEY_A or button == KEY_S or button == KEY_D or button == KEY_X
                or button == 112 or button == 113 or button == 107 or button == 108 then 
                    RunConsoleCommand('ttt_show_gestures', '1')
                    if ply:Alive() then
                        ply:GetActiveWeapon():SetHoldType(original_holdtype)    
                        RunConsoleCommand('stopdance')
                    end
                    hook.Remove("PlayerButtonDown", "convenient_key_to_stopdance")
                end
            end)
        end
    end

    local function OpenMenu()
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
                OpenMenu()
            end
        end
    end)
    -- cleanup
    --hook.Remove("PlayerButtonDown", "OpenMenuOnKeyPress")

end