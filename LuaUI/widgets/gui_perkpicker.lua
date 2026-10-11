--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Perk picker of the RmlUi HUD.
--
--  Shows every perk with its icon, name and description. Click perks to
--  select them (up to the points you have left), then confirm. Nothing is
--  sent until you confirm, and the game is never paused or blocked: "Decide
--  later" folds the picker into a reminder under the top bar, which reopens it.
--
--  Perk state comes from the team rules params hasperk_<n> and perks_left;
--  choices go out as the pickperk:<n> Lua message handled by the perks gadget.
--
--  While this widget runs it sets WG.thisPerkPicker, which switches off the
--  old perk selector.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "THIS Perk Picker",
		desc = "Choose perks from labelled cards, with a confirm step",
		author = "THIS contributors",
		date = "2026-10-11",
		license = "GNU GPL, v2 or later",
		layer = -10,
		enabled = true
	}
end

local DOCUMENT_PATH = "LuaUI/rml/perkpicker.rml"
local UPDATE_INTERVAL = 0.2
-- the picker opens by itself only at the start of a game
local AUTO_OPEN_FRAMES = 30 * 30

local hud
local perkList
local document
local view
local lastUpdate

local open = false
local selected = {}   -- perk index -> true, not yet confirmed
local pointsLeft = 0
local accentTeam, accentColour

--------------------------------------------------------------------------------

local function Sentence(text)
	text = tostring(text or "")
	if text == "" then
		return ""
	end
	text = text:sub(1, 1):upper() .. text:sub(2)
	if not text:find("[%.!%?]$") then
		text = text .. "."
	end
	return text
end

local function IconRML(path)
	if type(path) == "string" and path ~= "" and VFS.FileExists(path) then
		return '<img class="perk-icon" src="/' .. path .. '"/>'
	end
	return '<div class="perk-icon"/>'
end

local function BuildGrid()
	local rml = {}
	for i = 1, #perkList do
		local perk = perkList[i]
		rml[#rml + 1] = string.format(
			'<div id="perk-%d" class="perk" data-perk="%d">' ..
				'<div id="perk-%d-mark" class="perk-mark"/>' ..
				'%s' ..
				'<div class="perk-text">' ..
					'<div class="perk-name">%s</div>' ..
					'<div class="perk-desc">%s</div>' ..
				'</div>' ..
				'<div class="perk-tag">CHOSEN</div>' ..
			'</div>',
			i, i, i, IconRML(perk[3]), hud.Escape(perk[1]), hud.Escape(Sentence(perk[2])))
	end
	view.Element("perk-grid").inner_rml = table.concat(rml)
end

local function CountSelected()
	local count = 0
	for _ in pairs(selected) do
		count = count + 1
	end
	return count
end

local function Plural(count, word)
	return count .. " " .. word .. (count == 1 and "" or "s")
end

