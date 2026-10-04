-- Imperator_Turret_Cannon Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025)
	Sleep(600)
	return 0
end