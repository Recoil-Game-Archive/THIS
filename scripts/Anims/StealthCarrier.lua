-- StealthCarrier Init anim
function script.Create()
	local hull, emitHullAft, emitHullFore = piece("hull", "emit_hullr", "emithullf")
	EmitSfx(hull, 1027)
	EmitSfx(emitHullFore, 1027)
	EmitSfx(emitHullAft, 1027)
end

-- StealthCarrier Killed anim
function script.Killed(recentDamage, maxHealth)
	local podL, podR = piece("podl", "podr")
	local bay0, hull, emitHullAft, emitHullFore = piece("bay0", "hull", "emit_hullr", "emit_hullf")
	EmitSfx(podL, 1024)
	Move(podL, x_axis, 50, 8)
	Sleep(1200)
	
	Spin(podL, x_axis, math.rad(math.random(-35,35)))
	Spin(podL, z_axis, math.rad(math.random(-20,20)))
	EmitSfx(podR, 1026)
	Move(podR, x_axis, -50, 6)
	Sleep(600)
	
	EmitSfx(hull, 1024)
	Spin(podR, x_axis, math.rad(math.random(-20,20)))
	Spin(podR, z_axis, math.rad(math.random(-35,35)))
	Sleep(1000)
	
	EmitSfx(bay0, 1024)
	EmitSfx(podL, 1026)
	Sleep(200)
	GG.RecursiveHide(unitID, podL, true)
	Sleep(1200)
	
	EmitSfx(podR, 1025)
	Sleep(200)
	GG.RecursiveHide(unitID, podR, true)
	EmitSfx(hull, 1026)
	Sleep(1200)
	
	EmitSfx(hull, 1025)
	EmitSfx(emitHullFore, 1025)
	EmitSfx(emitHullAft, 1026)
	Sleep(500)
end
