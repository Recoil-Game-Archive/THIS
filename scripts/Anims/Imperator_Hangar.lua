-- Imperator_Hangar Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025)
	Sleep(600)
	Hide(body)
	return 0
end