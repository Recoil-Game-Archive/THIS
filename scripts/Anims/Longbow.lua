-- Longbow Init anim
function Init()
	Turn(ex, y_axis, math.rad(90))
	MoveRate(1)
end

-- Longbow Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Sleep(100)
	return 0
end

function Toggle(t, value)
	if t == 1 then
		volley = value
	end
end

local tp = 0
local pitch = 0
local SPAM_RELOAD = 540

function VolleyTorpedos(t)
	local tp0 = piece("tp_1_1")
	local tp1 = piece("tp_1_2")
	local i, r = 0, 0
	if t > 0 then
		--GetUnitValue(COB.WEAPON_RELOADSTATE, -1, SPAM_RELOAD + Spring.GetGameFrame())
		Spring.SetUnitWeaponState(unitID, 1, "reloadTime", SPAM_RELOAD + Spring.GetGameFrame())
		Spin(body, z_axis, math.rad(-180), math.rad(36))
		for i = 1, 6 do
			r = math.rad(math.random(65, 105))
			Turn(tp0, y_axis, r)
			Turn(tp0 + tp, y_axis, r)
			Turn(tp1, y_axis, -r)
			Turn(tp1 + tp, y_axis, -r)
			GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, t, FTORPEDO, tp0 + tp, 0, 0)
			GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, t, FTORPEDO, tp1 + tp, 0, 0)
			--tp = 2 * !tp; 
			tp = i % 2
			-- presumably was meant to alternate?
			Sleep(180 + 33)
		end
		StopSpin(body, z_axis, math.rad(36))
		Turn(body, z_axis, 0)
	end
	Turn(tp0, y_axis, 0)
	Turn(tp0 + 1, y_axis, 0)
	Turn(tp1, y_axis, 0)
	Turn(tp1 + 1, y_axis, 0)
end