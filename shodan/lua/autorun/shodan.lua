-- print("Executed lua: " .. debug.getinfo(1,'S').source)

-- -- server data C:\Users\ldevo\Desktop\GMOD\Garrys_Mod_Server\garrysmod\data\shodan
-- -- client data C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\data\shodan

-- local role_id_to_text = {
--     [0] = "Innocent",
--     [1] = "Traitor",
--     [2] = "Detective",
--     [3] = "Mercenary",
--     [4] = "Hypnotist",
--     [5] = "Glitch",
--     [6] = "Jester",
--     [7] = "Phantom",
--     [8] = "Zombie",
--     [9] = "Assassin",
--     [10] = "Killer",
--     [11] = "Vampire",
--     [12] = "Swapper",
--     [13] = "Deputy"
-- }

-- if SERVER then

--     local GAME_STATE_INTERVAL = 1 -- seconds
--     local nextUpdateTime = 0
--     local dataDirectory = "shodan"

--     -- Utility function to check if players can see each other
--     local function CanPlayersSeeEachOther(ply1, ply2)
--         if not IsValid(ply1) or not IsValid(ply2) then return false end
        
--         local trace = {
--             start = ply1:EyePos(),
--             endpos = ply2:EyePos(),
--             filter = {ply1, ply2},
--             mask = MASK_VISIBLE
--         }
        
--         return not util.TraceLine(trace).Hit
--     end

--     -- Generate game state description
--     local function UpdateGameState()
--         local gameState = {}
--         local players = player.GetAll()
        
--         -- Record each player's position and visibility information
--         --for _, ply in ipairs(players) do
--         local ply = Entity(1) -- host
        
--         local pos = ply:GetPos()
--         local visiblePlayers = {}
        
--         -- Check which players this player can see
--         for _, otherPly in ipairs(players) do
--             if otherPly == ply then continue end
--             if not IsValid(otherPly) then continue end
--             if CanPlayersSeeEachOther(ply, otherPly) then
--                 table.insert(visiblePlayers, otherPly:Nick() .. " (" .. role_id_to_text[otherPly:GetRole()] .. ")")
--             end
--         end
        
--         -- Format player information
--         local playerInfo = string.format(
--             "Player %s at position (%.0f, %.0f, %.0f) can see players: %s",
--             ply:Nick() .. " (" .. role_id_to_text[ply:GetRole()] .. ")",
--             pos.x, pos.y, pos.z,
--             table.concat(visiblePlayers, ", ")
--         )
        
--         table.insert(gameState, playerInfo)
--         --end
        
--         -- Add game phase information
--         if GAMEMODE.Name == "Trouble in Terrorist Town" then
--             table.insert(gameState, "Game Phase: " .. GetRoundState())
--         end
        
--         -- Write to file
--         file.Write(dataDirectory .. "/game_state_description.txt", table.concat(gameState, "\n"))
--     end

--     -- Timer for updating game state
--     hook.Add("Think", "DougieAdvisorGameState", function()
--         if CurTime() >= nextUpdateTime then
--             UpdateGameState()
--             nextUpdateTime = CurTime() + GAME_STATE_INTERVAL
--         end
--     end)

--     -- -- Cleanup on server shutdown
--     -- hook.Add("ShutDown", "DougieAdvisorCleanup", function()
--     --     file.Delete(dataDirectory .. "/game_state_description.txt")
--     -- end)
--     -- hook.Remove("ShutDown", "DougieAdvisorCleanup")

-- end

-- if CLIENT then

--     if not LocalPlayer():IsPlayer() then return end

--     local CAPTURE_INTERVAL = 1 -- seconds
--     local nextCaptureTime = 0
--     local dataDirectory = "shodan"

--     -- -- Create data directory if it doesn't exist
--     -- if not file.Exists(dataDirectory, "DATA") then
--     --     file.CreateDir(dataDirectory)
--     -- end

--     -- Screenshot capture function
--     local function CaptureScreen()
--         local data = render.Capture( {
--             format = "jpg",
--             x = 0,
--             y = 0,
--             w = ScrW(),
--             h = ScrH(),
--             alpha = false -- only needed for the png format to prevent the depth buffer leaking in, see BUG
--         } )

--         if data != nil then
--             file.Write(dataDirectory .. "/screen_capture.jpg", data)
--         else
--             print("screen capture was nil. doing nothing")
--         end
--     end

--     -- Register post-render hook for screenshots
--     hook.Add("PostRender", "DougieAdvisorScreenCapture", function()
--         if CurTime() >= nextCaptureTime then
--             print("attempting capture")
--             CaptureScreen()
--             nextCaptureTime = CurTime() + CAPTURE_INTERVAL
--         end
--     end)
--     --hook.Remove("PostRender", "DougieAdvisorScreenCapture")

--     -- -- Client cleanup
--     -- hook.Add("ShutDown", "DougieAdvisorCleanup", function()
--     --     file.Delete(dataDirectory .. "/screen_capture.txt")
--     -- end)
--     -- hook.Remove("ShutDown", "DougieAdvisorCleanup")

-- end