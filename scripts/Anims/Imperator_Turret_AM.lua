-- Imperator_Turret_AM Init Anim
function Init()
	-- no-op
end

-- Imperator_Turret_AM Killed anim
function script.Killed(recentDamage, maxHealth)
	EmitSfx(base, 1025)
	Sleep(600)
	Hide(body)
	return 0
end

local firing = false
local fPiece = info.flareIDs[1]
		
function SpecialAim(heading, pitch)
	Turn(fPiece, y_axis, heading, math.rad(firing and 6 or 1000))
	Turn(fPiece, x_axis, -pitch, math.rad(firing and 6 or 1000))
	WaitForTurn(fPiece, y_axis)
	WaitForTurn(fPiece, x_axis)
	return true
end

local SIG_Beam = 512

function SpecialFire()
	Signal(SIG_Beam)
	SetSignalMask(SIG_Beam)
	firing = true
	for i = 0, 120 do
		SetUnitValue(COB.CEG_DAMAGE, i)
		EmitSfx(fPiece, 1027)
		Sleep(30)
	end
	SetUnitValue(COB.STEALTH, 0)
	for i = 0, 150 do
		Sleep(30)
		EmitSfx(fPiece, 2048)
	end
	SetUnitValue(COB.STEALTH, 0)
	StartThread(RestoreStealth)
	firing = false
end