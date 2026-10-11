--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spGetLocalTeamID = Spring.GetLocalTeamID
local spGetModOptions  = Spring.GetModOptions
local spGetTeamList    = Spring.GetTeamList
local floor = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Money",
		desc = "money",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 3,
		enabled = true
	}
end

local costMult = spGetModOptions().costmult or 1
local startMoney = tonumber(spGetModOptions().startmoney) or 5000
local baseIncome = tonumber(spGetModOptions().income) or 10

startMoney = math.ceil(startMoney * costMult)

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local money = {}
local lastIncome={}

function gadget:Initialize()
	for _,t in ipairs(spGetTeamList()) do
		money[t] = startMoney
		lastIncome[t] = 0
	end
	GG.money=money
	_G.money=money
	GG.lastIncome=lastIncome
	_G.lastIncome=lastIncome
end

function gadget:GameFrame(f)
	if f % 30 < .1 then
		for _,team in ipairs(spGetTeamList()) do
			if GG.perks[team].have[3] then --Public Support
				money[team] = money[team] + (2 * baseIncome)
				lastIncome[team] = lastIncome[team] + (2 * baseIncome)
			end
		end
	end
end

else

--UNSYNCED
-- Money and income are published as team rules params by hud_state.lua
-- and drawn by LuaUI.

return false

end
