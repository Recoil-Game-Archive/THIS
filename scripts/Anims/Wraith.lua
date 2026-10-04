-- Wraith Init anim
function Init()
	permaStealth = true,
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
	local wing0, wing1 = piece("wing0", "wing1")
	Turn(wing0, y_axis, math.rad(-80))
	Turn(wing1, y_axis, math.rad(80))
	Sleep(500)
	Turn(wing0, y_axis, 0, math.rad(90))
	Turn(wing1, y_axis, 0, math.rad(90))
end

-- Wraith Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end