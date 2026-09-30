-- Dagger Init anim
function Init()
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
end

-- Dagger Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end