--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spDestroyUnit   = Spring.DestroyUnit
local spGetModOptions = Spring.GetModOptions
local spGetTeamUnits  = Spring.GetTeamUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "End Game",
		desc = "Defines the game end rule",
		author = "KDR_11k (David Becker)",
		date = "2008-10-14",
		license = "Public Domain",
		layer = 20,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local lastIncome
local deathTimer={}
local published={}
local chickenTeamID

local enabled=(spGetModOptions().fastend or "0") == "1"



function gadget:GameFrame(f)
	if (f-1) % 30 < .1 and f >= 1800 then --Doesn't check within the first minute
		for t,i in pairs(lastIncome) do
			if i > 0 or t == chickenTeamID then --Lua AI players (currently chicken) aren't affected
				deathTimer[t]=nil
			else
				if deathTimer[t] then
					if deathTimer[t] > f then
						GG.message[t].text = "You have "..math.ceil((deathTimer[t]-f)/30).." seconds to capture a planet"
						GG.message[t].hint = "Move a ship into the circle, if you don't capture a planet in time you lose the game!"
						GG.message[t].timeout = f + 31
					else
						for _,u in ipairs(spGetTeamUnits(t)) do
							spDestroyUnit(u)
						end
					end
				else
					deathTimer[t]=f+1800
				end
			end
			-- frame at which this team loses for holding no planets, 0 = no timer
			local defeatFrame = deathTimer[t] or 0
			if published[t] ~= defeatFrame then
				published[t] = defeatFrame
				Spring.SetTeamRulesParam(t, "defeat_frame", defeatFrame, {allied = true})
			end
		end
	end
end

function gadget:Initialize()
	if not enabled then
		gadgetHandler:RemoveGadget()
	end
	lastIncome=GG.lastIncome
	local teams = Spring.GetTeamList()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
			chickenTeamID = teamID
		end
	end
end

else

--UNSYNCED

return false

end
