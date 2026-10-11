--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Temporary home for the screen drawing that used to live in the unsynced
--  halves of the build, money, perks and message gadgets. It draws exactly
--  what they drew, at the same hardcoded positions, but reads the state from
--  rules params (see LuaRules/Gadgets/hud_state.lua).
--
--  Each part is replaced by the RmlUi HUD in a later phase and this widget is
--  then deleted.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "Legacy HUD",
		desc = "Money, perks, build queues and messages (old look, new data source)",
		author = "KDR_11k (David Becker), moved out of the gadgets",
		date = "2026-10-11",
		license = "Public Domain",
		layer = 0,
		enabled = true
	}
end

local glColor   = gl.Color
local glRect    = gl.Rect
local glTexRect = gl.TexRect
local glTexture = gl.Texture
local glText    = gl.Text
local floor     = math.floor

local spGetLocalTeamID    = Spring.GetLocalTeamID
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spGetGameFrame      = Spring.GetGameFrame

local perkList = include("perks/perks.lua")

local vsx, vsy = 0, 0

--------------------------------------------------------------------------------
-- helpers

-- "12,12,40" -> {12, 12, 40}; ids that are not valid unit defs are skipped
local function DecodeQueue(str)
	local queue = {}
	if type(str) == "number" then
		str = tostring(str)
	end
	if type(str) == "string" then
		for id in str:gmatch("%d+") do
			id = tonumber(id)
			if UnitDefs[id] then
				queue[#queue + 1] = id
			end
		end
	end
	return queue
end

-- a rules param that holds a unitDefID, where 0 or missing means "none"
local function DefParam(value)
	if value and value > 0 and UnitDefs[value] then
		return value
	end
	return nil
end

--------------------------------------------------------------------------------
-- money and chosen perks (from money.locals.lua and perks.locals.lua)

local panelTop = 60
local panelRight = 0
local panelWidth = 128
local panelHeight = 128

local perkTop = panelTop + 64
local perkRight = panelRight + 16
local perkHeight = 32
local perkWidth = 32

local function DrawMoneyAndPerks(team)
	glTexture("bitmaps/ui/money_perks.png")
	glTexRect(vsx - panelRight - panelWidth, vsy - panelTop - panelHeight, vsx - panelRight, vsy - panelTop, false, false)
	local n = 0
	for p = 1, #perkList do
		if spGetTeamRulesParam(team, "hasperk_" .. p) == 1 then
			glTexture(perkList[p][3])
			glTexRect(vsx - perkRight - n * perkWidth - perkWidth, vsy - perkTop, vsx - perkRight - n * perkWidth, vsy - perkTop - perkHeight, false, true)
			n = n + 1
		end
	end
	glTexture(false)

	local money = spGetTeamRulesParam(team, "money")
	local income = spGetTeamRulesParam(team, "income")
	if money then
		glText(floor(money), vsx - 20, vsy - 98, 16, "ro")
	end
	if income then
		glText("(+" .. floor(income) .. ")", vsx - 20, vsy - 108, 12, "ro")
	end
end

--------------------------------------------------------------------------------
-- build progress and queues (from build.locals.lua)

local cbpWidth = 80
local cbpHeight = 60
local cbpLeft = 280
local gbpBottom = 100

local qbpWidth = 40
local qbpHeight = 30
local qbpTop = 160
local qbpLeft = 330

local qbpRowHeight = 70

local function DrawQueue(queue, vert)
	for hpos = 1, #queue do
		glTexture("#" .. queue[hpos])
		glTexRect(qbpLeft + hpos * qbpWidth, vert, qbpLeft + qbpWidth + hpos * qbpWidth, vert - qbpHeight, false, true)
	end
	glTexture(false)
end

local function DrawCurrent(current, progress, vert)
	glTexture("#" .. current)
	glTexRect(cbpLeft, vert, cbpLeft + cbpWidth, vert - cbpHeight, false, true)
	glTexture(false)
	if progress < 1 then
		glColor(1, 1, 1, .3)
		glRect(cbpLeft, vert, cbpLeft + (cbpWidth * progress), vert - cbpHeight)
		glColor(1, 1, 1, 1)
	end
end

local function DrawBuilds(team)
	-- one row per selected carrier, minelayer or hangar
	local vpos = 1
	local selected = spGetSelectedUnits()
	for i = 1, #selected do
		local u = selected[i]
		local queueStr = spGetUnitRulesParam(u, "build_queue")
		if queueStr then
			local vert = vsy - qbpTop - qbpRowHeight * vpos
			local current = DefParam(spGetUnitRulesParam(u, "build_current"))
			local progress = spGetUnitRulesParam(u, "build_progress") or 0
			if current and progress < 1 then
				DrawCurrent(current, progress, vert)
			end
			DrawQueue(DecodeQueue(queueStr), vert)
			vpos = vpos + 1
		end
	end

	-- the team's large-ship build
	local vert = gbpBottom + cbpHeight
	local current = DefParam(spGetTeamRulesParam(team, "gb_current"))
	if current then
		DrawCurrent(current, spGetTeamRulesParam(team, "gb_progress") or 0, vert)
	end
	DrawQueue(DecodeQueue(spGetTeamRulesParam(team, "gb_queue")), vert)
end

--------------------------------------------------------------------------------
-- messages (from message.locals.lua)

local function DrawMessage(team)
	local untilFrame = spGetTeamRulesParam(team, "alert_until")
	if untilFrame and spGetGameFrame() < untilFrame then
		glText(spGetTeamRulesParam(team, "alert_text") or "", vsx * .5, vsy * .8, 24, "oc")
		glText(spGetTeamRulesParam(team, "alert_hint") or "", vsx * .5, vsy * .8 - 40, 15, "oc")
	end
end

--------------------------------------------------------------------------------

function widget:Initialize()
	vsx, vsy = widgetHandler:GetViewSizes()
end

function widget:ViewResize()
	vsx, vsy = widgetHandler:GetViewSizes()
end

function widget:DrawScreen()
	local team = spGetLocalTeamID()
	-- the RmlUi top bar (gui_topbar.lua) replaces the money panel and the
	-- messages; they are only drawn here while it is not running
	local topBar = WG.thisTopBar
	if not topBar then
		DrawMoneyAndPerks(team)
	end
	DrawBuilds(team)
	if not topBar then
		DrawMessage(team)
	end
	glColor(1, 1, 1, 1)
end
