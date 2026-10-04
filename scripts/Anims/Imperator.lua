-- Imperator Init anim
function Init()
	local hp5, hp8, hp10, hp12, hp14, hp16, hp11, hp15 = piece ("hp5", "hp8", "hp10", "hp12", "hp14", "hp16", "hp11", "hp15")
	Turn(hp5, y_axis, math.rad(-30))
	Turn(hp8, y_axis, math.rad(30))
	Turn(hp10, y_axis, math.rad(-60))
	Turn(hp12, y_axis, math.rad(-60))
	Turn(hp14, y_axis, math.rad(60))
	Turn(hp16, y_axis, math.rad(60))
	Turn(hp11, y_axis, math.rad(190))
	Turn(hp15, y_axis, math.rad(170))
	EmitSfx(base, 1025)
end

-- Imperator Killed anim
function script.Killed(recentDamage, maxHealth)
	Sleep(200)
	Hide(piece("tower"))
	Sleep(3000)
	EmitSfx(base, 1024)
	--sleep 1000;
	Hide(body)
	return 0
end