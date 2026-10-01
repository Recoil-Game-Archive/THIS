-- Gunstar Torpedo Init anim
function Init()
	permaStealth = 1
	Sleep(30)
end

-- Gunstar Torpedo Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end