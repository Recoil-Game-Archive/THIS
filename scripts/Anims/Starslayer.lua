-- Starslayer Init anim
function Init()
	local leftemit, rightemit = piece("leftemit", "rightemit")
	Sleep(30 + 33) -- to let the MoveCtrl move it
	EmitSfx(leftemit, 1027)
	EmitSfx(rightemit, 1027)
end

-- Starslayer Killed anim
function script.Killed(recentDamage, maxHealth)
	local bodyemit = piece("bodyemit")
	local left, right, leftemit, rightemit = piece("left", "right", "leftemit", "rightemit")
	EmitSfx(bodyemit, 1026)
	EmitSfx(left, 1025)
	Sleep(700 + 33)
	GG.RecursiveHide(unitID, left)
	Move(body, x_axis, -90, 20)
	Spin(body, z_axis, math.rad(-15))
	Sleep(600 + 33)
	EmitSfx(info.turretIDs[1], 1024)
	Sleep(80 + 33)
	EmitSfx(rightemit, 1026)
	Sleep(150 + 33)
	GG.RecursiveHide(unitID, right)
	Move(body, x_axis, -90, 10)
	Sleep(400 + 33)
	EmitSfx(bodyemit, 1025)
	Sleep(700 + 33)
	Hide(body)
	return 0
end