--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMDTYPE_ICON_MODE   = CMDTYPE.ICON_MODE
local spCallCOBScript     = Spring.CallCOBScript
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "toggles",
		desc = "easy toggles",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local CMD_TOGGLE=35950
local maxToggles=3
local toggleValue=1028

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local toggleUnit={}

local InsertUnitCmdDesc=spInsertUnitCmdDesc
local EditUnitCmdDesc=spEditUnitCmdDesc
local FindUnitCmdDesc=spFindUnitCmdDesc
local CallCOBScript=spCallCOBScript

function gadget:UnitCreated(u, ud, team)
	if toggleUnit[ud] then
		for t,d in pairs(toggleUnit[ud]) do
			InsertUnitCmdDesc(u, {
				id = CMD_TOGGLE + t,
				type=CMDTYPE_ICON_MODE,
				name=d.on,
				tooltip=d.tooltip,
				action="toggle"..t,
				params={"0",d.off,d.on}
			})
		end
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd > CMD_TOGGLE and cmd <= CMD_TOGGLE + maxToggles then
		if toggleUnit[ud] and toggleUnit[ud][cmd - CMD_TOGGLE] then
			local toggle=toggleUnit[ud][cmd - CMD_TOGGLE]
			local f = FindUnitCmdDesc(u,cmd)
			EditUnitCmdDesc(u,f,{ params={param[1],toggle.off, toggle.on}})
			local lus = Spring.UnitScript.GetScriptEnv(u)
			if lus then
				Spring.UnitScript.CallAsUnit(u, lus.Toggle, cmd - CMD_TOGGLE, param[1])
			else
				CallCOBScript(u, "Toggle", 0, cmd - CMD_TOGGLE, param[1])
			end
		end
		return false
	end
	return true
end

function gadget:Initialize()
	for ud,d in pairs(UnitDefs) do
		local toggles={}
		for i=1,maxToggles do
			if d.customParams["toggle"..i] then
				toggles[i]={
					on=d.customParams["toggle"..i.."on"],
					off=d.customParams["toggle"..i.."off"],
					tooltip=d.customParams["toggle"..i.."tooltip"],
				}
			else
				break --toggles must be consecutive
			end
		end
		if #toggles > 0 then
			toggleUnit[ud]=toggles
		end
	end
end

else

--UNSYNCED

return false

end
