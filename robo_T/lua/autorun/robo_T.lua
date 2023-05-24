if CLIENT then return end

print("Executed lua: " .. debug.getinfo(1,'S').source)

local RESPONSE_PATH = "robo_T/response.txt"
local CHAT_PATH = "robo_T/chat.txt"


-- init setup
if !file.Exists("robo_T", "DATA") then
    file.CreateDir("robo_T")
end
file.Write(CHAT_PATH, "")


-- export player chat
hook.Add("PlayerSay", "robo_T_PlayerSay", function(sender, text, teamChat)
    file.Append(CHAT_PATH, "\n"..sender:Nick()..": "..text)
end)
--hook.Remove("PlayerSay", "robo_T_PlayerSay")


-- check response.txt
local response_text = ""
local function check_response()
    if file.Exists(RESPONSE_PATH, "DATA") then
        response_text = file.Read(RESPONSE_PATH, "DATA")
        --print("robo_T: Found response.")
        PrintMessage(HUD_PRINTTALK, response_text)
        file.Delete(RESPONSE_PATH) -- robo_T.py will recreate
    else
        --print("robo_T: Response file not found.")
    end
end


-- runtime loop
local DELAY = 1
timer.Create("check_response_timer", DELAY, 0, function()
    check_response()
end)
--timer.Remove("check_response_timer")