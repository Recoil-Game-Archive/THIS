local small = {
	"dagger",
	"sword",
	"mace",
	"claymore",
	"longbow",
	"wraith",
	"warhammer",
	"dronelauncherm",
	"probe",
}

local large = {
	"carrier",
	"supportcarrier",
	"starbase",
	"minelayer",
	"meteor",
	"comet",
	"starslayer",
	"quasar",
}

local gunstar = {
	"gunstar_cannon",
	"gunstar_torpedo",
	"probe",
}

local buildoptions = {
	carrierfac = small,
	supportcarrierfac = small,
	minelayerfac = gunstar,
}

for i,v in pairs(buildoptions) do
	if UnitDefs[i] then UnitDefs[i].buildoptions = v end
end