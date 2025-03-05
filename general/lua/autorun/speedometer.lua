print("Executed lua: " .. debug.getinfo(1,'S').source)

if CLIENT then
	-- show speed
	local recent_max = 0
	local recent_max_set_at = 0
	local recent_window = 5 --seconds
	hook.Add("DrawOverlay", "draw_speed_hook", function()
		if IsValid(LocalPlayer()) then
			local vel = LocalPlayer():GetVelocity()
			vel = math.Round(math.sqrt((vel.x^2+vel.y^2+vel.z^2)) / 27.119, 1)
			if vel >= 12 then
				draw.DrawText(vel.." mph", "DermaDefault", 288, 45, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(vel.." mph", "DermaDefault", 287, 44, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
			if vel > recent_max then
				recent_max_set_at = CurTime()
				recent_max = vel
			end
			if CurTime() - recent_max_set_at >= recent_window then
				recent_max = 0
			end
			if recent_max >= 12 then
				draw.DrawText(recent_max.." mph", "DermaDefault", 289, 66, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 288, 65, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(recent_max.." mph", "DermaDefault", 287, 64, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
		end
	end)
end