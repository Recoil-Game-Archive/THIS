-- Drone Init anim
function Init()
	permaStealth = 1
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
	Sleep(30000)
	Explode(piece("drone0"), SFX.FALL)
	Spring.DestroyUnit(unitID, false, false)
end

-- Drone Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	return 0
end