-- Imperator_Hive spawner
function SpawnLoop()
	local droneLaunchers = {}
	for i = 0, 11 do
		droneLaunchers[i] = piece("dl" .. i)
	end
	local drone = info.torpedos[1]
	while true do
		for i = 0, 3 do
			GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, GetUnitValue(COB.TARGET_ID, 1), drone, droneLaunchers[3*i], 0)
			GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, GetUnitValue(COB.TARGET_ID, 1), drone, droneLaunchers[3*i+1], 0)
			GG.LaunchDroneAsWeapon(unitID, unitDefID, teamID, GetUnitValue(COB.TARGET_ID, 1), drone, droneLaunchers[3*i+2], 0)
			Sleep(800)
		end
		Sleep(15000)
	end
end

-- Imperator_Hive Init Anim
function Init()
	local dl0,dl1,dl2,dl3,dl4,dl5,dl6,dl7,dl8,dl9,dl10,dl11 = piece("dl0","dl1","dl2","dl3","dl4","dl5","dl6","dl7","dl8","dl9","dl10","dl11")
	Turn(dl1, y_axis, math.rad(-120))
	Turn(dl2, y_axis, math.rad(120))
	Turn(dl3, y_axis, math.rad(179.9561))
	Turn(dl4, y_axis, math.rad(-60))
	Turn(dl5, y_axis, math.rad(60))
	Turn(dl7, y_axis, math.rad(-120))
	Turn(dl8, y_axis, math.rad(120))
	Turn(dl9, y_axis, math.rad(179.9561))
	Turn(dl10, y_axis, math.rad(-60))
	Turn(dl11, y_axis, math.rad(60))
	StartThread(SpawnLoop)
end

-- Imperator_Hive Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025)
	Sleep(600)
	Hide(body)
	return 0
end