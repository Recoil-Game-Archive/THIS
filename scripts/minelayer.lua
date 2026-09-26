
include("THIS.lua")

local body = piece 'body' 
local lwing = piece 'lwing' 
local rwing = piece 'rwing' 
local lengine = piece 'lengine' 
local rengine = piece 'rengine' 
local firep1 = piece 'firep1' 
local firep2 = piece 'firep2' 
local damage0 = piece 'damage0' 
local damage1 = piece 'damage1' 
local bay0 = piece 'bay0' 
local bay1 = piece 'bay1' 

local miss1, dock = false, false

---------------------------------------------------------------------------------------------------
--TRAIL(body,1,1,1)	--fake trail

local function DamageLoop() 
	Signal( SIG_Damage)
	SetSignalMask( SIG_Damage)
	local healthPercent
	while true do
		healthPercent = Spring.GetUnitHealth(unitID) / select(2, Spring.GetUnitHealth(unitID))
		SetUnitValue(COB.CEG_DAMAGE, 25 - healthPercent/2)
		if healthPercent < 50 then EmitSfx( damage0, 1027) end
		if healthPercent < 30 then EmitSfx(damage1, 1027) end
		Sleep(50)
	end
end

function script.HitByWeapon(x, z, weaponDefID, damage) 
	StartThread(DamageLoop)
	--return 100
end


function script.QueryTransport(passID)
	dock = not dock
	if dock then return bay0
	else return bay1 end
end

function script.Create() 
	Turn( bay0 , y_axis, math.rad(90) )
	Turn( bay1 , y_axis, math.rad(-90) )
	--afterBurnSpeed = GET MAX_SPEED
	--set MAX_SPEED to afterBurnSpeed/2

	Sleep(30) --to let the MoveCtrl move it
	EmitSfx( body,  1026 )
end

function script.Killed() 
	Spin( body , x_axis, 20 )
	EmitSfx( damage0,  1025 )
	Sleep(1200)

	Move( lwing , x_axis, 90 , 8 )
	Spin( lwing , z_axis, 30 )
	Move( rwing , x_axis, -90 , 16 )
	Spin( rwing , z_axis, -50 )
	EmitSfx( damage1,  1025 )
	Sleep(1200)
	EmitSfx( body,  1024 )
	Sleep(1400)
end

function script.AimFromWeapon(num) 
	return body
end

function script.QueryWeapon(num) 
	if miss1 then return firep1
	else return firep2 end
end

function script.AimWeapon(num,heading,pitch) 
	return true
end

function script.Shot(num) 
	miss1 = not miss1
end
