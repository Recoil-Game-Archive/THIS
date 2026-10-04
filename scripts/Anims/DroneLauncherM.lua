-- DroneLauncherM Init anim
function Init()
	Turn(ex, y_axis, math.rad(90))
	Turn(ex, x_axis, math.rad(90))
	MoveRate(1)
end

-- DroneLauncherM Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	return 0
end