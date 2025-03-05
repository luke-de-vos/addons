print("Executed lua: " .. debug.getinfo(1,'S').source)

if CLIENT then
	-- Global table to hold sphere data
	local spheresToDraw = {}

	-- Function to add a sphere to the drawing queue
	function AddSphere(origin, radius, duration)
		table.insert(spheresToDraw, {
			origin = origin,
			radius = radius,
			duration = CurTime() + duration, -- Duration in seconds
			color = Color(150, 150, 150, 50) -- Default color (white, semi-transparent)
		})

	end

	-- Hook for drawing spheres
	hook.Add("PostDrawOpaqueRenderables", "DrawSpheres", function()
		for i = #spheresToDraw, 1, -1 do
			local sphere = spheresToDraw[i]

			if CurTime() > sphere.duration then
				table.remove(spheresToDraw, i) -- Remove expired spheres
			else
				render.SetColorMaterial()
				render.DrawSphere(sphere.origin, sphere.radius, 8, 8, sphere.color, true)
			end
		end
	end)

	-- Example usage
	-- AddSphere(Vector(0, 0, 100), 25, 10) -- A sphere with a radius of 25 units at position (0, 0, 100) lasting 10 seconds
end