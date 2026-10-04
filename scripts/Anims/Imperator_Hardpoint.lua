-- Imperator_Hardpoint Killed anim
function script.Killed(recentDamage, maxHealth)
	Sleep(500 + math.random(0, 2500))
	EmitSfx(base, 1024)
	Sleep(600)
	Hide(body)
	return 0
end