local function Refresh()
	local team = Spring.GetLocalTeamID()
	local spectating = Spring.GetSpectatingState()
	pointsLeft = Spring.GetTeamRulesParam(team, "perks_left") or 0
	if spectating then
		pointsLeft = 0
	end

	-- drop selections that are no longer possible
	for i in pairs(selected) do
		if Spring.GetTeamRulesParam(team, "hasperk_" .. i) == 1 then
			selected[i] = nil
		end
	end
	local selectedCount = CountSelected()
	if selectedCount > pointsLeft then
		selected = {}
		selectedCount = 0
	end
	if pointsLeft <= 0 then
		open = false
	end

	local colour = hud.GetAccentRCSS(team)
	if team ~= accentTeam or colour ~= accentColour then
		accentTeam, accentColour = team, colour
		local marks = {"picker-accent", "pill"}
		for i = 1, #perkList do
			marks[#marks + 1] = "perk-" .. i .. "-mark"
		end
		hud.ApplyAccent(document, team, {}, marks)
	end

	view.SetClass("picker", "hidden", not open)
	view.SetClass("pill", "hidden", open or pointsLeft <= 0)
	if pointsLeft > 0 then
		view.SetText("pill", Plural(pointsLeft, "PERK POINT") .. " TO SPEND")
		view.SetText("points", Plural(pointsLeft - selectedCount, "point") .. " left")
	end

	local full = selectedCount >= pointsLeft
	for i = 1, #perkList do
		local id = "perk-" .. i
		local owned = Spring.GetTeamRulesParam(team, "hasperk_" .. i) == 1
		local isSelected = selected[i] == true
		view.SetClass(id, "owned", owned)
		view.SetClass(id, "selected", isSelected)
		view.SetClass(id, "full", full and not owned and not isSelected)
	end

	view.SetClass("confirm", "disabled", selectedCount == 0)
	-- the accent colour is set inline on the button, which would hide the
	-- disabled look, so the accent is only applied while it can be pressed
	view.SetStyle("confirm", "background-color", selectedCount > 0 and accentColour or "rgba(255, 255, 255, 14)")
	if selectedCount == 0 then
		view.SetText("confirm", "Select a perk")
	else
		view.SetText("confirm", "Confirm " .. Plural(selectedCount, "perk"))
	end
end

--------------------------------------------------------------------------------
-- input

local function LeftButton(event)
	return event.parameters and event.parameters.button == 0
end

local function OnPerkMouseDown(event)
	if not LeftButton(event) then
		return
	end
	local index = hud.EventAttribute(event, "data-perk")
	if not index or not perkList[index] then
		return
	end
	local team = Spring.GetLocalTeamID()
	if Spring.GetTeamRulesParam(team, "hasperk_" .. index) == 1 then
		return
	end
	if selected[index] then
		selected[index] = nil
	elseif CountSelected() < pointsLeft then
		selected[index] = true
	end
	Refresh()
end

local function OnConfirmMouseDown(event)
	if not LeftButton(event) then
		return
	end
	local indices = {}
	for i in pairs(selected) do
		indices[#indices + 1] = i
	end
	if #indices == 0 then
		return
	end
	table.sort(indices)
	for _, i in ipairs(indices) do
		Spring.SendLuaRulesMsg("pickperk:" .. i)
	end
	selected = {}
	open = false
	Refresh()
end

local function OnLaterMouseDown(event)
	if LeftButton(event) then
		open = false
		Refresh()
	end
end

local function OnPillMouseDown(event)
	if LeftButton(event) and pointsLeft > 0 then
		open = true
		Refresh()
	end
end

--------------------------------------------------------------------------------
-- call-ins

function widget:Initialize()
	if not RmlUi then
		Spring.Echo("[THIS Perk Picker] RmlUi is not available, keeping the legacy perk selector")
		widgetHandler:RemoveWidget()
		return
	end

	hud = include("rml/hud.lua")
	perkList = include("perks/perks.lua")

	local context = hud.UpdateScale()
	if not context then
		Spring.Echo("[THIS Perk Picker] no RmlUi context, keeping the legacy perk selector")
		widgetHandler:RemoveWidget()
		return
	end

	hud.LoadFonts()
	local ok, result = pcall(context.LoadDocument, context, DOCUMENT_PATH, widget)
	if not ok or not result then
		Spring.Echo("[THIS Perk Picker] could not load " .. DOCUMENT_PATH .. ", keeping the legacy perk selector", ok and "" or result)
		widgetHandler:RemoveWidget()
		return
	end
	document = result
	hud.PrepareDocument(document)

	view = hud.NewView(document)
	view.Assume("picker", "hidden", true)
	view.Assume("pill", "hidden", true)
	view.Assume("confirm", "disabled", true)

	BuildGrid()
	view.Element("perk-grid"):AddEventListener("mousedown", OnPerkMouseDown)
	view.Element("confirm"):AddEventListener("mousedown", OnConfirmMouseDown)
	view.Element("later"):AddEventListener("mousedown", OnLaterMouseDown)
	view.Element("pill"):AddEventListener("mousedown", OnPillMouseDown)

	-- open by itself at the start of a game; later on only the reminder shows
	local team = Spring.GetLocalTeamID()
	local points = Spring.GetTeamRulesParam(team, "perks_left") or 0
	open = points > 0 and Spring.GetGameFrame() < AUTO_OPEN_FRAMES and not Spring.GetSpectatingState()

	Refresh()
	hud.ShowPassive(document)
	lastUpdate = Spring.GetTimer()
	WG.thisPerkPicker = true
end

function widget:Shutdown()
	WG.thisPerkPicker = nil
	if document then
		document:Close()
		document = nil
	end
end

function widget:ViewResize()
	if hud then
		hud.UpdateScale()
	end
end

function widget:Update()
	if not document then
		return
	end
	local now = Spring.GetTimer()
	if Spring.DiffTimers(now, lastUpdate) >= UPDATE_INTERVAL then
		lastUpdate = now
		Refresh()
	end
end
