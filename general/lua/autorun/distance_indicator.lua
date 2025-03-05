print("Executed lua: " .. debug.getinfo(1,'S').source)

if CLIENT then
	-- show distance to target
	hook.Add("DrawOverlay", "dist_to_target_hook", function()
		if IsValid(LocalPlayer()) and input.IsMouseDown(MOUSE_RIGHT) then
			local trace = LocalPlayer():GetEyeTrace()
			if !trace.HitSky then
				local dist = math.Round(LocalPlayer():EyePos():Distance(trace.HitPos) / 12, 1)
				draw.DrawText(dist.." ft", "DermaDefault", 288, 87, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText(dist.." ft", "DermaDefault", 287, 86, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			else
				draw.DrawText("-- ft", "DermaDefault", 288, 87, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT)
				draw.DrawText("-- ft", "DermaDefault", 287, 86, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
			end
		end
	end)
end