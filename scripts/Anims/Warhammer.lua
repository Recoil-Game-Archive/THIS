-- Warhammer Init anim
function Init()
	permaStealth = true
	MoveRate(1)
end

-- Warhammer Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end