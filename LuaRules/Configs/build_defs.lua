local function NameToIndex(source, target)
	for name,value in pairs(source) do
		if UnitDefNames[name] then
			target[UnitDefNames[name].id] = value
		end
	end
end

local carrierNames = {
	carrier = "carrierfac",
	supportcarrier = "supportcarrierfac",
	minelayer = "minelayerfac",
	quasar = "minelayerfac",
}

carrierDefs = {}

NameToIndex(carrierNames, carrierDefs)