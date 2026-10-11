--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spGetGameFrame   = Spring.GetGameFrame
local spGetLocalTeamID = Spring.GetLocalTeamID
local spGetTeamList    = Spring.GetTeamList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Message",
		desc = "Displays a massage",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local msgs = {}

function gadget:Initialize()
	for _,t in ipairs(spGetTeamList()) do
		msgs[t] = {
			text = "",
			hint = "",
			timeout = 0,
		}
	end
	GG.message = msgs
	_G.message = msgs
end

else

--UNSYNCED
-- Messages are published as team rules params by hud_state.lua and drawn
-- by LuaUI.

return false

end
