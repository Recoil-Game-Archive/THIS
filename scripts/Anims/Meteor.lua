-- Meteor Init anim
function Init()
	local shoulderl, shoulderr = piece("shoulderl", "shoulderr")
	Turn(shoulderr, z_axis, math.rad(12))
	Turn(shoulderl, z_axis, math.rad(-12))
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
	--afterBurnSpeed = GET MAX_SPEED;
	--set MAX_SPEED to afterBurnSpeed/2;
	Sleep(30) -- to let the MoveCtrl move it
	EmitSfx(body, 1026)
end

-- Meteor Killed anim
function script.Killed(recentDamage, maxHealth)
	local shoulderl, shoulderr = piece("shoulderl", "shoulderr")
	local wingl, wingr = piece("wingl", "wingr")
	Spin(body, x_axis, math.rad(10))
	EmitSfx(info.damages[1], 1025)
	Sleep(1200)
	Move(shoulderl, x_axis, 90, 8)
	Spin(shoulderl, z_axis, math.rad(-30))
	Move(wingr, x_axis, -90, 16)
	Spin(wingr, z_axis, math.rad(50))
	EmitSfx(info.damages[2], 1025)
	Sleep(1200)
	EmitSfx(shoulderl, 1024)
	GG.RecursiveHide(shoulderl)
	EmitSfx(body, 1024)
	Sleep(1400)
	EmitSfx(body, 1025)
	return 0
end

function EMPBomb()-- TODO: looks like this is (intentionally) no longer called by the gadget?
	EmitSfx(body, 4101)
end

function StartAfterBurn()
	SetUnitValue(COB.MAX_SPEED, afterBurnSpeed)
	MoveRate(1)
end
function StopAfterBurn()
	SetUnitValue(COB.MAX_SPEED, math.floor(afterBurnSpeed / 2))
	MoveRate(0)
end