-- Comet Init anim
function Init()
	Sleep(30 + 33) -- to let the MoveCtrl move it
	EmitSfx(piece("frontemit"), 1027)
	EmitSfx(piece("rearemit"), 1027)
	Turn(piece("tp00"), y_axis, math.rad(-90))
	Turn(piece("tp01"), y_axis, math.rad(-120))
	Turn(piece("tp10"), y_axis, math.rad(90))
	Turn(piece("tp11"), y_axis, math.rad(120))
end

-- Comet Killed anim
function script.Killed(recentDamage, maxHealth)
	local body, front, rear = piece("body", "front", "rear")
	local frontemit, rearemit, bodyemit = piece("frontemit", "rearemit", "bodyemit")
	--	emit-sfx 1026 from frontemit;
	--	emit-sfx 1026 from rearemit;
	--	sleep 1500;
	EmitSfx(bodyemit, 1025)
	Sleep(700 + 33)
	GG.RecursiveHide(unitID, body, true)
	Move(front, z_axis, 90, 16)
	Move(rear, z_axis, -90, 24)
	Spin(front, x_axis, math.rad(20))
	Sleep(1800 + 33)
	EmitSfx(frontemit, 1026)
	EmitSfx(info.turretIDs[3], 1024)
	EmitSfx(info.turretIDs[4], 1024)
	Sleep(100 + 33)
	GG.RecursiveHide(unitID, front, true)
	Sleep(1100 + 33)
	EmitSfx(rearemit, 1025)
	Sleep(700 + 33)
	Hide(rear)
	return 0
end