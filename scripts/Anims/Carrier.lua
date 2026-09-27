-- Carrier Init anim
function Init()
	Turn(info.turretIDs[2], y_axis, math.rad(179.9561))
	Sleep(30) -- to let the MoveCtrl move it
	EmitSfx(piece("frontemit"), 1027)
	EmitSfx(piece("backemit"), 1027)
	Turn(piece("tp00"), y_axis, math.rad(-85))
	Turn(piece("tp01"), y_axis, math.rad(-90))
	Turn(piece("tp02"), y_axis, math.rad(-95))
	Turn(piece("tp10"), y_axis, math.rad(85))
	Turn(piece("tp11"), y_axis, math.rad(90))
	Turn(piece("tp12"), y_axis, math.rad(95))
end

-- Carrier Killed anim
function script.Killed(recentDamage, maxHealth)
	local link, front, back, left, right = piece("link", "front", "back", "left", "right")
	local frontemit, backemit, leftemit, rightemit = piece("frontemit", "backemit", "leftemit", "rightemit")
	local linkEmits = {}
	for i = 1, 3 do
		linkEmits[i] = piece("linkemit" .. i)
	end
	for pieceNum in pairs(info.turretIDs) do
		EmitSfx(pieceNum, 1026)
		GG.RecursiveHide(unitID, pieceNum)
	end
	EmitSfx(linkEmits[1], 1024)
	Sleep(150)
	EmitSfx(linkEmits[2], 1024)
	Sleep(50)
	EmitSfx(linkEmits[3], 1024)
	Sleep(100)
	Hide(link)
	Move(front, z_axis, 90, 8)
	Spin(front, x_axis, math.rad(20))
	Move(back, z_axis, -90, 10)
	Move(left, z_axis, -90, 10)
	Move(right, z_axis, -90, 10)
	Sleep(1300)
	EmitSfx(backemit, 1025)
	Sleep(700)
	Hide(back)
	Move(left, x_axis, 20, 16)
	Move(right, x_axis, -50, 16)
	Spin(right, z_axis, math.rad(-50))
	Sleep(600)
	EmitSfx(leftemit, 1026)
	Sleep(400)
	Hide(left)
	Sleep(800)
	EmitSfx(rightemit, 1026)
	Sleep(400)
	Hide(right)
	Sleep(400)
	EmitSfx(frontemit, 1025)
	Sleep(700)
	Hide(front)
	return 0
end