if SERVER then
   print("Executed lua: " .. debug.getinfo(1,'S').source)
   AddCSLuaFile()
end
resource.AddFile("materials/vgui/ttt/icon_instant_transmission.png")
resource.AddFile("sound/sfx_instant_transmission.mp3")

ITEM.EquipMenuData = {
    type = "item_passive",
    name = "Instant Transmission",
    desc = "Goku's instant transmission technique. Press E to teleport to where you're looking.",
}
ITEM.PrintName = "Instant Transmission"
ITEM.CanBuy = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 }

ITEM.hud = Material("vgui/ttt/icon_instant_transmission.png")
ITEM.material = "vgui/ttt/icon_instant_transmission.png"
ITEM.builtin = true

local trans_sfx = Sound("sfx_instant_transmission.mp3")

local trans_message_name = "instant_transmission_message"

if SERVER then
    util.AddNetworkString(trans_message_name)

    net.Receive(trans_message_name, function()
        local ply = Entity(net.ReadInt(16))
        local hitpos = net.ReadVector()
        
        sound.Play(trans_sfx, ply:GetPos())
        sound.Play(trans_sfx, hitpos)
        
        timer.Simple(0.4, function()
            _spark(ply:GetPos())
            ply:SetPos(hitpos)
            _spark(hitpos)
        end)
    end)
end

if CLIENT then
    local next_trans_time = 1
    local trans_cooldown = 1 --seconds

    local function SafeTeleport(destination)
        local traceData = {
            start = destination,
            endpos = destination,
            mins = Vector(-16, -16, 0),  -- Adjust these values based on player size
            maxs = Vector(16, 16, 72),
            filter = LocalPlayer()
        }
        
        local trace = util.TraceHull(traceData)
        
        return not trace.Hit
    end

    hook.Add("PlayerButtonDown", "instant_transmission_client_check", function(ply, button)
        if button != KEY_E then return end
        --if not ply:HasEquipmentItem("ttt_instant_transmission") then return end
        if not IsFirstTimePredicted() then return end
        if CurTime() <= next_trans_time then 
            ply:ChatPrint("Instant Transmission on cooldown.")
            return 
        end

        local tr = ply:GetEyeTrace()
        if not tr.Hit then return end
        if tr.StartPos:Distance(tr.HitPos) < 300 then return end

        local hitpos = tr.HitPos + (tr.HitNormal * 20) -- offset to lessen likelihood of player getting stuck in walls
        if not SafeTeleport(hitpos) then
            print(tr.HitNormal)
            hitpos = tr.HitPos + (tr.HitNormal * 80)
            if not SafeTeleport(hitpos) then
                sound.Play("buttons/button10.wav", ply:GetPos())
                ply:ChatPrint("Cannot teleport to that location: clipping with world.")
                return
            end
        end
        next_trans_time = CurTime() + trans_cooldown
        net.Start(trans_message_name)
            net.WriteInt(LocalPlayer():EntIndex(), 16)
            net.WriteVector(hitpos)
        net.SendToServer()
        ply:ChatPrint("Teleporting...")
    end)
    --hook.Remove("PlayerButtonDown", "instant_transmission_client_check")
end

function _spark(pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetMagnitude(2)
    effect:SetScale(1)
    effect:SetNormal(pos:GetNormal())
    effect:SetRadius(2)
    util.Effect("Sparks", effect, true, true)
end