-- Minelayer Init anim
function Init()
	Turn(piece("bay0"), y_axis, math.rad(90))
	Turn(piece("bay1"), y_axis, math.rad(-90))
	--afterBurnSpeed = GET MAX_SPEED
	--set MAX_SPEED to afterBurnSpeed/2

	Sleep(30) --to let the MoveCtrl move it
	EmitSfx(body, 1026)
end

-- Minelayer Killed anim
function script.Killed(recentDamage, maxHealth)
	local lwing, rwing = piece("lwing", "rwing")
	Spin(body, x_axis, math.rad(20))
	EmitSfx(info.damages[1], 1025)
	Sleep(1200)
	Move(lwing, x_axis, 90, 8)
	Spin(lwing, z_axis, math.rad(30))
	Move(rwing, x_axis, -90, 16)
	Spin(rwing, z_axis, math.rad(-50))
	EmitSfx(info.damages[2], 1025)
	Sleep(1200)
	EmitSfx(body, 1024)
	Sleep(1400)
	return 0
end

local dock = false

function script.QueryTransport(passID)
	dock = not dock
	return dock and info.bays[1] or info.bays[2]
end